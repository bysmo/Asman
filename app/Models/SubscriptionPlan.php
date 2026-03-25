<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SubscriptionPlan extends Model
{
    protected $fillable = [
        'slug', 'nom', 'description',
        'monthly_price', 'annual_price',
        'features', 'limits', 'is_active',
    ];

    protected $casts = [
        'features'     => 'array',
        'limits'       => 'array',
        'is_active'    => 'boolean',
        'monthly_price' => 'integer',
        'annual_price'  => 'integer',
    ];

    public function subscriptions()
    {
        return $this->hasMany(Subscription::class);
    }

    public function getLimitAttribute(string $key, $default = null): mixed
    {
        return ($this->limits ?? [])[$key] ?? $default;
    }
}
