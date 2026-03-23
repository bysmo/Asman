<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Asset extends Model
{
    use HasFactory, SoftDeletes;

    // Types d'actifs
    const TYPE_IMMOBILIER     = 'immobilier';
    const TYPE_VEHICULE       = 'vehicule';
    const TYPE_INVESTISSEMENT = 'investissement';
    const TYPE_CREANCE        = 'creance';
    const TYPE_DETTE          = 'dette';
    const TYPE_COMPTE_BANCAIRE= 'compte_bancaire';
    const TYPE_AUTRE          = 'autre';

    // Statuts
    const STATUS_ACTIF    = 'actif';
    const STATUS_LOUE     = 'loue';
    const STATUS_VENDU    = 'vendu';
    const STATUS_INACTIF  = 'inactif';

    // Certification
    const CERT_NON_DEMANDE = 'non_demande';
    const CERT_EN_ATTENTE  = 'en_attente';
    const CERT_EN_COURS    = 'en_cours';
    const CERT_CERTIFIE    = 'certifie';
    const CERT_REFUSE      = 'refuse';

    protected $fillable = [
        'user_id', 'nom', 'type', 'statut', 'description',
        'valeur_actuelle', 'valeur_initiale', 'devise', 'pays',
        'date_acquisition', 'date_derniere_evaluation',
        'certification_status', 'certification_id', 'date_certification',
        'certification_autorite_nom',
        'est_loue', 'loyer_mensuel', 'locataire', 'date_fin_bail',
        'en_vente', 'en_location', 'prix_vente', 'prix_location',
        'details', 'photos',
        // Immobilier spécifique
        'adresse', 'ville', 'commune', 'village', 'province', 'region',
        'superficie', 'superficie_unite', 'numero_lot', 'section_cadastrale',
        'coordonnees_gps', 'titre_foncier', 'reference_cadastrale',
        'type_propriete', // villa, appartement, terrain, immeuble, bureau, entrepôt...
        // Véhicule
        'marque', 'modele', 'annee_fabrication', 'numero_chassis',
        'numero_immatriculation', 'couleur', 'carburant', 'kilometrage',
        // Investissement
        'nom_societe', 'type_investissement', 'nombre_parts', 'valeur_part',
        'courtier', 'numero_compte_titre', 'isin',
    ];

    protected $casts = [
        'date_acquisition'          => 'date',
        'date_derniere_evaluation'  => 'date',
        'date_certification'        => 'date',
        'date_fin_bail'             => 'date',
        'valeur_actuelle'           => 'decimal:2',
        'valeur_initiale'           => 'decimal:2',
        'loyer_mensuel'             => 'decimal:2',
        'prix_vente'                => 'decimal:2',
        'prix_location'             => 'decimal:2',
        'valeur_part'               => 'decimal:2',
        'est_loue'                  => 'boolean',
        'en_vente'                  => 'boolean',
        'en_location'               => 'boolean',
        'details'                   => 'array',
        'photos'                    => 'array',
        'coordonnees_gps'           => 'array',
    ];

    // ─── Relations ────────────────────────────────────────────────────────────

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function certifications()
    {
        return $this->hasMany(Certification::class);
    }

    public function certificationActive()
    {
        return $this->hasOne(Certification::class)->latestOfMany();
    }

    public function loyers()
    {
        return $this->hasMany(Loyer::class);
    }

    public function marketplaceListings()
    {
        return $this->hasMany(MarketplaceListing::class);
    }

    public function evaluations()
    {
        return $this->hasMany(Evaluation::class);
    }

    public function repartitionsTestament()
    {
        return $this->hasMany(RepartitionBien::class);
    }

    // ─── Accesseurs ───────────────────────────────────────────────────────────

    public function getPlusValueAttribute(): float
    {
        return $this->valeur_actuelle - $this->valeur_initiale;
    }

    public function getPlusValuePctAttribute(): float
    {
        if ($this->valeur_initiale <= 0) return 0;
        return (($this->valeur_actuelle - $this->valeur_initiale) / $this->valeur_initiale) * 100;
    }

    public function getEstCertifieAttribute(): bool
    {
        return $this->certification_status === self::CERT_CERTIFIE;
    }

    // ─── Scopes ───────────────────────────────────────────────────────────────

    public function scopeCertifies($query)
    {
        return $query->where('certification_status', self::CERT_CERTIFIE);
    }

    public function scopeEnVente($query)
    {
        return $query->where('en_vente', true);
    }

    public function scopeLoues($query)
    {
        return $query->where('est_loue', true);
    }
}
