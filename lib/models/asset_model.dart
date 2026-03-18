enum AssetType {
  immobilier,
  vehicule,
  investissement,
  creance,
  dette,
  compteBancaire,
  autre,
}

enum AssetStatus {
  actif,
  loue,
  vendu,
  inactif,
}

enum CertificationStatus {
  nonDemande,
  enAttente,
  enCours,
  certifie,
  refuse,
}

enum ListingType {
  vente,
  location,
}

enum ListingStatus {
  actif,
  suspendu,
  cloture,
}

enum TestamentStatus {
  brouillon,
  finalise,
  certifie,
}

enum AyantDroitType {
  heritier,
  legataire,
  ascendant,
  conjoint,
  autre,
}

enum PeriodiciteLoyer {
  mensuelle,
  trimestrielle,
  semestrielle,
  annuelle,
}

// ─── ASSET ────────────────────────────────────────────────────────────────────
class Asset {
  final String id;
  String nom;
  AssetType type;
  AssetStatus statut;
  double valeurActuelle;
  double valeurInitiale;
  String description;
  String devise;
  String pays;
  DateTime dateAcquisition;
  DateTime? dateDerniereEvaluation;
  Map<String, dynamic> details;
  List<String> photos;
  bool estLoue;
  double? loyerMensuel;
  PeriodiciteLoyer periodiciteLoyer;
  String? locataire;
  DateTime? dateFinBail;

  // Certification
  CertificationStatus certificationStatus;
  String? certificationId;
  DateTime? dateCertification;
  String? certificationAutoriteNom;

  // Marketplace
  bool enVente;
  bool enLocation;
  double? prixVente;
  double? prixLocation;
  String? listingId;

  Asset({
    required this.id,
    required this.nom,
    required this.type,
    this.statut = AssetStatus.actif,
    required this.valeurActuelle,
    required this.valeurInitiale,
    this.description = '',
    this.devise = 'EUR',
    this.pays = 'France',
    required this.dateAcquisition,
    this.dateDerniereEvaluation,
    this.details = const {},
    this.photos = const [],
    this.estLoue = false,
    this.loyerMensuel,
    this.periodiciteLoyer = PeriodiciteLoyer.mensuelle,
    this.locataire,
    this.dateFinBail,
    this.certificationStatus = CertificationStatus.nonDemande,
    this.certificationId,
    this.dateCertification,
    this.certificationAutoriteNom,
    this.enVente = false,
    this.enLocation = false,
    this.prixVente,
    this.prixLocation,
    this.listingId,
  });

  bool get estCertifie => certificationStatus == CertificationStatus.certifie;
  double get plusValue => valeurActuelle - valeurInitiale;
  double get plusValuePourcentage =>
      valeurInitiale > 0 ? ((valeurActuelle - valeurInitiale) / valeurInitiale) * 100 : 0;

  Map<String, dynamic> toMap() => {
        'id': id, 'nom': nom, 'type': type.index, 'statut': statut.index,
        'valeurActuelle': valeurActuelle, 'valeurInitiale': valeurInitiale,
        'description': description, 'devise': devise, 'pays': pays,
        'dateAcquisition': dateAcquisition.toIso8601String(),
        'dateDerniereEvaluation': dateDerniereEvaluation?.toIso8601String(),
        'details': details, 'photos': photos, 'estLoue': estLoue,
        'loyerMensuel': loyerMensuel, 
        'periodiciteLoyer': periodiciteLoyer.index,
        'locataire': locataire,
        'dateFinBail': dateFinBail?.toIso8601String(),
        'certificationStatus': certificationStatus.index,
        'certificationId': certificationId,
        'dateCertification': dateCertification?.toIso8601String(),
        'certificationAutoriteNom': certificationAutoriteNom,
        'enVente': enVente, 'enLocation': enLocation,
        'prixVente': prixVente, 'prixLocation': prixLocation,
        'listingId': listingId,
      };

