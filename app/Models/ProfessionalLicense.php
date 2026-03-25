<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProfessionalLicense extends Model
{
    protected $fillable = [
        'type', 'nom_cabinet', 'responsable_nom', 'numero_agrement',
        'ville', 'pays', 'telephone', 'email', 'specialites',
        'tarif_base', 'statut', 'note_moyenne', 'commission_rate',
    ];

    protected $casts = [
        'specialites'   => 'array',
        'note_moyenne'  => 'float',
        'tarif_base'    => 'integer',
        'commission_rate' => 'float',
    ];

    // Types
    const TYPE_NOTAIRE          = 'notaire';
    const TYPE_HUISSIER         = 'huissier';
    const TYPE_AVOCAT           = 'avocat';
    const TYPE_EXPERT_IMMOBILIER = 'expert_immobilier';
    const TYPE_EXPERT_VEHICULE   = 'expert_vehicule';
    const TYPE_EXPERT_FINANCIER  = 'expert_financier';

    public function expertises()
    {
        return $this->hasMany(ExpertiseRequest::class);
    }

    public function revenues()
    {
        return $this->hasMany(RevenueShare::class);
    }

    public function getLibelleTypeAttribute(): string
    {
        return match($this->type) {
            'notaire'           => 'Notaire',
            'huissier'          => 'Huissier de justice',
            'avocat'            => 'Avocat',
            'expert_immobilier' => 'Expert immobilier',
            'expert_vehicule'   => 'Expert automobile',
            'expert_financier'  => 'Expert financier',
            default             => ucfirst($this->type),
        };
    }
}
