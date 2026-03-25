<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Subscription extends Model
{
    protected $fillable = [
        'user_id', 'subscription_plan_id', 'billing_period',
        'date_debut', 'date_fin', 'montant_paye', 'statut',
        'payment_method', 'payment_reference', 'auto_renew',
    ];

    protected $casts = [
        'date_debut'  => 'datetime',
        'date_fin'    => 'datetime',
        'montant_paye' => 'integer',
        'auto_renew'  => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function plan()
    {
        return $this->belongsTo(SubscriptionPlan::class, 'subscription_plan_id');
    }

    public function isActive(): bool
    {
        return $this->statut === 'actif' && $this->date_fin->isFuture();
    }
}
