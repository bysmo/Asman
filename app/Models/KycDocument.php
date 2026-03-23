<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class KycDocument extends Model {
    protected $table = 'kyc_documents';
    protected $fillable = ['user_id','type','fichier','nom_original','statut','commentaire','verifie_par','verifie_le'];
    public function user()      { return $this->belongsTo(User::class); }
    public function verificateur() { return $this->belongsTo(User::class, 'verifie_par'); }
}