  factory Asset.fromMap(Map<String, dynamic> map) => Asset(
        id: map['id'] ?? '',
        nom: map['nom'] ?? '',
        type: AssetType.values[map['type'] ?? 0],
        statut: AssetStatus.values[map['statut'] ?? 0],
        valeurActuelle: (map['valeurActuelle'] ?? 0).toDouble(),
        valeurInitiale: (map['valeurInitiale'] ?? 0).toDouble(),
        description: map['description'] ?? '',
        devise: map['devise'] ?? 'EUR',
        pays: map['pays'] ?? 'France',
        dateAcquisition: DateTime.parse(map['dateAcquisition'] ?? DateTime.now().toIso8601String()),
        dateDerniereEvaluation: map['dateDerniereEvaluation'] != null ? DateTime.parse(map['dateDerniereEvaluation']) : null,
        details: Map<String, dynamic>.from(map['details'] ?? {}),
        photos: List<String>.from(map['photos'] ?? []),
        estLoue: map['estLoue'] ?? false,
        loyerMensuel: map['loyerMensuel']?.toDouble(),
        periodiciteLoyer: PeriodiciteLoyer.values[map['periodiciteLoyer'] ?? 0],
        locataire: map['locataire'],
        dateFinBail: map['dateFinBail'] != null ? DateTime.parse(map['dateFinBail']) : null,
        certificationStatus: CertificationStatus.values[map['certificationStatus'] ?? 0],
        certificationId: map['certificationId'],
        dateCertification: map['dateCertification'] != null ? DateTime.parse(map['dateCertification']) : null,
        certificationAutoriteNom: map['certificationAutoriteNom'],
        enVente: map['enVente'] ?? false,
        enLocation: map['enLocation'] ?? false,
        prixVente: map['prixVente']?.toDouble(),
        prixLocation: map['prixLocation']?.toDouble(),
        listingId: map['listingId'],
      );
}

// ─── COMPTE BANCAIRE ──────────────────────────────────────────────────────────
class CompteBancaire {
  final String id;
  String nomBanque;
  String numeroCompte;
  String typeCompte; // courant, épargne, investissement, crypto
  double solde;
  String devise;
  String pays;
  String? iban;
  String? swift;
  String description;
  DateTime dateOuverture;
  bool estActif;

  CompteBancaire({
    required this.id,
    required this.nomBanque,
    required this.numeroCompte,
    this.typeCompte = 'courant',
    required this.solde,
    this.devise = 'EUR',
    this.pays = 'France',
    this.iban,
    this.swift,
    this.description = '',
    required this.dateOuverture,
    this.estActif = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'nomBanque': nomBanque, 'numeroCompte': numeroCompte,
        'typeCompte': typeCompte, 'solde': solde, 'devise': devise,
        'pays': pays, 'iban': iban, 'swift': swift,
        'description': description,
        'dateOuverture': dateOuverture.toIso8601String(),
        'estActif': estActif,
      };

  factory CompteBancaire.fromMap(Map<String, dynamic> map) => CompteBancaire(
        id: map['id'] ?? '',
        nomBanque: map['nomBanque'] ?? '',
        numeroCompte: map['numeroCompte'] ?? '',
        typeCompte: map['typeCompte'] ?? 'courant',
        solde: (map['solde'] ?? 0).toDouble(),
        devise: map['devise'] ?? 'EUR',
        pays: map['pays'] ?? 'France',
        iban: map['iban'],
        swift: map['swift'],
        description: map['description'] ?? '',
        dateOuverture: DateTime.parse(map['dateOuverture'] ?? DateTime.now().toIso8601String()),
        estActif: map['estActif'] ?? true,
      );
}

// ─── CRÉANCE ──────────────────────────────────────────────────────────────────
class Creance {
  final String id;
  String debiteurNom;
  String debiteurContact;
  double montant;
  double montantRembourse;
  String devise;
  String description;
  DateTime dateCreance;
  DateTime? dateEcheance;
  bool estRembourse;
  double? tauxInteret;
  List<RemboursementCreance> remboursements;

  Creance({
    required this.id,
    required this.debiteurNom,
    this.debiteurContact = '',
    required this.montant,
    this.montantRembourse = 0,
    this.devise = 'EUR',
    this.description = '',
    required this.dateCreance,
    this.dateEcheance,
    this.estRembourse = false,
    this.tauxInteret,
    this.remboursements = const [],
  });

  double get montantRestant => montant - montantRembourse;
  double get pourcentageRembourse => montant > 0 ? (montantRembourse / montant) * 100 : 0;
  bool get estEnRetard => dateEcheance != null && DateTime.now().isAfter(dateEcheance!) && !estRembourse;

