<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class MarketplaceListing extends Model {
    use SoftDeletes;
    protected $table = 'marketplace_listings';
    protected $fillable = ['reference','asset_id','user_id','type','statut','prix','devise','description','photos','negociable','date_expiration','vues'];
    protected $casts = ['photos' => 'array', 'negociable' => 'boolean'];
    public function asset() { return $this->belongsTo(Asset::class); }
    public function user()  { return $this->belongsTo(User::class); }
}
