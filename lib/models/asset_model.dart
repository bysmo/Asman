enum AssetType {
  immobilier,
  vehicule,
  investissement,
  creance,
  autre,
}

enum AssetStatus {
  actif,
  loue,
  vendu,
  inactif,
}

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
  String? locataire;
  DateTime? dateFinBail;

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
    this.locataire,
    this.dateFinBail,
  });

  double get plusValue => valeurActuelle - valeurInitiale;
  double get plusValuePourcentage =>
      valeurInitiale > 0 ? ((valeurActuelle - valeurInitiale) / valeurInitiale) * 100 : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'type': type.index,
      'statut': statut.index,
      'valeurActuelle': valeurActuelle,
      'valeurInitiale': valeurInitiale,
      'description': description,
      'devise': devise,
      'pays': pays,
      'dateAcquisition': dateAcquisition.toIso8601String(),
      'dateDerniereEvaluation': dateDerniereEvaluation?.toIso8601String(),
      'details': details,
      'photos': photos,
      'estLoue': estLoue,
      'loyerMensuel': loyerMensuel,
      'locataire': locataire,
      'dateFinBail': dateFinBail?.toIso8601String(),
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      type: AssetType.values[map['type'] ?? 0],
      statut: AssetStatus.values[map['statut'] ?? 0],
      valeurActuelle: (map['valeurActuelle'] ?? 0).toDouble(),
      valeurInitiale: (map['valeurInitiale'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      devise: map['devise'] ?? 'EUR',
      pays: map['pays'] ?? 'France',
      dateAcquisition: DateTime.parse(
          map['dateAcquisition'] ?? DateTime.now().toIso8601String()),
      dateDerniereEvaluation: map['dateDerniereEvaluation'] != null
          ? DateTime.parse(map['dateDerniereEvaluation'])
          : null,
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      photos: List<String>.from(map['photos'] ?? []),
      estLoue: map['estLoue'] ?? false,
      loyerMensuel: map['loyerMensuel']?.toDouble(),
      locataire: map['locataire'],
      dateFinBail: map['dateFinBail'] != null
          ? DateTime.parse(map['dateFinBail'])
          : null,
    );
  }
}

class Loyer {
  final String id;
  final String assetId;
  double montant;
  String devise;
  DateTime datePaiement;
  bool estPaye;
  String? notes;
  int mois;
  int annee;

  Loyer({
    required this.id,
    required this.assetId,
    required this.montant,
    this.devise = 'EUR',
    required this.datePaiement,
    this.estPaye = false,
    this.notes,
    required this.mois,
    required this.annee,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assetId': assetId,
      'montant': montant,
      'devise': devise,
      'datePaiement': datePaiement.toIso8601String(),
      'estPaye': estPaye,
      'notes': notes,
      'mois': mois,
      'annee': annee,
    };
  }

  factory Loyer.fromMap(Map<String, dynamic> map) {
    return Loyer(
      id: map['id'] ?? '',
      assetId: map['assetId'] ?? '',
      montant: (map['montant'] ?? 0).toDouble(),
      devise: map['devise'] ?? 'EUR',
      datePaiement:
          DateTime.parse(map['datePaiement'] ?? DateTime.now().toIso8601String()),
      estPaye: map['estPaye'] ?? false,
      notes: map['notes'],
      mois: map['mois'] ?? DateTime.now().month,
      annee: map['annee'] ?? DateTime.now().year,
    );
  }
}

class UserProfile {
  String id;
  String telephone;
  String nom;
  String prenom;
  String pays;
  String devise;
  DateTime dateCreation;

  UserProfile({
    required this.id,
    required this.telephone,
    this.nom = '',
    this.prenom = '',
    this.pays = 'France',
    this.devise = 'EUR',
    required this.dateCreation,
  });

  String get nomComplet => '$prenom $nom'.trim();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'telephone': telephone,
      'nom': nom,
      'prenom': prenom,
      'pays': pays,
      'devise': devise,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      telephone: map['telephone'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      pays: map['pays'] ?? 'France',
      devise: map['devise'] ?? 'EUR',
      dateCreation: DateTime.parse(
          map['dateCreation'] ?? DateTime.now().toIso8601String()),
    );
  }
}
