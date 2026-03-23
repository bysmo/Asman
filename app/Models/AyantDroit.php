<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class AyantDroit extends Model {
    protected $table = 'ayants_droit';
    protected $fillable = ['testament_id','nom','prenom','email','telephone','lien_parente','type','pourcentage','biens_specifiques','adresse','numero_piece'];
    public function testament() { return $this->belongsTo(Testament::class); }
}
