<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class ExpertiseRequest extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'reference','user_id','asset_id','professional_license_id','assigned_to',
        'type_service','sous_type','statut',
        'montant_ht','taux_remise','montant_remise','montant_ttc','devise',
        'est_paye','methode_paiement','reference_paiement','paye_le',
        'part_professionnel','part_plateforme','part_fonds_garantie','part_superviseur',
        'versement_effectue','verse_le',
        'description','notes_client','notes_professionnel',
        'documents_client','documents_rapport','valeur_estimee','devise_estimee','conclusion_rapport',
        'urgence','date_souhaitee','date_assignee','date_debut_expertise','date_rendu',
        'lieu_expertise','coordonnees_lieu','note_client','avis_client','evalue_le',
    ];

    protected $casts = [
        'est_paye'           => 'boolean',
        'versement_effectue' => 'boolean',
        'documents_client'   => 'array',
        'documents_rapport'  => 'array',
        'coordonnees_lieu'   => 'array',
        'paye_le'            => 'datetime',
        'verse_le'           => 'datetime',
        'date_souhaitee'     => 'datetime',
        'date_assignee'      => 'datetime',
        'date_debut_expertise' => 'datetime',
        'date_rendu'         => 'datetime',
        'evalue_le'          => 'datetime',
        'montant_ht'         => 'decimal:2',
        'montant_ttc'        => 'decimal:2',
        'montant_remise'     => 'decimal:2',
        'part_professionnel' => 'decimal:2',
        'part_plateforme'    => 'decimal:2',
        'part_fonds_garantie'=> 'decimal:2',
        'part_superviseur'   => 'decimal:2',
        'valeur_estimee'     => 'decimal:2',
    ];

    // Types de services
    const TYPE_EXPERTISE_IMMOBILIERE = 'expertise_immobiliere';
    const TYPE_EXPERTISE_VEHICULE    = 'expertise_vehicule';
    const TYPE_EXPERTISE_ENTREPRISE  = 'expertise_entreprise';
    const TYPE_EXPERTISE_BIJOUX      = 'expertise_bijoux';
    const TYPE_EXPERTISE_AGRICOLE    = 'expertise_agricole';
    const TYPE_EXPERTISE_INDUSTRIELLE= 'expertise_industrielle';
    const TYPE_CERTIFICATION         = 'certification_notariale';
    const TYPE_CONSTAT               = 'constat_huissier';
    const TYPE_CONSULTATION_AVOCAT   = 'consultation_avocat';
    const TYPE_TESTAMENT             = 'testament';

    // Statuts
    const STATUT_ATTENTE   = 'en_attente';
    const STATUT_ASSIGNEE  = 'assignee';
    const STATUT_EN_COURS  = 'en_cours';
    const STATUT_RAPPORT   = 'rapport_soumis';
    const STATUT_VALIDEE   = 'validee';
    const STATUT_LIVREE    = 'livree';
    const STATUT_ANNULEE   = 'annulee';
    const STATUT_LITIGEE   = 'litigee';

    // Urgences
    const URGENCE_NORMALE     = 'normale';
    const URGENCE_PRIORITAIRE = 'prioritaire';
    const URGENCE_EXPRESS     = 'express';

    public function user(): BelongsTo     { return $this->belongsTo(User::class); }
    public function asset(): BelongsTo    { return $this->belongsTo(Asset::class); }
    public function cabinet(): BelongsTo  { return $this->belongsTo(ProfessionalLicense::class, 'professional_license_id'); }
    public function expert(): BelongsTo   { return $this->belongsTo(User::class, 'assigned_to'); }

    public function isTerminee(): bool    { return in_array($this->statut, [self::STATUT_LIVREE, self::STATUT_ANNULEE]); }
    public function isPayee(): bool       { return $this->est_paye; }

    public function calculateRevenueSplit(float $montant, float $pctPro, float $pctPlatform, float $pctFonds, float $pctSuperv): array
    {
        return [
            'professionnel'  => round($montant * $pctPro / 100, 2),
            'plateforme'     => round($montant * $pctPlatform / 100, 2),
            'fonds_garantie' => round($montant * $pctFonds / 100, 2),
            'superviseur'    => round($montant * $pctSuperv / 100, 2),
        ];
    }

    protected static function boot(): void
    {
        parent::boot();
        static::creating(function ($model) {
            if (empty($model->reference)) {
                $model->reference = 'EXP-' . date('Y') . '-' . str_pad(rand(1, 999999), 6, '0', STR_PAD_LEFT);
            }
        });
    }
}
