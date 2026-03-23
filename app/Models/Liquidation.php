<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Liquidation extends Model {
    use SoftDeletes;
    protected $fillable = ['reference','user_id','testament_id','type','mode','statut','assets_concernes','valeur_totale','notes','traite_par','date_execution'];
    protected $casts = ['assets_concernes' => 'array'];
    public function user()      { return $this->belongsTo(User::class); }
    public function testament() { return $this->belongsTo(Testament::class); }
    public function traitePar() { return $this->belongsTo(User::class, 'traite_par'); }
}
