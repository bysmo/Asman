import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset_model.dart';

class StorageService {
  static const String _assetsKey = 'assets_data';
  static const String _loyersKey = 'loyers_data';
  static const String _userKey = 'user_profile';
  static const String _authKey = 'auth_data';

  // ---- ASSETS ----
  Future<List<Asset>> loadAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_assetsKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => Asset.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveAssets(List<Asset> assets) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(assets.map((a) => a.toMap()).toList());
    await prefs.setString(_assetsKey, data);
  }

  // ---- LOYERS ----
  Future<List<Loyer>> loadLoyers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_loyersKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => Loyer.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveLoyers(List<Loyer> loyers) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(loyers.map((l) => l.toMap()).toList());
    await prefs.setString(_loyersKey, data);
  }

  // ---- USER PROFILE ----
  Future<UserProfile?> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data == null) return null;
    return UserProfile.fromMap(jsonDecode(data));
  }

  Future<void> saveUserProfile(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }

  // ---- AUTH ----
  Future<Map<String, String>?> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_authKey);
    if (data == null) return null;
    return Map<String, String>.from(jsonDecode(data));
  }

  Future<void> saveAuthData(String telephone, String passwordHash) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _authKey, jsonEncode({'telephone': telephone, 'password': passwordHash}));
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await prefs.remove(_userKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_authKey);
  }
}
