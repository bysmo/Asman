import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/asset_model.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

class AssetProvider extends ChangeNotifier {
  List<Asset> _assets = [];
  List<Loyer> _loyers = [];
  List<CompteBancaire> _comptes = [];
  List<Creance> _creances = [];
  List<Dette> _dettes = [];
  List<CertificationDemande> _certifications = [];
  List<MarketplaceListing> _listings = [];
  Testament? _testament;
  bool _isLoading = false;

  final StorageService _storage = StorageService();
  final _uuid = const Uuid();
  AuthProvider? _authProvider;

  void setAuthProvider(AuthProvider auth) {
    _authProvider = auth;
  }

  List<Asset> get assets => _assets;
  List<Loyer> get loyers => _loyers;
  List<CompteBancaire> get comptes => _comptes;
  List<Creance> get creances => _creances;
  List<Dette> get dettes => _dettes;
  List<CertificationDemande> get certifications => _certifications;
  List<MarketplaceListing> get listings => _listings;
  Testament? get testament => _testament;
  bool get isLoading => _isLoading;

  // ─── TOTAUX PATRIMOINE ────────────────────────────────────────────────────
  double get totalImmobilier => _totalByType(AssetType.immobilier);
  double get totalVehicules => _totalByType(AssetType.vehicule);
  double get totalInvestissements => _totalByType(AssetType.investissement);
  double get totalCreancesActifs => _totalByType(AssetType.creance);
  double get totalAutres => _totalByType(AssetType.autre);

  double _totalByType(AssetType t) => _assets
      .where((a) => a.type == t && a.statut != AssetStatus.vendu)
      .fold(0.0, (s, a) => s + a.valeurActuelle);

  double get totalComptesBancaires =>
      _comptes.where((c) => c.estActif).fold(0.0, (s, c) => s + c.solde);

  double get totalCreancesEnCours =>
      _creances.where((c) => !c.estRembourse).fold(0.0, (s, c) => s + c.montantRestant);

  double get totalDettesEnCours =>
      _dettes.where((d) => !d.estRembourse).fold(0.0, (s, d) => s + d.montantRestant);

  double get patrimoineTotal =>
      _assets.where((a) => a.statut != AssetStatus.vendu).fold(0.0, (s, a) => s + a.valeurActuelle) +
      totalComptesBancaires +
      totalCreancesEnCours -
      totalDettesEnCours;

  double get patrimoineNet => patrimoineTotal;

  double get loyersMensuelsTotaux => _assets
      .where((a) => a.estLoue && a.loyerMensuel != null)
      .fold(0.0, (s, a) => s + (a.loyerMensuel ?? 0));

  List<Asset> getAssetsByType(AssetType type) =>
      _assets.where((a) => a.type == type).toList();
  List<Asset> get assetsLoues => _assets.where((a) => a.estLoue).toList();
  List<Asset> get assetsCertifies =>
      _assets.where((a) => a.certificationStatus == CertificationStatus.certifie).toList();

  List<Loyer> getLoyersByAsset(String assetId) =>
      _loyers.where((l) => l.assetId == assetId).toList();

  double getLoyersPercusMois(int mois, int annee) => _loyers
      .where((l) => l.mois == mois && l.annee == annee && l.estPaye)
      .fold(0.0, (s, l) => s + l.montant);

  CertificationDemande? getCertificationByAsset(String assetId) {
    try {
      return _certifications.lastWhere((c) => c.assetId == assetId);
    } catch (_) {
      return null;
    }
  }

  List<MarketplaceListing> get listingsActifs =>
      _listings.where((l) => l.statut == ListingStatus.actif).toList();

