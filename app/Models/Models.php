<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CompteBancaire extends Model
{
    use HasFactory;

    const TYPE_COURANT      = 'courant';
    const TYPE_EPARGNE      = 'epargne';
    const TYPE_DAT          = 'dat';
    const TYPE_TITRE        = 'compte_titre';
    const TYPE_CRYPTO       = 'crypto';
    const TYPE_PROFESSIONNEL= 'professionnel';

    protected $fillable = [
        'user_id', 'nom_banque', 'numero_compte', 'type_compte',
        'solde', 'devise', 'pays', 'iban', 'swift_bic',
        'description', 'date_ouverture', 'est_actif',
        'taux_interet', 'date_echeance_dat',
        'agence', 'conseiller', 'contact_banque',
    ];

    protected $casts = [
        'solde'              => 'decimal:2',
        'taux_interet'       => 'decimal:4',
        'date_ouverture'     => 'date',
        'date_echeance_dat'  => 'date',
        'est_actif'          => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

// ─── CRÉANCE ─────────────────────────────────────────────────────────────────

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Creance extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'debiteur_nom', 'debiteur_contact', 'debiteur_pays',
        'montant', 'montant_rembourse', 'devise',
        'description', 'date_creance', 'date_echeance',
        'est_rembourse', 'taux_interet', 'garantie',
        'document_path', 'notes',
    ];

    protected $casts = [
        'montant'           => 'decimal:2',
        'montant_rembourse' => 'decimal:2',
        'taux_interet'      => 'decimal:4',
        'date_creance'      => 'date',
        'date_echeance'     => 'date',
        'est_rembourse'     => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function remboursements()
    {
        return $this->hasMany(Remboursement::class, 'source_id')
                    ->where('source_type', 'creance');
    }

    public function getMontantRestantAttribute(): float
    {
        return max(0, $this->montant - $this->montant_rembourse);
    }

    public function getEstEnRetardAttribute(): bool
    {
        return $this->date_echeance && now()->isAfter($this->date_echeance) && !$this->est_rembourse;
    }
}

// ─── DETTE ───────────────────────────────────────────────────────────────────

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Dette extends Model
{
    use HasFactory;

    const TYPE_CREDIT_IMMO   = 'credit_immobilier';
    const TYPE_CREDIT_CONSO  = 'credit_consommation';
    const TYPE_CREDIT_AUTO   = 'credit_auto';
    const TYPE_PRET_PERSO    = 'pret_personnel';
    const TYPE_DECOUVERT     = 'decouvert';
    const TYPE_AUTRE         = 'autre';

    protected $fillable = [
        'user_id', 'creancier_nom', 'creancier_contact', 'type_dette',
        'montant', 'montant_rembourse', 'devise',
        'description', 'date_dette', 'date_echeance',
        'est_rembourse', 'taux_interet', 'mensualite',
        'nombre_echeances', 'echeances_restantes',
        'garantie', 'bien_hypotheque_id', 'document_path',
    ];

    protected $casts = [
        'montant'             => 'decimal:2',
        'montant_rembourse'   => 'decimal:2',
        'taux_interet'        => 'decimal:4',
        'mensualite'          => 'decimal:2',
        'date_dette'          => 'date',
        'date_echeance'       => 'date',
        'est_rembourse'       => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function bienHypotheque()
    {
        return $this->belongsTo(Asset::class, 'bien_hypotheque_id');
    }

    public function remboursements()
    {
        return $this->hasMany(Remboursement::class, 'source_id')
                    ->where('source_type', 'dette');
    }

    public function getMontantRestantAttribute(): float
    {
        return max(0, $this->montant - $this->montant_rembourse);
    }
}

// ─── REMBOURSEMENT ────────────────────────────────────────────────────────────

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Remboursement extends Model
{
    protected $fillable = [
        'source_id', 'source_type', 'user_id',
        'montant', 'devise', 'date_paiement', 'notes', 'reference',
    ];

    protected $casts = [
        'montant'        => 'decimal:2',
        'date_paiement'  => 'date',
    ];
}

// ─── LOYER ────────────────────────────────────────────────────────────────────

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Loyer extends Model
{
    protected $fillable = [
        'asset_id', 'user_id', 'montant', 'devise',
        'date_paiement', 'est_paye', 'mois', 'annee', 'notes',
        'mode_paiement', 'reference_paiement',
    ];

    protected $casts = [
        'montant'       => 'decimal:2',
        'date_paiement' => 'date',
        'est_paye'      => 'boolean',
    ];

    public function asset()
    {
        return $this->belongsTo(Asset::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

// ─── ÉVALUATION ───────────────────────────────────────────────────────────────

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Evaluation extends Model
{
    protected $fillable = [
        'asset_id', 'user_id', 'evaluateur_id',
        'valeur_precedente', 'valeur_nouvelle', 'devise',
        'methode_evaluation', 'notes', 'date_evaluation',
        'source', // auto, manuel, expert, marche
    ];

    protected $casts = [
        'valeur_precedente' => 'decimal:2',
        'valeur_nouvelle'   => 'decimal:2',
        'date_evaluation'   => 'date',
    ];

    public function asset()
    {
        return $this->belongsTo(Asset::class);
    }

    public function getPlusValueAttribute(): float
    {
        return $this->valeur_nouvelle - $this->valeur_precedente;
    }
}

// ─── MARKETPLACE LISTING ──────────────────────────────────────────────────────

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MarketplaceListing extends Model
{
    const TYPE_VENTE    = 'vente';
    const TYPE_LOCATION = 'location';
    const STATUS_ACTIF  = 'actif';
    const STATUS_SUSPENDU = 'suspendu';
    const STATUS_CLOTURE  = 'cloture';
    const STATUS_VENDU    = 'vendu';

    protected $fillable = [
        'asset_id', 'user_id', 'type', 'statut',
        'prix', 'devise', 'titre', 'description',
        'photos', 'pays', 'localisation',
        'date_publication', 'date_expiration',
        'vues', 'contacts_interesses', 'conditions',
    ];

    protected $casts = [
        'prix'                  => 'decimal:2',
        'date_publication'      => 'datetime',
        'date_expiration'       => 'datetime',
        'photos'                => 'array',
        'contacts_interesses'   => 'array',
    ];

    public function asset()
    {
        return $this->belongsTo(Asset::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

// ─── PAIEMENT ─────────────────────────────────────────────────────────────────

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Paiement extends Model
{
    const STATUS_EN_ATTENTE = 'en_attente';
    const STATUS_VALIDE     = 'valide';
    const STATUS_ECHOUE     = 'echoue';
    const STATUS_REMBOURSE  = 'rembourse';

    const TYPE_CERTIFICATION = 'certification';
    const TYPE_TESTAMENT     = 'testament';
    const TYPE_ABONNEMENT    = 'abonnement';
    const TYPE_AUTRE         = 'autre';

    protected $fillable = [
        'user_id', 'certification_id', 'type', 'statut',
        'montant', 'devise', 'reference', 'methode',
        'montant_autorite', 'montant_plateforme',
        'autorite_id', 'autorite_paye_le',
        'plateforme_paye_le', 'notes',
        'gateway_response',
    ];

    protected $casts = [
        'montant'            => 'decimal:2',
        'montant_autorite'   => 'decimal:2',
        'montant_plateforme' => 'decimal:2',
        'autorite_paye_le'   => 'datetime',
        'plateforme_paye_le' => 'datetime',
        'gateway_response'   => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function certification()
    {
        return $this->belongsTo(Certification::class);
    }

    public function autorite()
    {
        return $this->belongsTo(User::class, 'autorite_id');
    }
}

// ─── KYC DOCUMENT ────────────────────────────────────────────────────────────

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class KycDocument extends Model
{
    const STATUS_PENDING   = 'pending';
    const STATUS_VERIFIED  = 'verified';
    const STATUS_REJECTED  = 'rejected';

    protected $fillable = [
        'user_id', 'statut',
        'piece_type', 'piece_numero', 'piece_front_path', 'piece_back_path',
        'selfie_path', 'video_liveness_path',
        'date_expiration_piece', 'pays_emission',
        'verified_by', 'verified_at', 'rejection_reason',
        'score_liveness', 'metadata',
    ];

    protected $casts = [
        'date_expiration_piece' => 'date',
        'verified_at'           => 'datetime',
        'score_liveness'        => 'decimal:2',
        'metadata'              => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function verifiedBy()
    {
        return $this->belongsTo(User::class, 'verified_by');
    }
}

// ─── LIQUIDATION ─────────────────────────────────────────────────────────────

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Liquidation extends Model
{
    const TYPE_MANUELLE    = 'manuelle';
    const TYPE_AUTOMATIQUE = 'automatique';
    const STATUS_EN_COURS  = 'en_cours';
    const STATUS_COMPLETE  = 'complete';
    const STATUS_ANNULEE   = 'annulee';

    protected $fillable = [
        'user_id', 'declencheur_id', 'asset_id',
        'type', 'statut', 'motif',
        'valeur_totale', 'devise',
        'date_declenchement', 'date_completion',
        'repartitions_executees', 'documents', 'notes',
    ];

    protected $casts = [
        'valeur_totale'             => 'decimal:2',
        'date_declenchement'        => 'datetime',
        'date_completion'           => 'datetime',
        'repartitions_executees'    => 'array',
        'documents'                 => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function declencheur()
    {
        return $this->belongsTo(User::class, 'declencheur_id');
    }

    public function asset()
    {
        return $this->belongsTo(Asset::class);
    }
}
