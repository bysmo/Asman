<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Evaluation extends Model {
    protected $fillable = ['asset_id','user_id','evaluateur_id','valeur_precedente','valeur_nouvelle','devise','methode','justification','documents'];
    protected $casts = ['documents' => 'array'];
    public function asset()      { return $this->belongsTo(Asset::class); }
    public function user()       { return $this->belongsTo(User::class); }
    public function evaluateur() { return $this->belongsTo(User::class, 'evaluateur_id'); }
}