  Map<String, dynamic> toMap() => {
        'id': id, 'debiteurNom': debiteurNom, 'debiteurContact': debiteurContact,
        'montant': montant, 'montantRembourse': montantRembourse,
        'devise': devise, 'description': description,
        'dateCreance': dateCreance.toIso8601String(),
        'dateEcheance': dateEcheance?.toIso8601String(),
        'estRembourse': estRembourse, 'tauxInteret': tauxInteret,
        'remboursements': remboursements.map((r) => r.toMap()).toList(),
      };

  factory Creance.fromMap(Map<String, dynamic> map) => Creance(
        id: map['id'] ?? '',
        debiteurNom: map['debiteurNom'] ?? '',
        debiteurContact: map['debiteurContact'] ?? '',
        montant: (map['montant'] ?? 0).toDouble(),
        montantRembourse: (map['montantRembourse'] ?? 0).toDouble(),
        devise: map['devise'] ?? 'EUR',
        description: map['description'] ?? '',
        dateCreance: DateTime.parse(map['dateCreance'] ?? DateTime.now().toIso8601String()),
        dateEcheance: map['dateEcheance'] != null ? DateTime.parse(map['dateEcheance']) : null,
        estRembourse: map['estRembourse'] ?? false,
        tauxInteret: map['tauxInteret']?.toDouble(),
        remboursements: (map['remboursements'] as List? ?? [])
            .map((r) => RemboursementCreance.fromMap(Map<String, dynamic>.from(r)))
            .toList(),
      );
}

class RemboursementCreance {
  final String id;
  double montant;
  DateTime date;
  String notes;

  RemboursementCreance({required this.id, required this.montant, required this.date, this.notes = ''});

  Map<String, dynamic> toMap() => {'id': id, 'montant': montant, 'date': date.toIso8601String(), 'notes': notes};
  factory RemboursementCreance.fromMap(Map<String, dynamic> map) => RemboursementCreance(
        id: map['id'] ?? '', montant: (map['montant'] ?? 0).toDouble(),
        date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
        notes: map['notes'] ?? '',
      );
}

// ─── DETTE ────────────────────────────────────────────────────────────────────
class Dette {
  final String id;
  String creancierNom;
  String creancierContact;
  double montant;
  double montantRembourse;
  String devise;
  String description;
  DateTime dateDette;
  DateTime? dateEcheance;
  bool estRembourse;
  double? tauxInteret;
  List<RemboursementCreance> remboursements;

  Dette({
    required this.id,
    required this.creancierNom,
    this.creancierContact = '',
    required this.montant,
    this.montantRembourse = 0,
    this.devise = 'EUR',
    this.description = '',
    required this.dateDette,
    this.dateEcheance,
    this.estRembourse = false,
    this.tauxInteret,
    this.remboursements = const [],
  });

  double get montantRestant => montant - montantRembourse;
  double get pourcentageRembourse => montant > 0 ? (montantRembourse / montant) * 100 : 0;
  bool get estEnRetard => dateEcheance != null && DateTime.now().isAfter(dateEcheance!) && !estRembourse;

  Map<String, dynamic> toMap() => {
        'id': id, 'creancierNom': creancierNom, 'creancierContact': creancierContact,
        'montant': montant, 'montantRembourse': montantRembourse,
        'devise': devise, 'description': description,
        'dateDette': dateDette.toIso8601String(),
        'dateEcheance': dateEcheance?.toIso8601String(),
        'estRembourse': estRembourse, 'tauxInteret': tauxInteret,
        'remboursements': remboursements.map((r) => r.toMap()).toList(),
      };

