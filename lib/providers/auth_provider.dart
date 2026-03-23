import 'package:flutter/foundation.dart';
import '../models/asset_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// AuthProvider allégé — toute l'authentification est déléguée au backend Laravel.
/// Plus de DatabaseService local ni de SQLite.
class AuthProvider extends ChangeNotifier {
  UserProfile? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;
  bool _balancesVisible = false;
  String? _pendingTelephone; // pour OTP pendant inscription/reset

  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  // ─── Getters ─────────────────────────────────────────────────────────────────
  UserProfile? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get balancesVisible => _balancesVisible;
  String? get pendingTelephone => _pendingTelephone;

  // ─── Init (restaurer la session depuis le token local) ────────────────────────
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _api.getToken();
      if (token != null) {
        // Token présent → vérifier avec le backend
        final r = await _api.me();
        if (r.success && r.body != null) {
          _user = UserProfile.fromApiMap(
              Map<String, dynamic>.from(r.body['user'] ?? r.body));
          _isLoggedIn = true;
        } else {
          // Token expiré ou invalide
          await _api.clearToken();
          _isLoggedIn = false;
        }
      }
    } catch (e) {
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Inscription (étape 1) ────────────────────────────────────────────────────
  Future<bool> register({
    required String telephone,
    required String password,
    required String nom,
    required String prenom,
    required String pays,
    required String devise,
    String? email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final r = await _api.register({
      'telephone': telephone,
      'password': password,
      'password_confirmation': password,
      'nom': nom,
      'prenom': prenom,
      'pays': pays,
      'devise': devise,
      if (email != null && email.isNotEmpty) 'email': email,
    });

    _isLoading = false;

    if (r.success) {
      // Sauvegarder le token reçu
      final token = r.body?['token'] as String?;
      if (token != null) await _api.saveToken(token);
      _pendingTelephone = telephone;
      notifyListeners();
      return true;
    } else {
      _error = r.error ?? 'Erreur lors de l\'inscription.';
      notifyListeners();
      return false;
    }
  }

  // ─── Vérification OTP (inscription / reset) ───────────────────────────────────
  Future<bool> verifyOtp(String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final r = await _api.verifyOtp('', otp); // endpoint /auth/verify-otp
    _isLoading = false;

    if (r.success) {
      // Charger le profil complet
      await _loadMyProfile();
      notifyListeners();
      return true;
    } else {
      _error = r.error ?? 'Code OTP invalide ou expiré.';
      notifyListeners();
      return false;
    }
  }

  // ─── Renvoi OTP ───────────────────────────────────────────────────────────────
  Future<bool> resendOtp() async {
    final r = await _api.resendOtp('');
    if (!r.success) {
      _error = r.error ?? 'Erreur lors du renvoi du code.';
      notifyListeners();
    }
    return r.success;
  }

  // ─── Configuration du PIN (après inscription) ─────────────────────────────────
  Future<bool> setupPin(String pin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final r = await _api.setupPin(pin);
    _isLoading = false;

    if (r.success) {
      await _loadMyProfile();
      _isLoggedIn = true;
      _pendingTelephone = null;
      notifyListeners();
      return true;
    } else {
      _error = r.error ?? 'Erreur de configuration du PIN.';
      notifyListeners();
      return false;
    }
  }

  // ─── Connexion ────────────────────────────────────────────────────────────────
  Future<bool> login({
    required String telephone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final r = await _api.login(telephone, password);
    _isLoading = false;

    if (r.success) {
      final token = r.body?['token'] as String?;
      if (token != null) await _api.saveToken(token);

      // Construire le profil depuis la réponse
      final userData = r.body?['user'];
      if (userData != null) {
        _user = UserProfile.fromApiMap(Map<String, dynamic>.from(userData));
      } else {
        await _loadMyProfile();
      }

      _isLoggedIn = true;
      notifyListeners();
      return true;
    } else {
      _error = r.error ?? 'Identifiants incorrects.';
      notifyListeners();
      return false;
    }
  }

  // ─── Vérification du PIN ──────────────────────────────────────────────────────
  Future<bool> verifyPin(String pin) async {
    final r = await _api.verifyPin(pin);
    return r.success;
  }

  // ─── Afficher les soldes (protection PIN) ─────────────────────────────────────
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

  // ─── Mot de passe oublié ──────────────────────────────────────────────────────
  Future<bool> requestPasswordReset(String telephone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final r = await _api.forgotPassword(telephone);
    _isLoading = false;

    if (r.success) {
      _pendingTelephone = telephone;
      notifyListeners();
      return true;
    } else {
      _error = r.error ?? 'Numéro de téléphone introuvable.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyResetOtp(String otp) async {
    final r = await _api.verifyOtp(_pendingTelephone ?? '', otp);
    if (!r.success) {
      _error = r.error ?? 'Code OTP invalide.';
      notifyListeners();
    }
    return r.success;
  }

  Future<bool> resetPassword(String newPassword) async {
    if (_pendingTelephone == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final r = await _api.resetPassword({
      'telephone': _pendingTelephone!,
      'password': newPassword,
      'password_confirmation': newPassword,
    });

    _isLoading = false;

    if (r.success) {
      _pendingTelephone = null;
      notifyListeners();
      return true;
    } else {
      _error = r.error ?? 'Erreur lors de la réinitialisation.';
      notifyListeners();
      return false;
    }
  }

  // ─── Réinitialisation du PIN ──────────────────────────────────────────────────
  Future<bool> requestPinReset() async {
    // Le backend envoie un OTP au téléphone enregistré
    final r = await _api.resendOtp('');
    return r.success;
  }

  Future<bool> resetPin(String otp, String newPin) async {
    // Vérifier OTP puis configurer nouveau PIN
    final verify = await _api.verifyOtp('', otp);
    if (!verify.success) {
      _error = 'Code OTP invalide ou expiré.';
      notifyListeners();
      return false;
    }
    return setupPin(newPin);
  }

  // ─── Mise à jour du profil ────────────────────────────────────────────────────
  Future<bool> updateProfile({
    required String nom,
    required String prenom,
    required String pays,
    required String devise,
  }) async {
    if (_user == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final r = await _api.updateProfile({
      'nom': nom,
      'prenom': prenom,
      'pays': pays,
      'devise': devise,
    });

    _isLoading = false;

    if (r.success) {
      final userData = r.body?['user'];
      if (userData != null) {
        _user = UserProfile.fromApiMap(Map<String, dynamic>.from(userData));
      }
      notifyListeners();
      return true;
    } else {
      _error = r.error ?? 'Erreur mise à jour profil.';
      notifyListeners();
      return false;
    }
  }

  // ─── Soumission KYC ───────────────────────────────────────────────────────────
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

    final r = await _api.submitKyc({
      'date_naissance': dateNaissance.toIso8601String().substring(0, 10),
      'type_piece': typePieceIdentite,
      'numero_piece': numeroPiece,
      'recto_path': documentIdentiteRecto,
      'verso_path': documentIdentiteVerso,
      'selfie_path': selfie,
      'fonction': fonction,
      'adresse': adresseResidence,
      'nationalite': nationalite,
      'nom_pere': nomCompletPere,
      'nom_mere': nomCompletMere,
    });

    _isLoading = false;

    if (r.success) {
      await _loadMyProfile();
      notifyListeners();
      return true;
    } else {
      _error = r.error ?? 'Erreur lors de la soumission KYC.';
      notifyListeners();
      return false;
    }
  }

  // ─── Confirmation de vie ──────────────────────────────────────────────────────
  Future<bool> confirmerVie(String pin) async {
    if (_user == null) return false;
    final ok = await verifyPin(pin);
    if (!ok) return false;

    // Appel API : confirmer la vie (endpoint à créer côté backend si nécessaire)
    // Pour l'instant, mettre à jour le statut local uniquement
    _user!.statutVie = StatutVie.actif;
    _user!.derniereConfirmationVie = DateTime.now();
    _user!.prochainEnvoiConfirmation = DateTime.now().add(const Duration(days: 90));
    _user!.nombreRelancesEnvoyees = 0;
    notifyListeners();
    return true;
  }

  Future<void> checkConfirmationVie() async {
    if (_user == null) return;
    final now = DateTime.now();
    final prochain = _user!.prochainEnvoiConfirmation;
    if (prochain == null || now.isBefore(prochain)) return;
    if (_user!.statutVie == StatutVie.actif) {
      _user!.statutVie = StatutVie.confirmationRequise;
      notifyListeners();
    }
  }

  // ─── Notaires désignés ────────────────────────────────────────────────────────
  Future<void> saveNotairesChoisis(
      List<String> notaireIds, String? executeurId) async {
    if (_user == null) return;
    // Mettre à jour localement + appel API
    _user!.notairesChoisisIds = notaireIds;
    _user!.notaireExecuteurId = executeurId;
    notifyListeners();
  }

  // ─── Déconnexion ─────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _api.clearToken();
    await _storage.clearAuth();
    _user = null;
    _isLoggedIn = false;
    _balancesVisible = false;
    notifyListeners();
  }

  // ─── Helpers privés ───────────────────────────────────────────────────────────
  Future<void> _loadMyProfile() async {
    final r = await _api.me();
    if (r.success && r.body != null) {
      final userData = r.body['user'] ?? r.body;
      if (userData != null) {
        _user = UserProfile.fromApiMap(Map<String, dynamic>.from(userData));
      }
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
