<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\SoftDeletes;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $fillable = [
        'nom', 'prenom', 'email', 'telephone', 'password',
        'role', 'statut', 'pays', 'devise', 'langue', 'photo',
        'pin_hash', 'pin_enabled', 'otp_code', 'otp_expires_at', 'otp_verified',
        'kyc_statut', 'kyc_date', 'kyc_niveau',
        'numero_piece', 'type_piece', 'date_naissance', 'lieu_naissance',
        'adresse', 'ville', 'province', 'region',
        'numero_professionnel', 'ordre_professionnel', 'cabinet', 'juridiction',
    ];

    protected $hidden = ['password', 'remember_token', 'pin_hash', 'otp_code'];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'otp_expires_at'    => 'datetime',
        'kyc_date'          => 'datetime',
        'date_naissance'    => 'date',
        'pin_enabled'       => 'boolean',
        'otp_verified'      => 'boolean',
    ];

    // ─── Accesseur nom complet ───────────────────────────────────────────
    public function getNomCompletAttribute(): string
    {
        return "{$this->prenom} {$this->nom}";
    }

    // ─── Relations ───────────────────────────────────────────────────────
    public function assets()
    {
        return $this->hasMany(Asset::class);
    }

    public function certifications()
    {
        return $this->hasMany(Certification::class, 'assigne_a');
    }

    public function certificationsDemandees()
    {
        return $this->hasMany(Certification::class, 'user_id');
    }

    public function testaments()
    {
        return $this->hasMany(Testament::class);
    }

    public function kycDocuments()
    {
        return $this->hasMany(KycDocument::class);
    }

    public function comptesBancaires()
    {
        return $this->hasMany(CompteBancaire::class);
    }

    public function creances()
    {
        return $this->hasMany(Creance::class);
    }

    public function dettes()
    {
        return $this->hasMany(Dette::class);
    }

    public function revenueShares()
    {
        return $this->hasMany(RevenueShare::class, 'autorite_id');
    }

    // ─── Helpers rôle ────────────────────────────────────────────────────
    public function isAdmin(): bool     { return $this->role === 'admin'; }
    public function isNotaire(): bool   { return $this->role === 'notaire'; }
    public function isHuissier(): bool  { return $this->role === 'huissier'; }
    public function isAvocat(): bool    { return $this->role === 'avocat'; }
    public function isAutorite(): bool  { return in_array($this->role, ['notaire', 'huissier', 'avocat']); }
    public function isClient(): bool    { return $this->role === 'client'; }
    public function isActif(): bool     { return $this->statut === 'actif'; }
}
