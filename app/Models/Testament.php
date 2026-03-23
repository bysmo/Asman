<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Testament extends Model
{
    use HasFactory, SoftDeletes;

    const STATUS_BROUILLON  = 'brouillon';
    const STATUS_FINALISE   = 'finalise';
    const STATUS_CERTIFIE   = 'certifie';
    const STATUS_CONTESTE   = 'conteste';
    const STATUS_EXECUTE    = 'execute';

    protected $fillable = [
        'user_id', 'statut', 'notes',
        'notaire_id', 'notaire_nom', 'notaire_contact',
        'reference_certification', 'date_certification',
        'date_finalisation', 'paiement_certif_effectue',
        'frais_certification', 'devise',
        'document_path', 'signature_testateur',
        'temoins', 'conditions_generales',
    ];

    protected $casts = [
        'date_certification'        => 'datetime',
        'date_finalisation'         => 'datetime',
        'paiement_certif_effectue'  => 'boolean',
        'frais_certification'       => 'decimal:2',
        'temoins'                   => 'array',
    ];

    // ─── Relations ────────────────────────────────────────────────────────────

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function notaire()
    {
        return $this->belongsTo(User::class, 'notaire_id');
    }

    public function ayantsDroits()
    {
        return $this->hasMany(AyantDroit::class);
    }

    public function repartitions()
    {
        return $this->hasMany(RepartitionBien::class);
    }

    // ─── Accesseurs ───────────────────────────────────────────────────────────

    public function getEstCertifieAttribute(): bool
    {
        return $this->statut === self::STATUS_CERTIFIE;
    }
}

// ─── AYANT DROIT ──────────────────────────────────────────────────────────────

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AyantDroit extends Model
{
    use HasFactory;

    const TYPE_HERITIER  = 'heritier';
    const TYPE_LEGATAIRE = 'legataire';
    const TYPE_ASCENDANT = 'ascendant';
    const TYPE_CONJOINT  = 'conjoint';
    const TYPE_AUTRE     = 'autre';

    protected $fillable = [
        'testament_id', 'nom', 'prenom', 'type', 'lien_parente',
        'contact', 'nationalite', 'numero_piece_identite',
        'date_naissance', 'adresse', 'notes',
    ];

    protected $casts = [
        'date_naissance' => 'date',
    ];

    public function testament()
    {
        return $this->belongsTo(Testament::class);
    }

    public function repartitions()
    {
        return $this->hasMany(RepartitionBien::class);
    }

    public function getNomCompletAttribute(): string
    {
        return trim("{$this->prenom} {$this->nom}");
    }
}

// ─── RÉPARTITION BIEN ─────────────────────────────────────────────────────────

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RepartitionBien extends Model
{
    use HasFactory;

    protected $fillable = [
        'testament_id', 'asset_id', 'ayant_droit_id',
        'pourcentage', 'conditions', 'notes', 'valeur_estimee',
    ];

    protected $casts = [
        'pourcentage'   => 'decimal:2',
        'valeur_estimee'=> 'decimal:2',
    ];

    public function testament()
    {
        return $this->belongsTo(Testament::class);
    }

    public function asset()
    {
        return $this->belongsTo(Asset::class);
    }

    public function ayantDroit()
    {
        return $this->belongsTo(AyantDroit::class);
    }
}
