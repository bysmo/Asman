# Asman Admin - Backend Laravel

Backend de gestion de patrimoine pour l'application mobile Asman.

## Stack Technique

- **Framework** : Laravel 10+
- **Auth** : Laravel Sanctum (API tokens)
- **BDD** : MySQL / PostgreSQL
- **Admin UI** : Bootstrap 5

## Rôles utilisateurs

| Rôle | Accès |
|------|-------|
| `admin` | Accès complet (dashboard, users, certifications, liquidations, revenus) |
| `notaire` | Certifications, testaments assignés |
| `huissier` | Certifications assignées |
| `avocat` | Certifications assignées |
| `client` | API mobile uniquement |

## Installation

```bash
git clone https://github.com/bysmo/asman_admin.git
cd asman_admin
cp .env.example .env
# Configurer la base de données dans .env
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve
```

## Comptes de test (après seeding)

| Rôle | Email | Mot de passe |
|------|-------|-------------|
| Admin | admin@asman.bf | Asman@2024! |
| Notaire | notaire@asman.bf | Notaire@2024! |
| Huissier | huissier@asman.bf | Huissier@2024! |
| Avocat | avocat@asman.bf | Avocat@2024! |
| Client | client@asman.bf | Client@2024! |

## API Endpoints

### Auth
```
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout (auth required)
GET  /api/v1/auth/me    (auth required)
```

### Assets
```
GET    /api/v1/assets
POST   /api/v1/assets
GET    /api/v1/assets/{id}
PUT    /api/v1/assets/{id}
DELETE /api/v1/assets/{id}
GET    /api/v1/assets/stats/summary
```

### Certifications
```
GET  /api/v1/certifications
POST /api/v1/certifications
GET  /api/v1/certifications/{id}
POST /api/v1/certifications/{id}/soumettre
POST /api/v1/certifications/{id}/approuver
POST /api/v1/certifications/{id}/rejeter
```

### Testaments
```
GET    /api/v1/testaments
POST   /api/v1/testaments
GET    /api/v1/testaments/{id}
PUT    /api/v1/testaments/{id}
DELETE /api/v1/testaments/{id}
POST   /api/v1/testaments/{id}/finaliser
POST   /api/v1/testaments/{id}/certifier
```

### Finances
```
GET /api/v1/comptes
POST /api/v1/comptes
GET /api/v1/creances
POST /api/v1/creances
GET /api/v1/dettes
POST /api/v1/dettes
GET /api/v1/loyers
POST /api/v1/loyers
```

### Marketplace
```
GET  /api/v1/marketplace
POST /api/v1/marketplace
GET  /api/v1/marketplace/{id}
```

## Modèle économique

Les frais de certification sont partagés :
- **70%** → Autorité (notaire/huissier/avocat)
- **30%** → Asman (plateforme)

## Structure du projet

```
app/
  Http/
    Controllers/
      API/V1/      # Controllers API mobile
      Admin/       # Controllers interface web admin
    Middleware/
      CheckRole.php
  Models/          # Eloquent models
database/
  migrations/      # Structure BDD
  seeders/         # Données initiales
resources/
  views/
    layouts/       # Layout admin Bootstrap
    admin/         # Vues interface admin
routes/
  api.php          # Routes API REST
  web.php          # Routes interface admin
```