  factory Dette.fromMap(Map<String, dynamic> map) => Dette(
        id: map['id'] ?? '',
        creancierNom: map['creancierNom'] ?? '',
        creancierContact: map['creancierContact'] ?? '',
        montant: (map['montant'] ?? 0).toDouble(),
        montantRembourse: (map['montantRembourse'] ?? 0).toDouble(),
        devise: map['devise'] ?? 'EUR',
        description: map['description'] ?? '',
        dateDette: DateTime.parse(map['dateDette'] ?? DateTime.now().toIso8601String()),
        dateEcheance: map['dateEcheance'] != null ? DateTime.parse(map['dateEcheance']) : null,
        estRembourse: map['estRembourse'] ?? false,
        tauxInteret: map['tauxInteret']?.toDouble(),
        remboursements: (map['remboursements'] as List? ?? [])
            .map((r) => RemboursementCreance.fromMap(Map<String, dynamic>.from(r)))
            .toList(),
      );
}

// ─── CERTIFICATION ────────────────────────────────────────────────────────────
class CertificationDemande {
  final String id;
  final String assetId;
  String assetNom;
  AssetType assetType;
  CertificationStatus statut;
  String autoriteType; // notaire, huissier, tribunal, cadastre
  String autoriteNom;
  String autoriteContact;
  double frais;
  String devise;
  DateTime dateDemande;
  DateTime? dateTraitement;
  String notes;
  String? refus;
  bool paiementEffectue;
  double? partAutorite; // % revenu sharing
  double? partPlateforme;

  CertificationDemande({
    required this.id,
    required this.assetId,
    required this.assetNom,
    required this.assetType,
    this.statut = CertificationStatus.enAttente,
    this.autoriteType = 'notaire',
    this.autoriteNom = '',
    this.autoriteContact = '',
    this.frais = 0,
    this.devise = 'EUR',
    required this.dateDemande,
    this.dateTraitement,
    this.notes = '',
    this.refus,
    this.paiementEffectue = false,
    this.partAutorite = 70,
    this.partPlateforme = 30,
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'assetId': assetId, 'assetNom': assetNom,
        'assetType': assetType.index, 'statut': statut.index,
        'autoriteType': autoriteType, 'autoriteNom': autoriteNom,
        'autoriteContact': autoriteContact, 'frais': frais, 'devise': devise,
        'dateDemande': dateDemande.toIso8601String(),
        'dateTraitement': dateTraitement?.toIso8601String(),
        'notes': notes, 'refus': refus,
        'paiementEffectue': paiementEffectue,
        'partAutorite': partAutorite, 'partPlateforme': partPlateforme,
      };

  factory CertificationDemande.fromMap(Map<String, dynamic> map) => CertificationDemande(
        id: map['id'] ?? '',
        assetId: map['assetId'] ?? '',
        assetNom: map['assetNom'] ?? '',
        assetType: AssetType.values[map['assetType'] ?? 0],
        statut: CertificationStatus.values[map['statut'] ?? 0],
        autoriteType: map['autoriteType'] ?? 'notaire',
        autoriteNom: map['autoriteNom'] ?? '',
        autoriteContact: map['autoriteContact'] ?? '',
        frais: (map['frais'] ?? 0).toDouble(),
        devise: map['devise'] ?? 'EUR',
        dateDemande: DateTime.parse(map['dateDemande'] ?? DateTime.now().toIso8601String()),
        dateTraitement: map['dateTraitement'] != null ? DateTime.parse(map['dateTraitement']) : null,
        notes: map['notes'] ?? '',
        refus: map['refus'],
        paiementEffectue: map['paiementEffectue'] ?? false,
        partAutorite: map['partAutorite']?.toDouble() ?? 70,
        partPlateforme: map['partPlateforme']?.toDouble() ?? 30,
      );
}

// ─── MARKETPLACE LISTING ──────────────────────────────────────────────────────
class MarketplaceListing {
  final String id;
  final String assetId;
  final String proprietaireId;
  String proprietaireNom;
  String proprietaireTel;
  ListingType type;
  ListingStatus statut;
  double prix;
  String devise;
  String titre;
  String description;
  List<String> photos;
  String pays;
  String localisation;
  DateTime datePublication;
  DateTime? dateExpiration;
  int vues;
  List<String> contactsInteresses;

  // ─── Champs spécifiques VENTE
  DateTime? dateMiseEnVente;
  bool prixNegociable;
  String conditionsVente; // conditions particulières

  // ─── Champs spécifiques LOCATION
  int dureeMois;           // durée en mois (0 = illimité)
  int nbRenouvellements;   // -1 = illimité
  double montantCaution;
  double montantAvance;

