<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class RevenueShare extends Model {
    protected $table = 'revenue_shares';
    protected $fillable = ['certification_id','autorite_id','montant_total','montant_autorite','montant_plateforme','devise','statut','date_distribution'];
    public function certification() { return $this->belongsTo(Certification::class); }
    public function autorite()      { return $this->belongsTo(User::class, 'autorite_id'); }
}
