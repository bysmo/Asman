import 'package:shared_preferences/shared_preferences.dart';

/// StorageService allégé — ne stocke plus les données métier localement.
/// Les actifs, loyers, certifications, etc. viennent tous du backend Laravel.
/// Ce service gère uniquement :
///   - Le token d'authentification (géré par ApiService)
///   - Les préférences utilisateur (thème, langue)
///   - Le statut de connexion
class StorageService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _themeKey = 'app_theme';
  static const String _langKey = 'app_lang';
  static const String _balancesVisibleKey = 'balances_visible';
  static const String _onboardingDoneKey = 'onboarding_done';

  // ─── Statut de connexion ─────────────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }

  // ─── Thème ───────────────────────────────────────────────────────────────────
  Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'light';
  }

  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  // ─── Langue ──────────────────────────────────────────────────────────────────
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey) ?? 'fr';
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
  }

  // ─── Soldes visibles (préférence) ────────────────────────────────────────────
  Future<bool> getBalancesVisible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_balancesVisibleKey) ?? false;
  }

  Future<void> setBalancesVisible(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_balancesVisibleKey, value);
  }

  // ─── Onboarding ─────────────────────────────────────────────────────────────
  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, true);
  }

  // ─── Nettoyage à la déconnexion ──────────────────────────────────────────────
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_balancesVisibleKey);
  }

  /// Nettoyage complet (utile pour debug/reset)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
