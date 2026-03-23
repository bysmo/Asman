import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service central pour tous les appels API vers le backend Laravel Asman.
class ApiService {
  // ─── Configuration ─────────────────────────────────────────────────────────
  static const String _baseUrl = 'https://api.asman.bf/api/v1';
  // Pour le développement local : 'http://10.0.2.2:8000/api/v1' (émulateur Android)
  // Pour la production          : 'https://api.asman.bf/api/v1'

  static const String _tokenKey = 'auth_token';
  static const Duration _timeout = Duration(seconds: 30);

  // ─── Singleton ──────────────────────────────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ─── Token management ───────────────────────────────────────────────────────
  String? _token;

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    return _token;
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ─── Headers ────────────────────────────────────────────────────────────────
  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ─── HTTP Methods ────────────────────────────────────────────────────────────
  Future<ApiResponse> get(String path, {bool auth = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final response = await http
          .get(uri, headers: await _headers(auth: auth))
          .timeout(_timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error(_networkError(e));
    }
  }

  Future<ApiResponse> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final response = await http
          .post(uri,
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(_timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error(_networkError(e));
    }
  }

  Future<ApiResponse> put(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final response = await http
          .put(uri,
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(_timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error(_networkError(e));
    }
  }

  Future<ApiResponse> delete(String path, {bool auth = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final response = await http
          .delete(uri, headers: await _headers(auth: auth))
          .timeout(_timeout);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error(_networkError(e));
    }
  }

  // Upload multipart (photos, documents KYC)
  Future<ApiResponse> uploadFile(
      String path, File file, String fieldName) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$_baseUrl$path');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files
          .add(await http.MultipartFile.fromPath(fieldName, file.path));
      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse.error(_networkError(e));
    }
  }

