<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Creance extends Model {
    use SoftDeletes;
    protected $fillable = ['user_id','nom_debiteur','contact_debiteur','montant_initial','montant_restant','taux_interet','devise','date_pret','date_echeance','statut','description','garantie','documents'];
    protected $casts = ['documents' => 'array'];
    public function user()           { return $this->belongsTo(User::class); }
    public function remboursements() { return $this->morphMany(Remboursement::class, 'remboursable'); }
}
