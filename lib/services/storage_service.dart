import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset_model.dart';

class StorageService {
  static const String _assetsKey = 'assets_data';
  static const String _loyersKey = 'loyers_data';
  static const String _userKey = 'user_profile';
  static const String _authKey = 'auth_data';
  static const String _comptesKey = 'comptes_bancaires';
  static const String _creancesKey = 'creances_data';
  static const String _dettesKey = 'dettes_data';
  static const String _certificationsKey = 'certifications_data';
  static const String _listingsKey = 'marketplace_listings';
  static const String _testamentKey = 'testament_data';

  // ─── ASSETS ────
  Future<List<Asset>> loadAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_assetsKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => Asset.fromMap(Map<String, dynamic>.from(e))).toList();
  }
  Future<void> saveAssets(List<Asset> assets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_assetsKey, jsonEncode(assets.map((a) => a.toMap()).toList()));
  }

  // ─── LOYERS ────
  Future<List<Loyer>> loadLoyers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_loyersKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => Loyer.fromMap(Map<String, dynamic>.from(e))).toList();
  }
  Future<void> saveLoyers(List<Loyer> loyers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loyersKey, jsonEncode(loyers.map((l) => l.toMap()).toList()));
  }

  // ─── COMPTES BANCAIRES ────
  Future<List<CompteBancaire>> loadComptes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_comptesKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => CompteBancaire.fromMap(Map<String, dynamic>.from(e))).toList();
  }
  Future<void> saveComptes(List<CompteBancaire> comptes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_comptesKey, jsonEncode(comptes.map((c) => c.toMap()).toList()));
  }

  // ─── CRÉANCES ────
  Future<List<Creance>> loadCreances() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_creancesKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => Creance.fromMap(Map<String, dynamic>.from(e))).toList();
  }
  Future<void> saveCreances(List<Creance> creances) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_creancesKey, jsonEncode(creances.map((c) => c.toMap()).toList()));
  }

  // ─── DETTES ────
  Future<List<Dette>> loadDettes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_dettesKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => Dette.fromMap(Map<String, dynamic>.from(e))).toList();
  }
  Future<void> saveDettes(List<Dette> dettes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dettesKey, jsonEncode(dettes.map((d) => d.toMap()).toList()));
  }

  // ─── CERTIFICATIONS ────
  Future<List<CertificationDemande>> loadCertifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_certificationsKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => CertificationDemande.fromMap(Map<String, dynamic>.from(e))).toList();
  }
  Future<void> saveCertifications(List<CertificationDemande> certs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_certificationsKey, jsonEncode(certs.map((c) => c.toMap()).toList()));
  }

  // ─── MARKETPLACE ────
  Future<List<MarketplaceListing>> loadListings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_listingsKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => MarketplaceListing.fromMap(Map<String, dynamic>.from(e))).toList();
  }
  Future<void> saveListings(List<MarketplaceListing> listings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listingsKey, jsonEncode(listings.map((l) => l.toMap()).toList()));
  }

  // ─── TESTAMENT ────
  Future<Testament?> loadTestament() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_testamentKey);
    if (data == null) return null;
    return Testament.fromMap(jsonDecode(data));
  }
  Future<void> saveTestament(Testament testament) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_testamentKey, jsonEncode(testament.toMap()));
  }

  // ─── AUTH ────
  Future<Map<String, String>?> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_authKey);
    if (data == null) return null;
    return Map<String, String>.from(jsonDecode(data));
  }
  Future<void> saveAuthData(String telephone, String passwordHash) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, jsonEncode({'telephone': telephone, 'password': passwordHash}));
  }
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