  // ─── Response parsing ────────────────────────────────────────────────────────
  ApiResponse _parseResponse(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(data);
      } else if (response.statusCode == 401) {
        clearToken();
        return ApiResponse.error('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 403) {
        return ApiResponse.error('Accès non autorisé.');
      } else if (response.statusCode == 422) {
        final errors = data['errors'] as Map<String, dynamic>?;
        final msg = errors?.values.first?.first ?? data['message'] ?? 'Données invalides';
        return ApiResponse.error(msg.toString());
      } else {
        return ApiResponse.error(
            data['message']?.toString() ?? 'Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      return ApiResponse.error('Réponse serveur invalide');
    }
  }

  String _networkError(dynamic e) {
    if (e is SocketException) return 'Pas de connexion internet';
    if (e is HttpException) return 'Erreur réseau';
    if (e.toString().contains('TimeoutException')) return 'Délai dépassé. Vérifiez votre connexion.';
    if (kDebugMode) debugPrint('ApiService error: $e');
    return 'Erreur de connexion';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ENDPOINTS MÉTIER
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Authentification ────────────────────────────────────────────────────────
  Future<ApiResponse> login(String email, String password) =>
      post('/auth/login', {'email': email, 'password': password}, auth: false);

  Future<ApiResponse> register(Map<String, dynamic> data) =>
      post('/auth/register', data, auth: false);

  Future<ApiResponse> logout() => post('/auth/logout', {});

  Future<ApiResponse> me() => get('/auth/me');

  Future<ApiResponse> updateProfile(Map<String, dynamic> data) =>
      put('/auth/profile', data);

  Future<ApiResponse> changePassword(String current, String newPass) =>
      post('/auth/change-password', {
        'current_password': current,
        'password': newPass,
        'password_confirmation': newPass,
      });

  Future<ApiResponse> verifyOtp(String email, String otp) =>
      post('/auth/verify-otp', {'email': email, 'otp': otp}, auth: false);

  Future<ApiResponse> resendOtp(String email) =>
      post('/auth/resend-otp', {'email': email}, auth: false);

  Future<ApiResponse> forgotPassword(String email) =>
      post('/auth/forgot-password', {'email': email}, auth: false);

  Future<ApiResponse> resetPassword(Map<String, dynamic> data) =>
      post('/auth/reset-password', data, auth: false);

  Future<ApiResponse> setupPin(String pin) =>
      post('/auth/setup-pin', {'pin': pin});

  Future<ApiResponse> verifyPin(String pin) =>
      post('/auth/verify-pin', {'pin': pin});

  // ─── KYC ─────────────────────────────────────────────────────────────────────
  Future<ApiResponse> kycStatus() => get('/kyc/status');

  Future<ApiResponse> submitKyc(Map<String, dynamic> data) =>
      post('/kyc/submit', data);

  Future<ApiResponse> uploadKycDocument(File file, String type) =>
      uploadFile('/kyc/documents', file, 'fichier');

  // ─── Assets ──────────────────────────────────────────────────────────────────
  Future<ApiResponse> getAssets() => get('/assets');

  Future<ApiResponse> getAsset(int id) => get('/assets/$id');

  Future<ApiResponse> createAsset(Map<String, dynamic> data) =>
      post('/assets', data);

  Future<ApiResponse> updateAsset(int id, Map<String, dynamic> data) =>
      put('/assets/$id', data);

  Future<ApiResponse> deleteAsset(int id) => delete('/assets/$id');

  Future<ApiResponse> getAssetStats() => get('/assets/stats/summary');

  Future<ApiResponse> getDashboardStats() => get('/dashboard/stats');

  // ─── Comptes bancaires ───────────────────────────────────────────────────────
  Future<ApiResponse> getComptes() => get('/comptes');

  Future<ApiResponse> createCompte(Map<String, dynamic> data) =>
      post('/comptes', data);

  Future<ApiResponse> updateCompte(int id, Map<String, dynamic> data) =>
      put('/comptes/$id', data);

  Future<ApiResponse> deleteCompte(int id) => delete('/comptes/$id');

  Future<ApiResponse> addTransaction(int compteId, Map<String, dynamic> data) =>
      post('/comptes/$compteId/transactions', data);

  Future<ApiResponse> getTransactions(int compteId) =>
      get('/comptes/$compteId/transactions');

  // ─── Créances ────────────────────────────────────────────────────────────────
  Future<ApiResponse> getCreances() => get('/creances?type=creance');

  Future<ApiResponse> createCreance(Map<String, dynamic> data) =>
      post('/creances', {...data, 'type': 'creance'});

  Future<ApiResponse> addRemboursementCreance(
          int id, Map<String, dynamic> data) =>
      post('/creances/$id/remboursements?type=creance', data);

  Future<ApiResponse> deleteCreance(int id) =>
      delete('/creances/$id?type=creance');

  // ─── Dettes ──────────────────────────────────────────────────────────────────
  Future<ApiResponse> getDettes() => get('/dettes?type=dette');

  Future<ApiResponse> createDette(Map<String, dynamic> data) =>
      post('/dettes', {...data, 'type': 'dette'});

  Future<ApiResponse> addRemboursementDette(
          int id, Map<String, dynamic> data) =>
      post('/dettes/$id/remboursements?type=dette', data);

  // ─── Loyers ──────────────────────────────────────────────────────────────────
  Future<ApiResponse> getLoyers() => get('/loyers');

  Future<ApiResponse> createLoyer(Map<String, dynamic> data) =>
      post('/loyers', data);

  Future<ApiResponse> marquerLoyerPaye(int id) =>
      post('/loyers/$id/payer', {});

  Future<ApiResponse> deleteLoyer(int id) => delete('/loyers/$id');

  // ─── Certifications ──────────────────────────────────────────────────────────
  Future<ApiResponse> getCertifications() => get('/certifications');

  Future<ApiResponse> demanderCertification(Map<String, dynamic> data) =>
      post('/certifications', data);

  Future<ApiResponse> soumettreDocuments(int id, Map<String, dynamic> data) =>
      post('/certifications/$id/soumettre', data);

  Future<ApiResponse> uploadDocumentCertification(int id, File file) =>
      uploadFile('/certifications/$id/documents', file, 'fichier');

  // ─── Testaments ──────────────────────────────────────────────────────────────
  Future<ApiResponse> getTestaments() => get('/testaments');

  Future<ApiResponse> createTestament(Map<String, dynamic> data) =>
      post('/testaments', data);

  Future<ApiResponse> updateTestament(int id, Map<String, dynamic> data) =>
      put('/testaments/$id', data);

  Future<ApiResponse> finaliserTestament(int id) =>
      post('/testaments/$id/finaliser', {});

  Future<ApiResponse> certifierTestament(int id, int notaireId) =>
      post('/testaments/$id/certifier', {'notaire_id': notaireId});

  Future<ApiResponse> getAyantsDroit(int testamentId) =>
      get('/testaments/$testamentId/ayants-droit');

  Future<ApiResponse> addAyantDroit(
          int testamentId, Map<String, dynamic> data) =>
      post('/testaments/$testamentId/ayants-droit', data);

  // ─── Marketplace ─────────────────────────────────────────────────────────────
  Future<ApiResponse> getMarketplace({String? type}) =>
      get('/marketplace${type != null ? '?type=$type' : ''}');

  Future<ApiResponse> publishListing(Map<String, dynamic> data) =>
      post('/marketplace', data);

  Future<ApiResponse> withdrawListing(int id) =>
      delete('/marketplace/$id');

  Future<ApiResponse> suspendreListing(int id) =>
      post('/marketplace/$id/suspendre', {});

  // ─── Évaluations ─────────────────────────────────────────────────────────────
  Future<ApiResponse> getEvaluations() => get('/evaluations');

  Future<ApiResponse> createEvaluation(Map<String, dynamic> data) =>
      post('/evaluations', data);

  // ─── Revenus ─────────────────────────────────────────────────────────────────
  Future<ApiResponse> getRevenuesSummary() => get('/revenus/summary');

  Future<ApiResponse> getRevenuesTransactions() =>
      get('/revenus/transactions');
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Modèle de réponse API
// ═══════════════════════════════════════════════════════════════════════════════
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;

  const ApiResponse._({required this.success, this.data, this.error});

  factory ApiResponse.success(dynamic data) =>
      ApiResponse._(success: true, data: data);

  factory ApiResponse.error(String message) =>
      ApiResponse._(success: false, error: message);

  /// Données de la réponse (shortcut vers data['data'])
  dynamic get body => data is Map ? data['data'] : data;

  /// Message de succès
  String get message =>
      data is Map ? (data['message'] ?? '') : '';

  @override
  String toString() => success
      ? 'ApiResponse.success(${data.toString().substring(0, data.toString().length.clamp(0, 100))})'
      : 'ApiResponse.error($error)';
}