  MarketplaceListing({
    required this.id,
    required this.assetId,
    required this.proprietaireId,
    this.proprietaireNom = '',
    this.proprietaireTel = '',
    required this.type,
    this.statut = ListingStatus.actif,
    required this.prix,
    this.devise = 'XOF',
    required this.titre,
    this.description = '',
    this.photos = const [],
    this.pays = 'Burkina Faso',
    this.localisation = '',
    required this.datePublication,
    this.dateExpiration,
    this.vues = 0,
    this.contactsInteresses = const [],
    // Vente
    this.dateMiseEnVente,
    this.prixNegociable = false,
    this.conditionsVente = '',
    // Location
    this.dureeMois = 12,
    this.nbRenouvellements = -1,
    this.montantCaution = 0,
    this.montantAvance = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'assetId': assetId, 'proprietaireId': proprietaireId,
        'proprietaireNom': proprietaireNom, 'proprietaireTel': proprietaireTel,
        'type': type.index, 'statut': statut.index,
        'prix': prix, 'devise': devise, 'titre': titre,
        'description': description, 'photos': photos, 'pays': pays,
        'localisation': localisation,
        'datePublication': datePublication.toIso8601String(),
        'dateExpiration': dateExpiration?.toIso8601String(),
        'vues': vues, 'contactsInteresses': contactsInteresses,
        // Vente
        'dateMiseEnVente': dateMiseEnVente?.toIso8601String(),
        'prixNegociable': prixNegociable,
        'conditionsVente': conditionsVente,
        // Location
        'dureeMois': dureeMois,
        'nbRenouvellements': nbRenouvellements,
        'montantCaution': montantCaution,
        'montantAvance': montantAvance,
      };

  factory MarketplaceListing.fromMap(Map<String, dynamic> map) => MarketplaceListing(
        id: map['id'] ?? '',
        assetId: map['assetId'] ?? '',
        proprietaireId: map['proprietaireId'] ?? '',
        proprietaireNom: map['proprietaireNom'] ?? '',
        proprietaireTel: map['proprietaireTel'] ?? '',
        type: ListingType.values[map['type'] ?? 0],
        statut: ListingStatus.values[map['statut'] ?? 0],
        prix: (map['prix'] ?? 0).toDouble(),
        devise: map['devise'] ?? 'XOF',
        titre: map['titre'] ?? '',
        description: map['description'] ?? '',
        photos: List<String>.from(map['photos'] ?? []),
        pays: map['pays'] ?? 'Burkina Faso',
        localisation: map['localisation'] ?? '',
        datePublication: DateTime.parse(map['datePublication'] ?? DateTime.now().toIso8601String()),
        dateExpiration: map['dateExpiration'] != null ? DateTime.parse(map['dateExpiration']) : null,
        vues: map['vues'] ?? 0,
        contactsInteresses: List<String>.from(map['contactsInteresses'] ?? []),
        // Vente
        dateMiseEnVente: map['dateMiseEnVente'] != null ? DateTime.parse(map['dateMiseEnVente']) : null,
        prixNegociable: map['prixNegociable'] ?? false,
        conditionsVente: map['conditionsVente'] ?? '',
        // Location
        dureeMois: map['dureeMois'] ?? 12,
        nbRenouvellements: map['nbRenouvellements'] ?? -1,
        montantCaution: (map['montantCaution'] ?? 0).toDouble(),
        montantAvance: (map['montantAvance'] ?? 0).toDouble(),
      );
}

// ─── TESTAMENT ────────────────────────────────────────────────────────────────
class Testament {
  final String id;
  final String userId;
  TestamentStatus statut;
  String notes;
  DateTime dateCreation;
  DateTime? dateModification;
  DateTime? dateCertification;
  String? notaireNom;
  String? notaireContact;
  String? certificationRef;
  List<AyantDroit> ayantsDroits;
  List<RepartitionBien> repartitions;
  bool paiementCertifEffectue;

