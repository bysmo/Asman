import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/asset_model.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  UserProfile? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;
  bool _balancesVisible = false;

  // Temporary user id used between register and OTP verification
  String? _pendingUserId;

  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  UserProfile? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get balancesVisible => _balancesVisible;
  String? get pendingUserId => _pendingUserId;

  // ─── Hash helpers ────────────────────────────────────────────────────────────

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  String generateOtp() {
    final rand = Random.secure();
    return (100000 + rand.nextInt(900000)).toString();
  }

  // ─── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _storage.isLoggedIn();
      if (_isLoggedIn) {
        final authData = await _storage.loadAuthData();
        if (authData != null) {
          final dbUser = await DatabaseService().loginUser(authData['telephone']!, authData['password']!);
          if (dbUser != null) {
            _user = await DatabaseService().getUserProfile(dbUser['id']);
            if (_user != null) {
              await _storage.saveUserProfile(_user!);
            }
          } else {
            _isLoggedIn = false;
            await logout();
          }
        }
      }
    } catch (e) {
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Register (Step 1) ───────────────────────────────────────────────────────
  // Returns the OTP generated (to display in SnackBar until email is real)
  Future<String?> register({
    required String telephone,
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String pays,
    required String devise,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _uuid.v4();
      final passwordHash = _hashPassword(password);

      final success = await DatabaseService().registerUser(
        id: userId,
        telephone: telephone,
        email: email,
        passwordHash: passwordHash,
        nom: nom,
        prenom: prenom,
        pays: pays,
        devise: devise,
      );

      if (!success) {
        _error = 'Ce numéro de téléphone ou email est déjà enregistré.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Generate and store OTP
      final otp = generateOtp();
      await DatabaseService().setOtp(userId, otp);

      _pendingUserId = userId;
      _isLoading = false;
      notifyListeners();

      // In production: send via Laravel API. For now, return OTP for display.
      return otp;
    } catch (e) {
      _error = 'Erreur lors de l\'inscription: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ─── Register Step 2: Verify OTP ─────────────────────────────────────────────
  Future<bool> verifyRegistrationOtp(String otpCode) async {
    if (_pendingUserId == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ok = await DatabaseService().verifyOtp(_pendingUserId!, otpCode);
      if (!ok) {
        _error = 'Code OTP invalide ou expiré.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      await DatabaseService().setEmailVerifie(_pendingUserId!);
      _user = await DatabaseService().getUserProfile(_pendingUserId!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur de vérification: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Register Step 3: Setup PIN ──────────────────────────────────────────────
  Future<bool> setupPin(String pin) async {
    if (_pendingUserId == null && _user == null) return false;
    final uid = _pendingUserId ?? _user!.id;

    try {
      final pinHash = hashPin(pin);
      await DatabaseService().setPin(uid, pinHash);

      _user = await DatabaseService().getUserProfile(uid);
      final telephone = _user?.telephone ?? '';
      final authData = await _storage.loadAuthData();
      if (authData != null) {
        await _storage.saveAuthData(telephone, authData['password']!);
      }
      await _storage.saveUserProfile(_user!);

      _isLoggedIn = true;
      _pendingUserId = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur de configuration du PIN: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── Login ───────────────────────────────────────────────────────────────────
  Future<bool> login({required String telephone, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final passwordHash = _hashPassword(password);
      final dbUser = await DatabaseService().loginUser(telephone, passwordHash);

      if (dbUser == null) {
        _error = 'Numéro de téléphone ou mot de passe incorrect.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _user = await DatabaseService().getUserProfile(dbUser['id']);
      if (_user == null) {
        _error = 'Profil introuvable.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!_user!.emailVerifie) {
        _error = 'Veuillez vérifier votre email avant de vous connecter.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _storage.saveAuthData(telephone, passwordHash);
      await _storage.saveUserProfile(_user!);

      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur de connexion: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── PIN verification (for asset modifications, showing balances) ─────────────
  Future<bool> verifyPin(String pin) async {
    if (_user == null) return false;
    final pinHash = hashPin(pin);
    return DatabaseService().verifyPin(_user!.id, pinHash);
  }

  // ─── Balances visibility ─────────────────────────────────────────────────────
  Future<bool> showBalances(String pin) async {
    final ok = await verifyPin(pin);
    if (ok) {
      _balancesVisible = true;
      notifyListeners();
    }
    return ok;
  }

  void hideBalances() {
    _balancesVisible = false;
    notifyListeners();
  }

  // ─── Forgot password ─────────────────────────────────────────────────────────
  /// Returns the OTP for display (until real email is implemented)
  Future<String?> requestPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await DatabaseService().getUserByEmail(email);
      if (profile == null) {
        _error = 'Aucun compte associé à cet email.';
        _isLoading = false;
        notifyListeners();
        return null;
      }
      final otp = generateOtp();
      await DatabaseService().setOtp(profile.id, otp);
      _pendingUserId = profile.id;
      _isLoading = false;
      notifyListeners();
      // In production: send via Laravel API. For now return OTP.
      return otp;
    } catch (e) {
      _error = 'Erreur: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyResetOtp(String otp) async {
    if (_pendingUserId == null) return false;
    return DatabaseService().verifyOtp(_pendingUserId!, otp);
  }

  Future<bool> resetPassword(String newPassword) async {
    if (_pendingUserId == null) return false;
    try {
      final hash = _hashPassword(newPassword);
      await DatabaseService().resetPassword(_pendingUserId!, hash);
      _pendingUserId = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la réinitialisation: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── PIN Reset ───────────────────────────────────────────────────────────────
  Future<String?> requestPinReset() async {
    if (_user == null) return null;
    final otp = generateOtp();
    await DatabaseService().setOtp(_user!.id, otp);
    // In production: send via Laravel API. For now return OTP.
    return otp;
  }

  Future<bool> resetPin(String otp, String newPin) async {
    if (_user == null) return false;
    final ok = await DatabaseService().verifyOtp(_user!.id, otp);
    if (!ok) {
      _error = 'Code OTP invalide ou expiré.';
      notifyListeners();
      return false;
    }
    final pinHash = hashPin(newPin);
    await DatabaseService().setPin(_user!.id, pinHash);
    _user = await DatabaseService().getUserProfile(_user!.id);
    notifyListeners();
    return true;
  }

  // ─── Update profile (restricted fields only) ─────────────────────────────────
  Future<bool> updateProfile({
    required String nom,
    required String prenom,
    required String pays,
    required String devise,
  }) async {
    if (_user == null) return false;
    try {
      await DatabaseService().updateProfile(
        _user!.id,
        nom: nom, prenom: prenom, pays: pays, devise: devise,
      );
      _user = await DatabaseService().getUserProfile(_user!.id);
      await _storage.saveUserProfile(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur mise à jour profil: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── Submit KYC ────────────────────────────────────────────────────────────
  Future<bool> submitKyc({
    required DateTime dateNaissance,
    required String typePieceIdentite,
    required String numeroPiece,
    required String documentIdentiteRecto,
    required String documentIdentiteVerso,
    required String selfie,
    required String fonction,
    required String adresseResidence,
    required String nationalite,
    required String nomCompletPere,
    required String nomCompletMere,
  }) async {
    if (_user == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final kycData = {
        'kycStatus': KycStatus.enAttente.index,
        'dateNaissance': dateNaissance.toIso8601String(),
        'typePieceIdentite': typePieceIdentite,
        'numeroPiece': numeroPiece,
        'documentIdentiteRecto': documentIdentiteRecto,
        'documentIdentiteVerso': documentIdentiteVerso,
        'selfie': selfie,
        'fonction': fonction,
        'adresseResidence': adresseResidence,
        'nationalite': nationalite,
        'nomCompletPere': nomCompletPere,
        'nomCompletMere': nomCompletMere,
      };

      await DatabaseService().submitKycData(_user!.id, kycData);
      
      _user = await DatabaseService().getUserProfile(_user!.id);
      await _storage.saveUserProfile(_user!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la soumission du KYC: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _storage.clearAuth();
    _user = null;
    _isLoggedIn = false;
    _balancesVisible = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
