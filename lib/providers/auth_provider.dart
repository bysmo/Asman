import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/asset_model.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';

class AuthProvider extends ChangeNotifier {
  UserProfile? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  UserProfile? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _storage.isLoggedIn();
      if (_isLoggedIn) {
        _user = await _storage.loadUserProfile();
      }
    } catch (e) {
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<bool> register({
    required String telephone,
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
      final existingAuth = await _storage.loadAuthData();
      if (existingAuth != null && existingAuth['telephone'] == telephone) {
        _error = 'Ce numéro de téléphone est déjà enregistré.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userId = _uuid.v4();
      final passwordHash = _hashPassword(password);

      _user = UserProfile(
        id: userId,
        telephone: telephone,
        nom: nom,
        prenom: prenom,
        pays: pays,
        devise: devise,
        dateCreation: DateTime.now(),
      );

      await _storage.saveAuthData(telephone, passwordHash);
      await _storage.saveUserProfile(_user!);

      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'inscription: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String telephone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authData = await _storage.loadAuthData();

      if (authData == null) {
        _error = 'Aucun compte trouvé. Veuillez vous inscrire.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final passwordHash = _hashPassword(password);

      if (authData['telephone'] != telephone ||
          authData['password'] != passwordHash) {
        _error = 'Numéro de téléphone ou mot de passe incorrect.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _user = await _storage.loadUserProfile();
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

  Future<void> logout() async {
    await _storage.clearAuth();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