  Testament({
    required this.id,
    required this.userId,
    this.statut = TestamentStatus.brouillon,
    this.notes = '',
    required this.dateCreation,
    this.dateModification,
    this.dateCertification,
    this.notaireNom,
    this.notaireContact,
    this.certificationRef,
    this.ayantsDroits = const [],
    this.repartitions = const [],
    this.paiementCertifEffectue = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'userId': userId, 'statut': statut.index,
        'notes': notes, 'dateCreation': dateCreation.toIso8601String(),
        'dateModification': dateModification?.toIso8601String(),
        'dateCertification': dateCertification?.toIso8601String(),
        'notaireNom': notaireNom, 'notaireContact': notaireContact,
        'certificationRef': certificationRef,
        'ayantsDroits': ayantsDroits.map((a) => a.toMap()).toList(),
        'repartitions': repartitions.map((r) => r.toMap()).toList(),
        'paiementCertifEffectue': paiementCertifEffectue,
      };

  factory Testament.fromMap(Map<String, dynamic> map) => Testament(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        statut: TestamentStatus.values[map['statut'] ?? 0],
        notes: map['notes'] ?? '',
        dateCreation: DateTime.parse(map['dateCreation'] ?? DateTime.now().toIso8601String()),
        dateModification: map['dateModification'] != null ? DateTime.parse(map['dateModification']) : null,
        dateCertification: map['dateCertification'] != null ? DateTime.parse(map['dateCertification']) : null,
        notaireNom: map['notaireNom'],
        notaireContact: map['notaireContact'],
        certificationRef: map['certificationRef'],
        ayantsDroits: (map['ayantsDroits'] as List? ?? [])
            .map((a) => AyantDroit.fromMap(Map<String, dynamic>.from(a))).toList(),
        repartitions: (map['repartitions'] as List? ?? [])
            .map((r) => RepartitionBien.fromMap(Map<String, dynamic>.from(r))).toList(),
        paiementCertifEffectue: map['paiementCertifEffectue'] ?? false,
      );
}

class AyantDroit {
  final String id;
  String nom;
  String prenom;
  AyantDroitType type;
  String lienParente;
  String contact;
  String nationalite;
  String numeroPieceIdentite;
  DateTime? dateNaissance;
  String notes;

  AyantDroit({
    required this.id,
    required this.nom,
    this.prenom = '',
    this.type = AyantDroitType.heritier,
    this.lienParente = '',
    this.contact = '',
    this.nationalite = '',
    this.numeroPieceIdentite = '',
    this.dateNaissance,
    this.notes = '',
  });

  String get nomComplet => '$prenom $nom'.trim();

  Map<String, dynamic> toMap() => {
        'id': id, 'nom': nom, 'prenom': prenom, 'type': type.index,
        'lienParente': lienParente, 'contact': contact,
        'nationalite': nationalite, 'numeroPieceIdentite': numeroPieceIdentite,
        'dateNaissance': dateNaissance?.toIso8601String(), 'notes': notes,
      };

  factory AyantDroit.fromMap(Map<String, dynamic> map) => AyantDroit(
        id: map['id'] ?? '', nom: map['nom'] ?? '', prenom: map['prenom'] ?? '',
        type: AyantDroitType.values[map['type'] ?? 0],
        lienParente: map['lienParente'] ?? '', contact: map['contact'] ?? '',
        nationalite: map['nationalite'] ?? '',
        numeroPieceIdentite: map['numeroPieceIdentite'] ?? '',
        dateNaissance: map['dateNaissance'] != null ? DateTime.parse(map['dateNaissance']) : null,
        notes: map['notes'] ?? '',
      );
}

class RepartitionBien {
  final String id;
  final String testamentId;
  final String assetId;
  String assetNom;
  final String ayantDroitId;
  String ayantDroitNom;
  double pourcentage;
  String conditions;
  String notes;

  RepartitionBien({
    required this.id,
    required this.testamentId,
    required this.assetId,
    this.assetNom = '',
    required this.ayantDroitId,
    this.ayantDroitNom = '',
    required this.pourcentage,
    this.conditions = '',
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'testamentId': testamentId, 'assetId': assetId, 'assetNom': assetNom,
        'ayantDroitId': ayantDroitId, 'ayantDroitNom': ayantDroitNom,
        'pourcentage': pourcentage, 'conditions': conditions, 'notes': notes,
      };

  factory RepartitionBien.fromMap(Map<String, dynamic> map) => RepartitionBien(
        id: map['id'] ?? '', testamentId: map['testamentId'] ?? '', assetId: map['assetId'] ?? '',
        assetNom: map['assetNom'] ?? '',
        ayantDroitId: map['ayantDroitId'] ?? '',
        ayantDroitNom: map['ayantDroitNom'] ?? '',
        pourcentage: (map['pourcentage'] ?? 0).toDouble(),
        conditions: map['conditions'] ?? '', notes: map['notes'] ?? '',
      );
}

// ─── LOYER ────────────────────────────────────────────────────────────────────
// ─── LOYER PERIODE ───────────────────────────────────────────────────────────────
enum StatutPeriodeLoyer { enAttente, paye, impaye }

class EncaissementPeriode {
  int mois;
  int annee;
  StatutPeriodeLoyer statut;
  DateTime? datePaiement;
  double? montantPaye; // peut différer si paiement partiel
  String? notes;