  // ─── LOAD ─────────────────────────────────────────────────────────────────
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    _assets = await _storage.loadAssets();
    _loyers = await _storage.loadLoyers();
    _comptes = await _storage.loadComptes();
    _creances = await _storage.loadCreances();
    _dettes = await _storage.loadDettes();
    _certifications = await _storage.loadCertifications();
    _listings = await _storage.loadListings();
    _testament = await _storage.loadTestament();
    _isLoading = false;
    notifyListeners();
  }

  // ─── ASSETS CRUD ──────────────────────────────────────────────────────────
  Future<void> addAsset(Asset asset, {Map<String, String>? documents}) async {
    _assets.add(asset);
    await _storage.saveAssets(_assets);

    // Persister aussi en SQLite pour que la FK des documents soit satisfaite
    final auth = _authProvider;
    if (auth?.user != null) {
      try {
        await DatabaseService().createAsset(asset, auth!.user!.id);
      } catch (_) {} // peut échouer si l'asset existe déjà
    }

    // Si des documents accompagnent la création
    if (documents != null && documents.isNotEmpty) {
      await DatabaseService().addAssetDocuments(asset.id, documents);
    }

    notifyListeners();
  }

  Future<bool> checkAssetUniqueness(AssetType type, Map<String, dynamic> details) async {
    return await DatabaseService().checkAssetUniqueness(type, details);
  }

  Future<void> updateAsset(Asset updated) async {
    final i = _assets.indexWhere((a) => a.id == updated.id);
    if (i != -1) {
      _assets[i] = updated;
      await _storage.saveAssets(_assets);
      // Sync SQLite
      final auth = _authProvider;
      if (auth?.user != null) {
        try {
          await DatabaseService().updateAsset(updated);
        } catch (_) {}
      }
      notifyListeners();
    }
  }
  Future<void> deleteAsset(String id) async {
    _assets.removeWhere((a) => a.id == id);
    _loyers.removeWhere((l) => l.assetId == id);
    _certifications.removeWhere((c) => c.assetId == id);
    _listings.removeWhere((l) => l.assetId == id);
    await _storage.saveAssets(_assets);
    await _storage.saveLoyers(_loyers);
    notifyListeners();
  }
  Future<void> updateValeur(String id, double val) async {
    final i = _assets.indexWhere((a) => a.id == id);
    if (i != -1) {
      _assets[i].valeurActuelle = val;
      _assets[i].dateDerniereEvaluation = DateTime.now();
      await _storage.saveAssets(_assets);
      notifyListeners();
    }
  }

  // ─── LOYERS ───────────────────────────────────────────────────────────────
  Future<void> addLoyer(Loyer l) async { _loyers.add(l); await _storage.saveLoyers(_loyers); notifyListeners(); }
  Future<void> updateLoyer(Loyer l) async {
    final i = _loyers.indexWhere((x) => x.id == l.id);
    if (i != -1) { _loyers[i] = l; await _storage.saveLoyers(_loyers); notifyListeners(); }
  }

  /// Marquer une période (mois/année) comme payée
  Future<void> marquerPeriodePaye(String loyerId, int mois, int annee, {double? montantPaye, String? notes}) async {
    final i = _loyers.indexWhere((l) => l.id == loyerId);
    if (i == -1) return;
    final loyer = _loyers[i];
    final pi = loyer.periodes.indexWhere((p) => p.mois == mois && p.annee == annee);
    if (pi != -1) {
      loyer.periodes[pi].statut = StatutPeriodeLoyer.paye;
      loyer.periodes[pi].datePaiement = DateTime.now();
      loyer.periodes[pi].montantPaye = montantPaye ?? loyer.montant;
      loyer.periodes[pi].notes = notes;
    } else {
      loyer.periodes = [
        ...loyer.periodes,
        EncaissementPeriode(mois: mois, annee: annee, statut: StatutPeriodeLoyer.paye,
            datePaiement: DateTime.now(), montantPaye: montantPaye ?? loyer.montant, notes: notes),
      ];
    }
    await _storage.saveLoyers(_loyers);
    notifyListeners();
  }

  /// Marquer une période comme impayée
  Future<void> marquerPeriodeImpaye(String loyerId, int mois, int annee, {String? notes}) async {
    final i = _loyers.indexWhere((l) => l.id == loyerId);
    if (i == -1) return;
    final loyer = _loyers[i];
    final pi = loyer.periodes.indexWhere((p) => p.mois == mois && p.annee == annee);
    if (pi != -1) {
      loyer.periodes[pi].statut = StatutPeriodeLoyer.impaye;
      loyer.periodes[pi].notes = notes;
    } else {
      loyer.periodes = [
        ...loyer.periodes,
        EncaissementPeriode(mois: mois, annee: annee, statut: StatutPeriodeLoyer.impaye, notes: notes),
      ];
    }
    await _storage.saveLoyers(_loyers);
    notifyListeners();
  }

  /// Résilier la location d'un actif
  Future<void> resilierLocation(String assetId) async {
    final ia = _assets.indexWhere((a) => a.id == assetId);
    if (ia != -1) {
      _assets[ia].estLoue = false;
      _assets[ia].statut = AssetStatus.actif;
      _assets[ia].locataire = null;
      _assets[ia].dateFinBail = null;
      await _storage.saveAssets(_assets);
      try { await DatabaseService().updateAsset(_assets[ia]); } catch (_) {}
    }
    await _storage.saveLoyers(_loyers);
    notifyListeners();
  }


  // ─── COMPTES BANCAIRES ────────────────────────────────────────────────────
  Future<void> addCompte(CompteBancaire c) async { _comptes.add(c); await _storage.saveComptes(_comptes); notifyListeners(); }
  Future<void> updateCompte(CompteBancaire c) async {
    final i = _comptes.indexWhere((x) => x.id == c.id);
    if (i != -1) { _comptes[i] = c; await _storage.saveComptes(_comptes); notifyListeners(); }
  }
  Future<void> deleteCompte(String id) async { _comptes.removeWhere((c) => c.id == id); await _storage.saveComptes(_comptes); notifyListeners(); }

  // ─── CRÉANCES ─────────────────────────────────────────────────────────────
  Future<void> addCreance(Creance c) async { _creances.add(c); await _storage.saveCreances(_creances); notifyListeners(); }
  Future<void> updateCreance(Creance c) async {
    final i = _creances.indexWhere((x) => x.id == c.id);
    if (i != -1) { _creances[i] = c; await _storage.saveCreances(_creances); notifyListeners(); }
  }
  Future<void> deleteCreance(String id) async { _creances.removeWhere((c) => c.id == id); await _storage.saveCreances(_creances); notifyListeners(); }

  Future<void> ajouterRemboursementCreance(String creanceId, RemboursementCreance r) async {
    final i = _creances.indexWhere((c) => c.id == creanceId);
    if (i != -1) {
      _creances[i].remboursements = [..._creances[i].remboursements, r];
      _creances[i].montantRembourse += r.montant;
      if (_creances[i].montantRembourse >= _creances[i].montant) _creances[i].estRembourse = true;
      await _storage.saveCreances(_creances);
      notifyListeners();
    }
  }

  // ─── DETTES ───────────────────────────────────────────────────────────────
  Future<void> addDette(Dette d) async { _dettes.add(d); await _storage.saveDettes(_dettes); notifyListeners(); }
  Future<void> updateDette(Dette d) async {
    final i = _dettes.indexWhere((x) => x.id == d.id);
    if (i != -1) { _dettes[i] = d; await _storage.saveDettes(_dettes); notifyListeners(); }
  }
  Future<void> deleteDette(String id) async { _dettes.removeWhere((d) => d.id == id); await _storage.saveDettes(_dettes); notifyListeners(); }

  Future<void> ajouterRemboursementDette(String detteId, RemboursementCreance r) async {
    final i = _dettes.indexWhere((d) => d.id == detteId);
    if (i != -1) {
      _dettes[i].remboursements = [..._dettes[i].remboursements, r];
      _dettes[i].montantRembourse += r.montant;
      if (_dettes[i].montantRembourse >= _dettes[i].montant) _dettes[i].estRembourse = true;
      await _storage.saveDettes(_dettes);
      notifyListeners();
    }
  }

  // ─── CERTIFICATIONS ───────────────────────────────────────────────────────
  Future<void> demanderCertification(CertificationDemande c, List<Map<String, String>> docs) async {
    _certifications.add(c);
    final ai = _assets.indexWhere((a) => a.id == c.assetId);
    if (ai != -1) {
      _assets[ai].certificationStatus = CertificationStatus.enAttente;
      _assets[ai].certificationId = c.id;
      await _storage.saveAssets(_assets);
    }
    await _storage.saveCertifications(_certifications);
    // Placeholder: Plus tard, ces docs iront dans DatabaseService
    // await DatabaseService().demanderCertification(c, docs);
    notifyListeners();
  }

  // Simule l'approbation (en vrai: viendrait du backend)
  Future<void> approuverCertification(String certId) async {
    final ci = _certifications.indexWhere((c) => c.id == certId);
    if (ci != -1) {
      _certifications[ci].statut = CertificationStatus.certifie;
      _certifications[ci].dateTraitement = DateTime.now();
      final ai = _assets.indexWhere((a) => a.id == _certifications[ci].assetId);
      if (ai != -1) {
        _assets[ai].certificationStatus = CertificationStatus.certifie;
        _assets[ai].dateCertification = DateTime.now();
        _assets[ai].certificationAutoriteNom = _certifications[ci].autoriteNom;
        await _storage.saveAssets(_assets);
      }
      await _storage.saveCertifications(_certifications);
      notifyListeners();
    }
  }

  // ─── MARKETPLACE ──────────────────────────────────────────────────────────
  Future<void> publierListing(MarketplaceListing listing) async {
    _listings.add(listing);
    final ai = _assets.indexWhere((a) => a.id == listing.assetId);
    if (ai != -1) {
      if (listing.type == ListingType.vente) {
        _assets[ai].enVente = true;
        _assets[ai].prixVente = listing.prix;
      } else {
        _assets[ai].enLocation = true;
        _assets[ai].prixLocation = listing.prix;
      }
      _assets[ai].listingId = listing.id;
      await _storage.saveAssets(_assets);
    }
    await _storage.saveListings(_listings);
    notifyListeners();
  }

  Future<void> retirerListing(String listingId) async {
    final li = _listings.indexWhere((l) => l.id == listingId);
    if (li != -1) {
      final assetId = _listings[li].assetId;
      _listings[li].statut = ListingStatus.cloture;
      final ai = _assets.indexWhere((a) => a.id == assetId);
      if (ai != -1) {
        _assets[ai].enVente = false;
        _assets[ai].enLocation = false;
        await _storage.saveAssets(_assets);
      }
      await _storage.saveListings(_listings);
      notifyListeners();
    }
  }

  // ─── TESTAMENT ────────────────────────────────────────────────────────────
  Future<void> saveTestament(Testament t) async {
    _testament = t;
    await _storage.saveTestament(t);
    notifyListeners();
  }

  String generateId() => _uuid.v4();
}
