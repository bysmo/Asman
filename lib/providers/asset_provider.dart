import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/asset_model.dart';
import '../services/storage_service.dart';

class AssetProvider extends ChangeNotifier {
  List<Asset> _assets = [];
  List<Loyer> _loyers = [];
  bool _isLoading = false;

  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  List<Asset> get assets => _assets;
  List<Loyer> get loyers => _loyers;
  bool get isLoading => _isLoading;

  // Totaux par catégorie
  double get totalImmobilier => _assets
      .where((a) => a.type == AssetType.immobilier)
      .fold(0.0, (sum, a) => sum + a.valeurActuelle);

  double get totalVehicules => _assets
      .where((a) => a.type == AssetType.vehicule)
      .fold(0.0, (sum, a) => sum + a.valeurActuelle);

  double get totalInvestissements => _assets
      .where((a) => a.type == AssetType.investissement)
      .fold(0.0, (sum, a) => sum + a.valeurActuelle);

  double get totalCreances => _assets
      .where((a) => a.type == AssetType.creance)
      .fold(0.0, (sum, a) => sum + a.valeurActuelle);

  double get totalAutres => _assets
      .where((a) => a.type == AssetType.autre)
      .fold(0.0, (sum, a) => sum + a.valeurActuelle);

  double get patrimoineTotal => _assets
      .where((a) => a.statut != AssetStatus.vendu)
      .fold(0.0, (sum, a) => sum + a.valeurActuelle);

  double get loyersMensuelsTotaux => _assets
      .where((a) => a.estLoue && a.loyerMensuel != null)
      .fold(0.0, (sum, a) => sum + (a.loyerMensuel ?? 0));

  List<Asset> getAssetsByType(AssetType type) =>
      _assets.where((a) => a.type == type).toList();

  List<Asset> get assetsLoues => _assets.where((a) => a.estLoue).toList();

  List<Loyer> getLoyersByAsset(String assetId) =>
      _loyers.where((l) => l.assetId == assetId).toList();

  double getLoyersPercusPourMois(int mois, int annee) {
    return _loyers
        .where((l) => l.mois == mois && l.annee == annee && l.estPaye)
        .fold(0.0, (sum, l) => sum + l.montant);
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _assets = await _storage.loadAssets();
    _loyers = await _storage.loadLoyers();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAsset(Asset asset) async {
    _assets.add(asset);
    await _storage.saveAssets(_assets);
    notifyListeners();
  }

  Future<void> updateAsset(Asset updatedAsset) async {
    final index = _assets.indexWhere((a) => a.id == updatedAsset.id);
    if (index != -1) {
      _assets[index] = updatedAsset;
      await _storage.saveAssets(_assets);
      notifyListeners();
    }
  }

  Future<void> deleteAsset(String assetId) async {
    _assets.removeWhere((a) => a.id == assetId);
    _loyers.removeWhere((l) => l.assetId == assetId);
    await _storage.saveAssets(_assets);
    await _storage.saveLoyers(_loyers);
    notifyListeners();
  }

  Future<void> updateValeur(String assetId, double nouvelleValeur) async {
    final index = _assets.indexWhere((a) => a.id == assetId);
    if (index != -1) {
      _assets[index].valeurActuelle = nouvelleValeur;
      _assets[index].dateDerniereEvaluation = DateTime.now();
      await _storage.saveAssets(_assets);
      notifyListeners();
    }
  }

  Future<void> addLoyer(Loyer loyer) async {
    _loyers.add(loyer);
    await _storage.saveLoyers(_loyers);
    notifyListeners();
  }

  Future<void> updateLoyer(Loyer loyer) async {
    final index = _loyers.indexWhere((l) => l.id == loyer.id);
    if (index != -1) {
      _loyers[index] = loyer;
      await _storage.saveLoyers(_loyers);
      notifyListeners();
    }
  }

  Future<void> marquerLoyerPaye(String loyerId) async {
    final index = _loyers.indexWhere((l) => l.id == loyerId);
    if (index != -1) {
      _loyers[index].estPaye = true;
      _loyers[index].datePaiement = DateTime.now();
      await _storage.saveLoyers(_loyers);
      notifyListeners();
    }
  }

  String generateId() => _uuid.v4();
}
