# 🌟 Asman - La Plateforme Nouvelle Génération de Gestion de Patrimoine

![Asman Banner](https://via.placeholder.com/1200x400.png?text=Asman+-+Gestion+de+Patrimoine+Premium)

Bienvenue sur **Asman**, la solution ultime de gestion, d'évaluation, de certification et de transmission de patrimoine. Conçue pour offrir une expérience premium (interface *Dark Navy & Gold*), Asman s'adresse aux particuliers et professionnels souhaitant numériser, sécuriser et valoriser l'ensemble de leurs biens.

---

## 🚀 Présentation aux Clients (Fonctionnalités Clés)

Asman centralise l'intégralité de vos actifs dans un coffre-fort numérique hautement sécurisé. 

### 1. 📂 Gestion Multi-Actifs Complète
Gérez un portefeuille diversifié avec des champs spécifiques structurés à chaque catégorie :
- 🏢 **Immobilier** (Superficie, point GPS, dessin topographique complet (polygone) d'un terrain)
- 🚗 **Véhicules** (Marque, Immatriculation, Châssis, Puissance)
- 📈 **Investissements & Comptes Bancaires** (Parts sociales, IBAN, relevés d'identités bancaires)
- ⚖️ **Créances et Dettes** (Débiteurs, Créanciers, Témoins, Échéances)
- 💎 **Objets de Luxe** (Marque de luxe, Matière, Époque/Année)
- 🐄 **Cheptel Animal** (Catégorie, Nombres de têtes)
- 🎬 **Droits d'Auteur, Marques et Brevets** (Numéros de dépôts institutionnels internationaux)

### 2. 🛡️ Certification par les Autorités Habilitées
Luttez contre la fraude et les doublons ! Asman connecte les propriétaires aux autorités compétentes (Notaires, Huissiers, Tribunaux, Cadastre) :
- Soumettez vos titres de propriété ou documents à la vérification formelle.
- Modèle économique de répartition des frais : le coût de la certification est découpé avec partage de revenus fluide (70% pour l'autorité réalisant le contrôle / 30% Asman).
- Seuls les actifs "Certifiés" reçoivent le **Badge Vert**, pré-requis absolu pour la location, vente ou le transfert du bien sur la plateforme.

### 3. 🛍️ Marketplace : Vente et Location
Mettez en valeur votre patrimoine sur notre marché décentralisé sécurisé :
- Publiez des annonces de **Vente** ou de **Location** pour vos biens dûment certifiés.
- Tableau de bord intégré pour suivre la rentabilité locative.
- **Gestion des loyers :** Pointez les loyers payés/impayés, tirez un bilan périodique et gérez sereinement les fins de baux de vos locataires.

### 4. 📜 Transmission et Testaments
Déléguez et préparez l'avenir sereinement :
- Définissez vos héritiers (proportions en %).
- Assignez des biens spécifiques à des héritiers particuliers en réduisant la complexité des successions.
- Verrouillez votre testament avec un code PIN strict et mandatez un **Exécuteur Testamentaire** (ex: votre notaire de famille) habilité à déclarer un décès et déclencher la distribution virtuelle des lots.

### 5. 🔒 Sécurité : Standard KYC institutionnel et Code PIN
- Appareillage complet **KYC (Know Your Customer)** intégré, collectant selfies, pièces d'identité recto/verso, informations strictes pour valider l'existence juridique et physique de l'utilisateur. Seul un profil validé "Actif" bénéficie des droits d'action monétaires.
- Blindage des montants de solde et verrouillage des actions critiques au moyen d'un **Code PIN personnalisé**.

---

## 💻 Partie Technique (Pour les Développeurs / GitHub)

L'architecture applicative **Asman** est pensée pour la maintenabilité, la fluidité UI/UX (60fps) et reposant sur un modèle de sécurité "offline-first/online-sync".

### 🛠️ Stack Technique
- **Framework Front-end :** [Flutter](https://flutter.dev/) (Dart) déployable sur iOS, Android et potentiellement Web.
- **Gestion des États :** `Provider` (Assure une séparation nette entre l'Event Loop UI et la logique métier de l'application).
- **Base de Données Locale :** `sqflite`. (Soutient un modèle relationnel complexe pour assurer le fonctionnement local transparent — Actifs ↔ Documents ↔ Utilisateurs ↔ Loyers). Idéal pour la mise en place d'une synchronisation bidirectionnelle Backend ultérieure.
- **Médias :** `image_picker`, `file_picker` pour acquérir les justificatifs légaux et données médias (KYC, authenticités d'assets).

### 📁 Structure du Code Source (Aperçu)

```text
lib/
├── models/         # Entités métiers (Asset, UserProfile, KycStatus, Testament, CertificationDemande)
├── providers/      # Accesseurs State Management (AssetProvider, AuthProvider)
├── screens/        # Vues UI divisées par logiques (Home, Marketplace, Loyers, KYCScreen, AddAsset...)
├── services/       # Couche Services (DatabaseService, schémas de données SQL et seeders)
├── theme/          # Injection de UI exhaustive (AppTheme - Dark Navy, Gold Elements, typographie premium)
└── utils/          # Helpers (AppUtils pour le formatage devise monétaire, associations d'icônes par enum)
```

### ⚙️ Composants Techniques Clés
- `database_service.dart` : Cœur de la persistance locale orchestrant les tables SQL `users`, `assets`, `asset_documents`, `loyers` et `testaments`. Comprend la logique de construction et les requêtes complexes pour analyser les "Revenus des Autorités".
- **KYC & PIN Middleware Layers** : Systèmes d'exceptions et de gardes réactifs interdisant implicitement un parcours utilisateur inachevé d'actionner une mutation dans le patrimoine.
- **Topographie Géographique** : Parseur de sérialisation JSON pour un nombre infini de coordonnées topographiques (`Lat`, `Lng`) attachées à l'Actif (`details['coordonneesTopographiques']`), afin de modéliser facilement les points avec les écosystèmes *MapBox* ou *Google Maps*.

### 🚀 Instructions de lancement (Local Dev)

1. Assurez-vous que l'environnement [Flutter](https://flutter.dev/docs/get-started/install) soit initialisé et dans sa dernière version "Stable" (version `>= 3.19.x` hautement conseillée).
2. Cloner le projet :
   ```bash
   git clone <REPOSITORY_URL>
   cd Asman
   ```
3. Télécharger les dépendances externes :
   ```bash
   flutter pub get
   ```
4. Lancer le linter pour assurer l'intégrité avant le build :
   ```bash
   flutter analyze
   ```
5. Compiler vers l'émulateur/appareil ciblé :
   ```bash
   flutter run
   ```

### 🔮 Étapes Architectes pour l'Avenir
- Apparier en dur la structure structurée GPS aux widgets visuels interactifs `google_maps_flutter` afin de tracer les dessins fonciers vectoriels in-app.
- Substituer/Étendre la connectivité `sqflite` vers une passerelle Backend distante (API REST Node.js ou Firebase Cloud Firestore) propulsant de ce fait la Marketplace des actifs vers la version Multijoueurs Client/Serveur.
- Raccorder la validation KYC intégrée à un service d'intégration tierce IA (Sumsub, Onfido) dans le pipeline du Cloud pour une acceptation KYC asynchrone sans personnel humain permanent.

---
*Conçu et développé pour révolutionner de manière technologique la gestion formelle et empirique du patrimoine de nouvelle ère.*
