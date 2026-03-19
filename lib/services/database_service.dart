import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/asset_model.dart';
import 'dart:async';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'asman.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Table Auth & User
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        telephone TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE,
        password_hash TEXT NOT NULL,
        nom TEXT,
        prenom TEXT,
        pays TEXT DEFAULT 'Burkina Faso',
        devise TEXT DEFAULT 'XOF',
        date_creation TEXT NOT NULL,
        email_verifie INTEGER DEFAULT 0,
        pin_code TEXT,
        otp_code TEXT,
        otp_expiry TEXT,
        kyc_status INTEGER DEFAULT 0,
        date_naissance TEXT,
        type_piece_identite TEXT,
        numero_piece TEXT,
        document_identite_recto TEXT,
        document_identite_verso TEXT,
        selfie TEXT,
        fonction TEXT,
        adresse_residence TEXT,
        nationalite TEXT,
        nom_complet_pere TEXT,
        nom_complet_mere TEXT
      )
    ''');

    // 2. Table des types d'actifs et leurs documents requis
    await db.execute('''
      CREATE TABLE asset_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL UNIQUE,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE asset_type_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_type_id INTEGER NOT NULL,
        nom_document TEXT NOT NULL,
        est_obligatoire INTEGER DEFAULT 1,
        FOREIGN KEY (asset_type_id) REFERENCES asset_types (id) ON DELETE CASCADE
      )
    ''');

    // Insertion des types de base et leurs documents
    for (var type in AssetType.values) {
      await db.insert('asset_types', {'id': type.index, 'nom': type.name});
      
      // Seeders des documents par type
      List<String> docsRequise = [];
      if (type == AssetType.immobilier) {
        docsRequise = ['Titre foncier / Attestation d\'attribution', 'Plan cadastral', 'Pièce d\'identité du propriétaire'];
      } else if (type == AssetType.vehicule) {
        docsRequise = ['Carte grise', 'Certificat de visite technique', 'Pièce d\'identité du propriétaire'];
      } else if (type == AssetType.investissement) {
        docsRequise = ['Certificat d\'actions / Parts sociales', 'Extrait RCCM / Statuts', 'Pièce d\'identité'];
      } else if (type == AssetType.creance || type == AssetType.dette) {
        docsRequise = ['Contrat de prêt / Reconnaissance de dette', 'Copie de la pièce d\'identité du débiteur/créancier'];
      } else if (type == AssetType.compteBancaire) {
        docsRequise = ['Relevé d\'identité bancaire (RIB)', 'Attestation de solde'];
      } else if (type == AssetType.objetsLuxe) {
        docsRequise = ['Certificat d\'authenticité', 'Facture d\'achat'];
      } else if (type == AssetType.cheptelAnimal) {
        docsRequise = ['Certificat de propriété', 'Carnet de vaccination'];
      } else if (type == AssetType.droitsAuteur) {
        docsRequise = ['Certificat d\'enregistrement', 'Preuve de création'];
      } else if (type == AssetType.marquesBrevets) {
        docsRequise = ['Certificat de dépôt', 'Titre de propriété industrielle'];
      }

      for (var doc in docsRequise) {
        await db.insert('asset_type_documents', {
          'asset_type_id': type.index,
          'nom_document': doc,
          'est_obligatoire': 1,
        });
      }
    }

    // 3. Table principale des actifs
    await db.execute('''
      CREATE TABLE assets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        asset_type_id INTEGER NOT NULL,
        nom TEXT NOT NULL,
        statut INTEGER DEFAULT 0,
        valeur_actuelle REAL NOT NULL,
        valeur_initiale REAL NOT NULL,
        description TEXT,
        devise TEXT DEFAULT 'XOF',
        pays TEXT DEFAULT 'Burkina Faso',
        date_acquisition TEXT NOT NULL,
        date_derniere_evaluation TEXT,
        est_loue INTEGER DEFAULT 0,
        loyer_mensuel REAL,
        periodicite_loyer INTEGER DEFAULT 0,
        locataire TEXT,
        date_fin_bail TEXT,
        certification_status INTEGER DEFAULT 0,
        certification_id TEXT,
        date_certification TEXT,
        certification_autorite_nom TEXT,
        en_vente INTEGER DEFAULT 0,
        en_location INTEGER DEFAULT 0,
        prix_vente REAL,
        prix_location REAL,
        listing_id TEXT,
        details TEXT,
        photos TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (asset_type_id) REFERENCES asset_types (id)
      )
    ''');

    // 4. Tables Précises Financières (héritées conceptuellement de `assets` ou gérées à part selon l'UI)
    await db.execute('''
      CREATE TABLE comptes_bancaires (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        nom_banque TEXT NOT NULL,
        numero_compte TEXT NOT NULL,
        type_compte TEXT DEFAULT 'courant',
        solde REAL NOT NULL,
        devise TEXT DEFAULT 'XOF',
        pays TEXT DEFAULT 'Burkina Faso',
        iban TEXT,
        swift TEXT,
        description TEXT,
        date_ouverture TEXT NOT NULL,
        est_actif INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE creances (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        debiteur_nom TEXT NOT NULL,
        debiteur_contact TEXT,
        montant REAL NOT NULL,
        montant_rembourse REAL DEFAULT 0,
        devise TEXT DEFAULT 'EUR',
        description TEXT,
        date_creance TEXT NOT NULL,
        date_echeance TEXT,
        est_rembourse INTEGER DEFAULT 0,
        taux_interet REAL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE dettes (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        creancier_nom TEXT NOT NULL,
        creancier_contact TEXT,
        montant REAL NOT NULL,
        montant_rembourse REAL DEFAULT 0,
        devise TEXT DEFAULT 'EUR',
        description TEXT,
        date_dette TEXT NOT NULL,
        date_echeance TEXT,
        est_rembourse INTEGER DEFAULT 0,
        taux_interet REAL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 5. Tables de Transactions & Actions
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        type_transaction TEXT NOT NULL,
        montant REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE loyers (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        montant REAL NOT NULL,
        devise TEXT DEFAULT 'EUR',
        date_paiement TEXT NOT NULL,
        est_paye INTEGER DEFAULT 0,
        notes TEXT,
        mois INTEGER NOT NULL,
        annee INTEGER NOT NULL,
        FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE remboursements_creances (
        id TEXT PRIMARY KEY,
        creance_id TEXT NOT NULL,
        montant REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (creance_id) REFERENCES creances (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE remboursements_dettes (
        id TEXT PRIMARY KEY,
        dette_id TEXT NOT NULL,
        montant REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (dette_id) REFERENCES dettes (id) ON DELETE CASCADE
      )
    ''');

    // 6. Succession (Testament)
    await db.execute('''
      CREATE TABLE testaments (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL UNIQUE,
        statut INTEGER DEFAULT 0,
        notes TEXT,
        date_creation TEXT NOT NULL,
        date_modification TEXT,
        date_certification TEXT,
        notaire_nom TEXT,
        notaire_contact TEXT,
        certification_ref TEXT,
        paiement_certif_effectue INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ayants_droits (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        nom TEXT NOT NULL,
        prenom TEXT,
        type INTEGER DEFAULT 0,
        lien_parente TEXT,
        contact TEXT,
        nationalite TEXT,
        numero_piece_identite TEXT,
        date_naissance TEXT,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE repartitions_biens (
        id TEXT PRIMARY KEY,
        testament_id TEXT NOT NULL,
        asset_id TEXT NOT NULL,
        ayant_droit_id TEXT NOT NULL,
        pourcentage REAL NOT NULL,
        conditions TEXT,
        notes TEXT,
        FOREIGN KEY (testament_id) REFERENCES testaments (id) ON DELETE CASCADE,
        FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE,
        FOREIGN KEY (ayant_droit_id) REFERENCES ayants_droits (id) ON DELETE CASCADE
      )
    ''');

    // 7. Documents liés à un actif (Dès la création)
    await db.execute('''
      CREATE TABLE asset_documents (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        nom_document TEXT NOT NULL,
        file_path TEXT NOT NULL,
        FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE
      )
    ''');

    // 8. Certifications & Marketplace
    await db.execute('''
      CREATE TABLE certifications_demandes (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        asset_nom TEXT NOT NULL,
        asset_type_id INTEGER NOT NULL,
        statut INTEGER DEFAULT 1,
        autorite_type TEXT DEFAULT 'notaire',
        autorite_nom TEXT,
        autorite_contact TEXT,
        frais REAL DEFAULT 0,
        devise TEXT DEFAULT 'EUR',
        date_demande TEXT NOT NULL,
        date_traitement TEXT,
        notes TEXT,
        refus TEXT,
        paiement_effectue INTEGER DEFAULT 0,
        part_autorite REAL DEFAULT 70,
        part_plateforme REAL DEFAULT 30,
        FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE certification_documents (
        id TEXT PRIMARY KEY,
        demande_id TEXT NOT NULL,
        nom_document TEXT NOT NULL,
        file_path TEXT NOT NULL,
        FOREIGN KEY (demande_id) REFERENCES certifications_demandes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE marketplace_listings (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        proprietaire_id TEXT NOT NULL,
        proprietaire_nom TEXT,
        proprietaire_tel TEXT,
        type INTEGER NOT NULL,
        statut INTEGER DEFAULT 0,
        prix REAL NOT NULL,
        devise TEXT DEFAULT 'XOF',
        titre TEXT NOT NULL,
        description TEXT,
        photos TEXT,
        pays TEXT DEFAULT 'Burkina Faso',
        localisation TEXT,
        date_publication TEXT NOT NULL,
        date_expiration TEXT,
        vues INTEGER DEFAULT 0,
        contacts_interesses TEXT,
        FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE,
        FOREIGN KEY (proprietaire_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Helpers pour le JSON ---
  String _mapToJson(Map<String, dynamic> map) => jsonEncode(map);
  Map<String, dynamic> _jsonToMap(String? jsonStr) => jsonStr != null ? jsonDecode(jsonStr) : {};
  String _listToJson(List<dynamic> list) => jsonEncode(list);
  List<dynamic> _jsonToList(String? jsonStr) => jsonStr != null ? jsonDecode(jsonStr) : [];

  // ─── 1. AUTHENTIFICATION & UTILISATEURS ───────────────────────────────────────
  
  Future<bool> registerUser({
    required String id,
    required String telephone,
    required String email,
    required String passwordHash,
    required String nom,
    required String prenom,
    required String pays,
    required String devise,
  }) async {
    final db = await database;
    try {
      await db.insert('users', {
        'id': id,
        'telephone': telephone,
        'email': email,
        'password_hash': passwordHash,
        'nom': nom,
        'prenom': prenom,
        'pays': pays,
        'devise': devise,
        'date_creation': DateTime.now().toIso8601String(),
        'email_verifie': 0,
      });
      return true;
    } catch (e) {
      print('Erreur d\'inscription SQLite: \$e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String telephone, String passwordHash) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'telephone = ? AND password_hash = ?',
      whereArgs: [telephone, passwordHash],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      final map = maps.first;
      return UserProfile(
        id: map['id'],
        telephone: map['telephone'],
        email: map['email'] ?? '',
        nom: map['nom'] ?? '',
        prenom: map['prenom'] ?? '',
        pays: map['pays'] ?? 'Burkina Faso',
        devise: map['devise'] ?? 'XOF',
        dateCreation: DateTime.parse(map['date_creation']),
        emailVerifie: (map['email_verifie'] ?? 0) == 1,
        pinCode: map['pin_code'],
        kycStatus: KycStatus.values[map['kyc_status'] ?? 0],
        dateNaissance: map['date_naissance'] != null ? DateTime.parse(map['date_naissance']) : null,
        typePieceIdentite: map['type_piece_identite'],
        numeroPiece: map['numero_piece'],
        documentIdentiteRecto: map['document_identite_recto'],
        documentIdentiteVerso: map['document_identite_verso'],
        selfie: map['selfie'],
        fonction: map['fonction'],
        adresseResidence: map['adresse_residence'],
        nationalite: map['nationalite'],
        nomCompletPere: map['nom_complet_pere'],
        nomCompletMere: map['nom_complet_mere'],
      );
    }
    return null;
  }

  Future<void> setOtp(String userId, String otpCode) async {
    final db = await database;
    final expiry = DateTime.now().add(const Duration(minutes: 10)).toIso8601String();
    await db.update('users', {
      'otp_code': otpCode,
      'otp_expiry': expiry,
    }, where: 'id = ?', whereArgs: [userId]);
  }

  Future<bool> verifyOtp(String userId, String otpCode) async {
    final db = await database;
    final maps = await db.query('users',
        where: 'id = ? AND otp_code = ?', whereArgs: [userId, otpCode]);
    if (maps.isEmpty) return false;
    final expiry = maps.first['otp_expiry'] as String?;
    if (expiry == null) return false;
    final expiryDate = DateTime.parse(expiry);
    if (DateTime.now().isAfter(expiryDate)) return false;
    // Clear OTP after successful use
    await db.update('users', {'otp_code': null, 'otp_expiry': null},
        where: 'id = ?', whereArgs: [userId]);
    return true;
  }

  Future<void> setEmailVerifie(String userId) async {
    final db = await database;
    await db.update('users', {'email_verifie': 1},
        where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> setPin(String userId, String pinHash) async {
    final db = await database;
    await db.update('users', {'pin_code': pinHash},
        where: 'id = ?', whereArgs: [userId]);
  }

  Future<bool> verifyPin(String userId, String pinHash) async {
    final db = await database;
    final maps = await db.query('users',
        where: 'id = ? AND pin_code = ?', whereArgs: [userId, pinHash]);
    return maps.isNotEmpty;
  }

  Future<void> resetPassword(String userId, String newPasswordHash) async {
    final db = await database;
    await db.update('users', {'password_hash': newPasswordHash},
        where: 'id = ?', whereArgs: [userId]);
  }

  Future<UserProfile?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query('users',
        where: 'email = ?', whereArgs: [email]);
    if (maps.isEmpty) return null;
    final map = maps.first;
    return UserProfile(
      id: map['id'] as String,
      telephone: map['telephone'] as String,
      email: map['email'] as String? ?? '',
      nom: map['nom'] as String? ?? '',
      prenom: map['prenom'] as String? ?? '',
      pays: map['pays'] as String? ?? 'Burkina Faso',
      devise: map['devise'] as String? ?? 'XOF',
      dateCreation: DateTime.parse(map['date_creation'] as String),
      emailVerifie: (map['email_verifie'] ?? 0) == 1,
      pinCode: map['pin_code'] as String?,
      kycStatus: KycStatus.values[map['kyc_status'] as int? ?? 0],
      dateNaissance: map['date_naissance'] != null ? DateTime.parse(map['date_naissance'] as String) : null,
      typePieceIdentite: map['type_piece_identite'] as String?,
      numeroPiece: map['numero_piece'] as String?,
      documentIdentiteRecto: map['document_identite_recto'] as String?,
      documentIdentiteVerso: map['document_identite_verso'] as String?,
      selfie: map['selfie'] as String?,
      fonction: map['fonction'] as String?,
      adresseResidence: map['adresse_residence'] as String?,
      nationalite: map['nationalite'] as String?,
      nomCompletPere: map['nom_complet_pere'] as String?,
      nomCompletMere: map['nom_complet_mere'] as String?,
    );
  }

  Future<void> submitKycData(String userId, Map<String, dynamic> kycData) async {
    final db = await database;
    await db.update('users', {
      'kyc_status': kycData['kycStatus'],
      'date_naissance': kycData['dateNaissance'],
      'type_piece_identite': kycData['typePieceIdentite'],
      'numero_piece': kycData['numeroPiece'],
      'document_identite_recto': kycData['documentIdentiteRecto'],
      'document_identite_verso': kycData['documentIdentiteVerso'],
      'selfie': kycData['selfie'],
      'fonction': kycData['fonction'],
      'adresse_residence': kycData['adresseResidence'],
      'nationalite': kycData['nationalite'],
      'nom_complet_pere': kycData['nomCompletPere'],
      'nom_complet_mere': kycData['nomCompletMere'],
    }, where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> updateProfile(String userId, {required String nom, required String prenom, required String pays, required String devise}) async {
    final db = await database;
    await db.update('users', {'nom': nom, 'prenom': prenom, 'pays': pays, 'devise': devise},
        where: 'id = ?', whereArgs: [userId]);
  }

  // ─── 2. ACTIFS (BASE) ───────────────────────────────────────────────────────

  Future<void> createAsset(Asset asset, String userId) async {
    final db = await database;
    await db.insert('assets', {
      'id': asset.id,
      'user_id': userId,
      'asset_type_id': asset.type.index,
      'nom': asset.nom,
      'statut': asset.statut.index,
      'valeur_actuelle': asset.valeurActuelle,
      'valeur_initiale': asset.valeurInitiale,
      'description': asset.description,
      'devise': asset.devise,
      'pays': asset.pays,
      'date_acquisition': asset.dateAcquisition.toIso8601String(),
      'date_derniere_evaluation': asset.dateDerniereEvaluation?.toIso8601String(),
      'est_loue': asset.estLoue ? 1 : 0,
      'loyer_mensuel': asset.loyerMensuel,
      'periodicite_loyer': asset.periodiciteLoyer.index,
      'locataire': asset.locataire,
      'date_fin_bail': asset.dateFinBail?.toIso8601String(),
      'certification_status': asset.certificationStatus.index,
      'certification_id': asset.certificationId,
      'date_certification': asset.dateCertification?.toIso8601String(),
      'certification_autorite_nom': asset.certificationAutoriteNom,
      'en_vente': asset.enVente ? 1 : 0,
      'en_location': asset.enLocation ? 1 : 0,
      'prix_vente': asset.prixVente,
      'prix_location': asset.prixLocation,
      'listing_id': asset.listingId,
      'details': _mapToJson(asset.details),
      'photos': _listToJson(asset.photos),
    });
  }

  Future<void> addAssetDocuments(String assetId, Map<String, String> documents) async {
    final db = await database;
    for (final doc in documents.entries) {
      await db.insert('asset_documents', {
        'id': DateTime.now().millisecondsSinceEpoch.toString() + '_' + doc.key,
        'asset_id': assetId,
        'nom_document': doc.key,
        'file_path': doc.value,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getAssetDocuments(String assetId) async {
    final db = await database;
    return await db.query('asset_documents', where: 'asset_id = ?', whereArgs: [assetId]);
  }

  Future<bool> checkAssetUniqueness(AssetType type, Map<String, dynamic> details) async {
    final db = await database;
    final allAssets = await db.query('assets', where: 'asset_type_id = ?', whereArgs: [type.index]);

    for (var a in allAssets) {
      final existingDetails = _jsonToMap(a['details'] as String?);
      
      switch (type) {
        case AssetType.immobilier:
          if (details['gps'] != null && details['gps'] == existingDetails['gps']) return false;
          break;
        case AssetType.vehicule:
          if (details['chassis'] != null && details['chassis'] == existingDetails['chassis']) return false;
          if (details['immatriculation'] != null && details['immatriculation'] == existingDetails['immatriculation']) return false;
          break;
        case AssetType.compteBancaire:
          if (details['iban'] != null && details['iban'] == existingDetails['iban']) return false;
          break;
        case AssetType.investissement:
          if (details['siret'] != null && details['siret'] == existingDetails['siret']) return false;
          break;
        case AssetType.creance:
        case AssetType.dette:
          if (details['reference_contrat'] != null && details['reference_contrat'] == existingDetails['reference_contrat']) return false;
          break;
        default: break;
      }
    }
    return true; // Unique
  }

  Future<List<Asset>> getAssetsByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assets',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return Asset(
        id: map['id'],
        nom: map['nom'],
        type: AssetType.values[map['asset_type_id']],
        statut: AssetStatus.values[map['statut'] ?? 0],
        valeurActuelle: map['valeur_actuelle'],
        valeurInitiale: map['valeur_initiale'],
        description: map['description'] ?? '',
        devise: map['devise'] ?? 'XOF',
        pays: map['pays'] ?? 'Burkina Faso',
        dateAcquisition: DateTime.parse(map['date_acquisition']),
        dateDerniereEvaluation: map['date_derniere_evaluation'] != null ? DateTime.parse(map['date_derniere_evaluation']) : null,
        estLoue: (map['est_loue'] == 1),
        loyerMensuel: map['loyer_mensuel'],
        periodiciteLoyer: PeriodiciteLoyer.values[map['periodicite_loyer'] ?? 0],
        locataire: map['locataire'],
        dateFinBail: map['date_fin_bail'] != null ? DateTime.parse(map['date_fin_bail']) : null,
        certificationStatus: CertificationStatus.values[map['certification_status'] ?? 0],
        certificationId: map['certification_id'],
        dateCertification: map['date_certification'] != null ? DateTime.parse(map['date_certification']) : null,
        certificationAutoriteNom: map['certification_autorite_nom'],
        enVente: (map['en_vente'] == 1),
        enLocation: (map['en_location'] == 1),
        prixVente: map['prix_vente'],
        prixLocation: map['prix_location'],
        listingId: map['listing_id'],
        details: _jsonToMap(map['details'] as String?),
        photos: List<String>.from(_jsonToList(map['photos'] as String?)),
      );
    });
  }

  Future<void> updateAsset(Asset asset) async {
    final db = await database;
    await db.update(
      'assets',
      {
        'nom': asset.nom,
        'statut': asset.statut.index,
        'valeur_actuelle': asset.valeurActuelle,
        'description': asset.description,
        'date_derniere_evaluation': asset.dateDerniereEvaluation?.toIso8601String(),
        'est_loue': asset.estLoue ? 1 : 0,
        'loyer_mensuel': asset.loyerMensuel,
        'periodicite_loyer': asset.periodiciteLoyer.index,
        'locataire': asset.locataire,
        'date_fin_bail': asset.dateFinBail?.toIso8601String(),
        'certification_status': asset.certificationStatus.index,
        'en_vente': asset.enVente ? 1 : 0,
        'en_location': asset.enLocation ? 1 : 0,
        'prix_vente': asset.prixVente,
        'prix_location': asset.prixLocation,
        'details': _mapToJson(asset.details),
        'photos': _listToJson(asset.photos),
      },
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  Future<void> deleteAsset(String id) async {
    // A implémenter si on passe au SQL complet pour cet appel
  }

  // ─── 3. ACTIONS SUR LES ACTIFS ──────────────────────────────────────────────

  Future<void> reevaluerActif(String assetId, double nouvelleValeur, String notes) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'assets',
        {
          'valeur_actuelle': nouvelleValeur,
          'date_derniere_evaluation': DateTime.now().toIso8601String()
        },
        where: 'id = ?',
        whereArgs: [assetId],
      );
      
      await txn.insert('transactions', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'asset_id': assetId,
        'type_transaction': 'réévaluation',
        'montant': nouvelleValeur,
        'date': DateTime.now().toIso8601String()
      });
    });
  }

  Future<List<String>> getRequiredDocuments(AssetType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_type_documents',
      where: 'asset_type_id = ? AND est_obligatoire = 1',
      whereArgs: [type.index],
    );
    return maps.map((m) => m['nom_document'] as String).toList();
  }

  Future<void> demanderCertification(CertificationDemande demande, List<Map<String, String>> documents) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('certifications_demandes', {
        'id': demande.id,
        'asset_id': demande.assetId,
        'asset_nom': demande.assetNom,
        'asset_type_id': demande.assetType.index,
        'statut': demande.statut.index,
        'autorite_type': demande.autoriteType,
        'autorite_nom': demande.autoriteNom,
        'autorite_contact': demande.autoriteContact,
        'frais': demande.frais,
        'devise': demande.devise,
        'date_demande': demande.dateDemande.toIso8601String(),
        'date_traitement': demande.dateTraitement?.toIso8601String(),
        'notes': demande.notes,
        'refus': demande.refus,
        'paiement_effectue': demande.paiementEffectue ? 1 : 0,
        'part_autorite': demande.partAutorite,
        'part_plateforme': demande.partPlateforme,
      });

      for (var doc in documents) {
        await txn.insert('certification_documents', {
          'id': DateTime.now().microsecondsSinceEpoch.toString() + '_' + (doc['nomDocument']?.hashCode.toString() ?? ''),
          'demande_id': demande.id,
          'nom_document': doc['nomDocument'] ?? '',
          'file_path': doc['filePath'] ?? '',
        });
      }

      await txn.update(
        'assets',
        {'certification_status': demande.statut.index},
        where: 'id = ?',
        whereArgs: [demande.assetId],
      );
    });
  }

  Future<void> mettreEnLocation(MarketplaceListing listing) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('marketplace_listings', {
        'id': listing.id,
        'asset_id': listing.assetId,
        'proprietaire_id': listing.proprietaireId,
        'proprietaire_nom': listing.proprietaireNom,
        'proprietaire_tel': listing.proprietaireTel,
        'type': listing.type.index,
        'statut': listing.statut.index,
        'prix': listing.prix,
        'devise': listing.devise,
        'titre': listing.titre,
        'description': listing.description,
        'photos': _listToJson(listing.photos),
        'pays': listing.pays,
        'localisation': listing.localisation,
        'date_publication': listing.datePublication.toIso8601String(),
        'date_expiration': listing.dateExpiration?.toIso8601String(),
        'vues': listing.vues,
        'contacts_interesses': _listToJson(listing.contactsInteresses),
      });

      await txn.update(
        'assets',
        {
          'en_location': 1,
          'prix_location': listing.prix,
          'listing_id': listing.id,
        },
        where: 'id = ?',
        whereArgs: [listing.assetId],
      );
    });
  }

  Future<void> declarerLoyer(Loyer loyer) async {
    final db = await database;
    await db.insert('loyers', {
      'id': loyer.id,
      'asset_id': loyer.assetId,
      'montant': loyer.montant,
      'devise': loyer.devise,
      'date_paiement': DateTime.now().toIso8601String(),
      'est_paye': loyer.estPaye ? 1 : 0,
      'notes': loyer.notes,
      'mois': loyer.mois,
      'annee': loyer.annee,
    });
  }

  // ─── 4. CRÉANCES ET DETTES ──────────────────────────────────────────────────

  Future<void> creerCreance(Creance creance, String userId) async {
    final db = await database;
    await db.insert('creances', {
      'id': creance.id,
      'user_id': userId,
      'debiteur_nom': creance.debiteurNom,
      'debiteur_contact': creance.debiteurContact,
      'montant': creance.montant,
      'montant_rembourse': creance.montantRembourse,
      'devise': creance.devise,
      'description': creance.description,
      'date_creance': creance.dateCreance.toIso8601String(),
      'date_echeance': creance.dateEcheance?.toIso8601String(),
      'est_rembourse': creance.estRembourse ? 1 : 0,
      'taux_interet': creance.tauxInteret,
    });
  }

  Future<void> encaisserCreance(String creanceId, double montant, String notes) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('remboursements_creances', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'creance_id': creanceId,
        'montant': montant,
        'date': DateTime.now().toIso8601String(),
        'notes': notes,
      });

      await txn.rawUpdate(
        'UPDATE creances SET montant_rembourse = montant_rembourse + ?, est_rembourse = CASE WHEN montant_rembourse + ? >= montant THEN 1 ELSE 0 END WHERE id = ?',
        [montant, montant, creanceId]
      );
    });
  }

  Future<void> creerDette(Dette dette, String userId) async {
    final db = await database;
    await db.insert('dettes', {
      'id': dette.id,
      'user_id': userId,
      'creancier_nom': dette.creancierNom,
      'creancier_contact': dette.creancierContact,
      'montant': dette.montant,
      'montant_rembourse': dette.montantRembourse,
      'devise': dette.devise,
      'description': dette.description,
      'date_dette': dette.dateDette.toIso8601String(),
      'date_echeance': dette.dateEcheance?.toIso8601String(),
      'est_rembourse': dette.estRembourse ? 1 : 0,
      'taux_interet': dette.tauxInteret,
    });
  }

  Future<void> rembourserDette(String detteId, double montant, String notes) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('remboursements_dettes', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'dette_id': detteId,
        'montant': montant,
        'date': DateTime.now().toIso8601String(),
        'notes': notes,
      });

      await txn.rawUpdate(
        'UPDATE dettes SET montant_rembourse = montant_rembourse + ?, est_rembourse = CASE WHEN montant_rembourse + ? >= montant THEN 1 ELSE 0 END WHERE id = ?',
        [montant, montant, detteId]
      );
    });
  }

  // ─── 5. TESTAMENTS ET SUCCESSION ────────────────────────────────────────────

  Future<void> creerTestament(Testament testament) async {
    final db = await database;
    await db.insert('testaments', {
      'id': testament.id,
      'user_id': testament.userId,
      'statut': testament.statut.index,
      'notes': testament.notes,
      'date_creation': testament.dateCreation.toIso8601String(),
      'date_modification': testament.dateModification?.toIso8601String(),
      'date_certification': testament.dateCertification?.toIso8601String(),
      'notaire_nom': testament.notaireNom,
      'notaire_contact': testament.notaireContact,
      'certification_ref': testament.certificationRef,
      'paiement_certif_effectue': testament.paiementCertifEffectue ? 1 : 0,
    });
  }

  Future<void> ajouterAyantDroit(AyantDroit ayantDroit, String userId) async {
    final db = await database;
    await db.insert('ayants_droits', {
      'id': ayantDroit.id,
      'user_id': userId,
      'nom': ayantDroit.nom,
      'prenom': ayantDroit.prenom,
      'type': ayantDroit.type.index,
      'lien_parente': ayantDroit.lienParente,
      'contact': ayantDroit.contact,
      'nationalite': ayantDroit.nationalite,
      'numero_piece_identite': ayantDroit.numeroPieceIdentite,
      'date_naissance': ayantDroit.dateNaissance?.toIso8601String(),
      'notes': ayantDroit.notes,
    });
  }

  Future<void> repartirBien(RepartitionBien repartition) async {
    final db = await database;
    await db.insert('repartitions_biens', {
      'id': repartition.id,
      'testament_id': repartition.testamentId,
      'asset_id': repartition.assetId,
      'ayant_droit_id': repartition.ayantDroitId,
      'pourcentage': repartition.pourcentage,
      'conditions': repartition.conditions,
      'notes': repartition.notes,
    });
  }
}
