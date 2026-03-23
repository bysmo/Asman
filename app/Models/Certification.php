<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Certification extends Model
{
    use HasFactory, SoftDeletes;

    const STATUS_EN_ATTENTE = 'en_attente';
    const STATUS_EN_COURS   = 'en_cours';
    const STATUS_CERTIFIE   = 'certifie';
    const STATUS_REFUSE     = 'refuse';
    const STATUS_ANNULE     = 'annule';

    const AUTORITE_NOTAIRE   = 'notaire';
    const AUTORITE_HUISSIER  = 'huissier';
    const AUTORITE_AVOCAT    = 'avocat';
    const AUTORITE_TRIBUNAL  = 'tribunal';
    const AUTORITE_CADASTRE  = 'cadastre';

    protected $fillable = [
        'asset_id', 'demandeur_id', 'autorite_id',
        'statut', 'type_autorite', 'autorite_nom', 'autorite_contact',
        'frais', 'devise', 'paiement_effectue', 'paiement_reference',
        'part_autorite_pct', 'part_plateforme_pct',
        'montant_autorite', 'montant_plateforme',
        'date_demande', 'date_traitement', 'date_expiration',
        'notes', 'motif_refus', 'reference_certification',
        'documents', 'signature_autorite',
        // Anti-doublon
        'hash_actif', 'doublon_detecte', 'doublon_certification_id',
    ];

    protected $casts = [
        'date_demande'      => 'datetime',
        'date_traitement'   => 'datetime',
        'date_expiration'   => 'datetime',
        'frais'             => 'decimal:2',
        'montant_autorite'  => 'decimal:2',
        'montant_plateforme'=> 'decimal:2',
        'paiement_effectue' => 'boolean',
        'doublon_detecte'   => 'boolean',
        'documents'         => 'array',
    ];

    // ─── Relations ────────────────────────────────────────────────────────────

    public function asset()
    {
        return $this->belongsTo(Asset::class);
    }

    public function demandeur()
    {
        return $this->belongsTo(User::class, 'demandeur_id');
    }

    public function autorite()
    {
        return $this->belongsTo(User::class, 'autorite_id');
    }

    public function paiements()
    {
        return $this->hasMany(Paiement::class);
    }

    public function doublonDe()
    {
        return $this->belongsTo(Certification::class, 'doublon_certification_id');
    }

    // ─── Méthodes ─────────────────────────────────────────────────────────────

    /**
     * Calculer et affecter les montants de partage de revenus
     */
    public function calculerPartage(): void
    {
        $pctAutorite   = $this->part_autorite_pct ?? config('asman.revenue_share_authority', 70);
        $pctPlateforme = $this->part_plateforme_pct ?? config('asman.revenue_share_platform', 30);

        $this->montant_autorite   = round($this->frais * $pctAutorite / 100, 2);
        $this->montant_plateforme = round($this->frais * $pctPlateforme / 100, 2);
    }

    /**
     * Générer un hash unique pour détection de doublons
     */
    public function genererHashActif(): string
    {
        $asset = $this->asset;
        $data  = implode('|', [
            $asset->type ?? '',
            strtolower(trim($asset->nom ?? '')),
            $asset->reference_cadastrale ?? '',
            $asset->numero_chassis ?? '',
            $asset->isin ?? '',
            $asset->user_id ?? '',
        ]);
        return hash('sha256', $data);
    }

    // ─── Scopes ───────────────────────────────────────────────────────────────

    public function scopeEnAttente($query)
    {
        return $query->where('statut', self::STATUS_EN_ATTENTE);
    }

    public function scopeCertifiees($query)
    {
        return $query->where('statut', self::STATUS_CERTIFIE);
    }

    public function scopeRefusees($query)
    {
        return $query->where('statut', self::STATUS_REFUSE);
    }
}
