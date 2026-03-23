<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Loyer extends Model {
    protected $fillable = ['user_id','asset_id','locataire','contact_locataire','montant','devise','periodicite','date_debut','date_fin','date_echeance','est_paye','date_paiement','notes'];
    public function user()  { return $this->belongsTo(User::class); }
    public function asset() { return $this->belongsTo(Asset::class); }
}