  EncaissementPeriode({
    required this.mois,
    required this.annee,
    this.statut = StatutPeriodeLoyer.enAttente,
    this.datePaiement,
    this.montantPaye,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'mois': mois,
    'annee': annee,
    'statut': statut.index,
    'datePaiement': datePaiement?.toIso8601String(),
    'montantPaye': montantPaye,
    'notes': notes,
  };

  factory EncaissementPeriode.fromMap(Map<String, dynamic> m) => EncaissementPeriode(
    mois: m['mois'] ?? DateTime.now().month,
    annee: m['annee'] ?? DateTime.now().year,
    statut: StatutPeriodeLoyer.values[m['statut'] ?? 0],
    datePaiement: m['datePaiement'] != null ? DateTime.parse(m['datePaiement']) : null,
    montantPaye: m['montantPaye']?.toDouble(),
    notes: m['notes'],
  );
}

class Loyer {
  final String id;
  final String assetId;
  double montant;
  String devise;
  bool estPaye;
  String? notes;
  int mois;
  int annee;
  String? locataireNom;
  // Historique des périodes d'encaissement
  List<EncaissementPeriode> periodes;

  Loyer({
    required this.id, required this.assetId, required this.montant,
    this.devise = 'XOF',
    this.estPaye = false, this.notes,
    required this.mois, required this.annee,
    this.locataireNom,
    this.periodes = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'assetId': assetId, 'montant': montant, 'devise': devise,
        'estPaye': estPaye, 'notes': notes, 'mois': mois, 'annee': annee,
        'locataireNom': locataireNom,
        'periodes': periodes.map((p) => p.toMap()).toList(),
      };

  factory Loyer.fromMap(Map<String, dynamic> map) => Loyer(
        id: map['id'] ?? '', assetId: map['assetId'] ?? '',
        montant: (map['montant'] ?? 0).toDouble(), devise: map['devise'] ?? 'XOF',
        estPaye: map['estPaye'] ?? false, notes: map['notes'],
        mois: map['mois'] ?? DateTime.now().month, annee: map['annee'] ?? DateTime.now().year,
        locataireNom: map['locataireNom'],
        periodes: (map['periodes'] as List<dynamic>? ?? []).map((p) =>
            EncaissementPeriode.fromMap(Map<String, dynamic>.from(p))).toList(),
      );
}

// ─── USER PROFILE ─────────────────────────────────────────────────────────────
class UserProfile {
  String id;
  String telephone;
  String email;
  String nom;
  String prenom;
  String pays;
  String devise;
  DateTime dateCreation;
  bool emailVerifie;
  String? pinCode; // SHA-256 hash du code PIN 4 chiffres

  UserProfile({
    required this.id, required this.telephone,
    this.email = '',
    this.nom = '', this.prenom = '',
    this.pays = 'France', this.devise = 'EUR',
    required this.dateCreation,
    this.emailVerifie = false,
    this.pinCode,
  });

  String get nomComplet => '$prenom $nom'.trim();
  bool get hasPinConfigured => pinCode != null && pinCode!.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'id': id, 'telephone': telephone, 'email': email,
        'nom': nom, 'prenom': prenom,
        'pays': pays, 'devise': devise,
        'dateCreation': dateCreation.toIso8601String(),
        'emailVerifie': emailVerifie,
        'pinCode': pinCode,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] ?? '', telephone: map['telephone'] ?? '',
        email: map['email'] ?? '',
        nom: map['nom'] ?? '', prenom: map['prenom'] ?? '',
        pays: map['pays'] ?? 'France', devise: map['devise'] ?? 'EUR',
        dateCreation: DateTime.parse(map['dateCreation'] ?? DateTime.now().toIso8601String()),
        emailVerifie: (map['emailVerifie'] ?? false) == true || (map['emailVerifie'] ?? 0) == 1,
        pinCode: map['pinCode'],
      );
}
