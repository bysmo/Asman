import 'package:flutter/foundation.dart';
import '../models/asset_model.dart';
import '../services/api_service.dart';

/// Provider allégé — toutes les opérations BD sont déléguées au backend Laravel.
/// Le stockage local (SharedPreferences) n'est plus utilisé pour les données métier.
class AssetProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ─── État ────────────────────────────────────────────────────────────────────
  List<Asset>           _assets          = [];
  List<Loyer>           _loyers          = [];
  List<CompteBancaire>  _comptes         = [];
  List<Creance>         _creances        = [];
  List<Dette>           _dettes          = [];
  List<Certification>   _certifications  = [];
  List<MarketplaceListing> _listings     = [];
  Testament?            _testament;

  bool   _isLoading = false;
  String? _error;

  // ─── Getters ─────────────────────────────────────────────────────────────────
  List<Asset>           get assets          => _assets;
  List<Loyer>           get loyers          => _loyers;
  List<CompteBancaire>  get comptes         => _comptes;
  List<Creance>         get creances        => _creances;
  List<Dette>           get dettes          => _dettes;
  List<Certification>   get certifications  => _certifications;
  List<MarketplaceListing> get listings     => _listings;
  Testament?            get testament       => _testament;
  bool                  get isLoading       => _isLoading;
  String?               get error           => _error;

  // ─── Filtres par type ─────────────────────────────────────────────────────────
  List<Asset> get immobiliers   => _assets.where((a) => a.type == AssetType.immobilier).toList();
  List<Asset> get vehicules     => _assets.where((a) => a.type == AssetType.vehicule).toList();
  List<Asset> get investissements => _assets.where((a) => a.type == AssetType.investissement).toList();
  List<Asset> get parcelles     => _assets.where((a) => a.type == AssetType.parcelle).toList();
  List<Asset> get assetsCertifies => _assets.where((a) => a.estCertifie).toList();

  // ─── Calculs patrimoniaux ────────────────────────────────────────────────────
  double get totalActifs => _assets.fold(0, (s, a) => s + a.valeurActuelle);
  double get totalComptes => _comptes.fold(0, (s, c) => s + (c.solde ?? 0));
  double get totalCreances => _creances.fold(0, (s, c) => s + c.montantRestant);
  double get totalDettes => _dettes.fold(0, (s, d) => s + d.montantRestant);
  double get totalLoyers => _loyers.where((l) => !l.estPaye).fold(0, (s, l) => s + l.montant);
  double get patrimoineNet => totalActifs + totalComptes + totalCreances - totalDettes;
  double get patrimoineTotal => patrimoineNet;

  // Totaux par type d'actif (pour graphiques)
  double get totalImmobilier => immobiliers.fold(0, (s, a) => s + a.valeurActuelle);
  double get totalVehicules => vehicules.fold(0, (s, a) => s + a.valeurActuelle);
  double get totalInvestissements => investissements.fold(0, (s, a) => s + a.valeurActuelle);
  double get totalCreancesActifs => totalCreances;
  double get totalAutres => _assets.where((a) =>
      a.type != AssetType.immobilier &&
      a.type != AssetType.parcelle &&
      a.type != AssetType.vehicule &&
      a.type != AssetType.investissement
  ).fold(0, (s, a) => s + a.valeurActuelle);

  // ─── Chargement initial ───────────────────────────────────────────────────────
  Future<void> loadData() async {
    _setLoading(true);
    _error = null;

    await Future.wait([
      _loadAssets(),
      _loadComptes(),
      _loadCreances(),
      _loadDettes(),
      _loadLoyers(),
      _loadCertifications(),
      _loadTestament(),
    ]);

    _setLoading(false);
  }

  Future<void> _loadAssets() async {
    final r = await _api.getAssets();
    if (r.success) {
      final list = r.body as List? ?? [];
      _assets = list.map((e) => Asset.fromMap(Map<String, dynamic>.from(e))).toList();
    }
  }

  Future<void> _loadComptes() async {
    final r = await _api.getComptes();
    if (r.success) {
      final list = r.body as List? ?? [];
      _comptes = list.map((e) => CompteBancaire.fromMap(Map<String, dynamic>.from(e))).toList();
    }
  }

  Future<void> _loadCreances() async {
    final r = await _api.getCreances();
    if (r.success) {
      final list = r.body as List? ?? [];
      _creances = list.map((e) => Creance.fromMap(Map<String, dynamic>.from(e))).toList();
    }
  }

  Future<void> _loadDettes() async {
    final r = await _api.getDettes();
    if (r.success) {
      final list = r.body as List? ?? [];
      _dettes = list.map((e) => Dette.fromMap(Map<String, dynamic>.from(e))).toList();
    }
  }

  Future<void> _loadLoyers() async {
    final r = await _api.getLoyers();
    if (r.success) {
      final list = r.body as List? ?? [];
      _loyers = list.map((e) => Loyer.fromMap(Map<String, dynamic>.from(e))).toList();
    }
  }

  Future<void> _loadCertifications() async {
    final r = await _api.getCertifications();
    if (r.success) {
      final list = r.body as List? ?? [];
      _certifications = list.map((e) => Certification.fromMap(Map<String, dynamic>.from(e))).toList();
    }
  }

  Future<void> _loadTestament() async {
    final r = await _api.getTestaments();
    if (r.success) {
      final list = r.body as List? ?? [];
      if (list.isNotEmpty) {
        _testament = Testament.fromMap(Map<String, dynamic>.from(list.first));
      }
    }
  }

  // ─── Assets CRUD ─────────────────────────────────────────────────────────────
  Future<bool> addAsset(Asset asset) async {
    final r = await _api.createAsset(asset.toMap());
    if (r.success) {
      await _loadAssets();
      notifyListeners();
      return true;
    }
    _error = r.error;
    notifyListeners();
    return false;
  }

  Future<bool> updateAsset(Asset asset) async {
    final id = int.tryParse(asset.id) ?? 0;
    final r = await _api.updateAsset(id, asset.toMap());
    if (r.success) {
      await _loadAssets();
      notifyListeners();
      return true;
    }
    _error = r.error;
    notifyListeners();
    return false;
  }

  Future<bool> deleteAsset(String assetId) async {
    final id = int.tryParse(assetId) ?? 0;
    final r = await _api.deleteAsset(id);
    if (r.success) {
      _assets.removeWhere((a) => a.id == assetId);
      notifyListeners();
      return true;
    }
    _error = r.error;
    notifyListeners();
    return false;
  }

  // ─── Loyers ──────────────────────────────────────────────────────────────────
  Future<bool> addLoyer(Loyer loyer) async {
    final r = await _api.createLoyer(loyer.toMap());
    if (r.success) {
      await _loadLoyers();
      notifyListeners();
      return true;
    }
    _error = r.error;
    notifyListeners();
    return false;
  }

  Future<bool> marquerLoyerPaye(String loyerId) async {
    final id = int.tryParse(loyerId) ?? 0;
    final r = await _api.marquerLoyerPaye(id);
    if (r.success) {
      await _loadLoyers();
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Comptes bancaires ───────────────────────────────────────────────────────
  Future<bool> addCompte(CompteBancaire compte) async {
    final r = await _api.createCompte(compte.toMap());
    if (r.success) {
      await _loadComptes();
      notifyListeners();
      return true;
    }
    _error = r.error;
    notifyListeners();
    return false;
  }

  Future<bool> deleteCompte(String compteId) async {
    final id = int.tryParse(compteId) ?? 0;
    final r = await _api.deleteCompte(id);
    if (r.success) {
      _comptes.removeWhere((c) => c.id == compteId);
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Créances ────────────────────────────────────────────────────────────────
  Future<bool> addCreance(Creance creance) async {
    final r = await _api.createCreance(creance.toMap());
    if (r.success) {
      await _loadCreances();
      notifyListeners();
      return true;
    }
    _error = r.error;
    notifyListeners();
    return false;
  }

  Future<bool> deleteCreance(String creanceId) async {
    final id = int.tryParse(creanceId) ?? 0;
    final r = await _api.deleteCreance(id);
    if (r.success) {
      _creances.removeWhere((c) => c.id == creanceId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> ajouterRemboursementCreance(
      String creanceId, double montant, DateTime date) async {
    final id = int.tryParse(creanceId) ?? 0;
    final r = await _api.addRemboursementCreance(id, {
      'montant': montant,
      'date_remboursement': date.toIso8601String().substring(0, 10),
    });
    if (r.success) {
      await _loadCreances();
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Dettes ──────────────────────────────────────────────────────────────────
  Future<bool> addDette(Dette dette) async {
    final r = await _api.createDette(dette.toMap());
    if (r.success) {
      await _loadDettes();
      notifyListeners();
      return true;
    }
    _error = r.error;
    notifyListeners();
    return false;
  }

  // ─── Certifications ──────────────────────────────────────────────────────────
  Future<bool> demanderCertification(String assetId, String typeAutorite) async {
    final r = await _api.demanderCertification({
      'asset_id': assetId,
      'type_autorite': typeAutorite,
    });
    if (r.success) {
      await Future.wait([_loadAssets(), _loadCertifications()]);
      notifyListeners();
      return true;
    }
    _error = r.error;
    notifyListeners();
    return false;
  }

  // ─── Marketplace ─────────────────────────────────────────────────────────────
  Future<bool> publierListing(
      String assetId, String type, double prix, String devise) async {
    final r = await _api.publishListing({
      'asset_id': assetId,
      'type': type,
      'prix': prix,
      'devise': devise,
    });
    if (r.success) {
      await _loadAssets();
      notifyListeners();
      return true;
    }
    _error = r.error;
    notifyListeners();
    return false;
  }

  Future<bool> retirerListing(String listingId) async {
    final id = int.tryParse(listingId) ?? 0;
    final r = await _api.withdrawListing(id);
    if (r.success) {
      await _loadAssets();
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Testament ────────────────────────────────────────────────────────────────
  Future<bool> saveTestament(Testament testament) async {
    ApiResponse r;
    final id = int.tryParse(testament.id ?? '') ?? 0;
    if (id > 0) {
      r = await _api.updateTestament(id, testament.toMap());
    } else {
      r = await _api.createTestament(testament.toMap());
    }
    if (r.success) {
      await _loadTestament();
      notifyListeners();
      return true;
    }
    _error = r.error;
    notifyListeners();
    return false;
  }

  Future<bool> finaliserTestament() async {
    final id = int.tryParse(_testament?.id ?? '') ?? 0;
    if (id == 0) return false;
    final r = await _api.finaliserTestament(id);
    if (r.success) {
      await _loadTestament();
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Évaluations ─────────────────────────────────────────────────────────────
  Future<bool> evaluerActif(String assetId, double nouvelleValeur) async {
    final r = await _api.createEvaluation({
      'asset_id': assetId,
      'valeur_nouvelle': nouvelleValeur,
    });
    if (r.success) {
      await _loadAssets();
      notifyListeners();
      return true;
    }
    _error = r.error;
    notifyListeners();
    return false;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Génère un ID temporaire côté client (avant confirmation du backend)
  String generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts % 9000 + 1000).toString();
    return 'tmp_${ts}_$rand';
  }

  List<Loyer> getLoYersByAsset(String assetId) =>
      _loyers.where((l) => l.assetId == assetId).toList();

  List<Certification> getCertificationsByAsset(String assetId) =>
      _certifications.where((c) => c.assetId == assetId).toList();

  Asset? getAssetById(String id) =>
      _assets.cast<Asset?>().firstWhere((a) => a?.id == id, orElse: () => null);
}
