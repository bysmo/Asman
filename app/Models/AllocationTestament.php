<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class AllocationTestament extends Model {
    protected $table = 'allocations_testament';
    protected $fillable = ['testament_id','asset_id','ayant_droit_id','pourcentage','conditions'];
    public function testament()  { return $this->belongsTo(Testament::class); }
    public function asset()      { return $this->belongsTo(Asset::class); }
    public function ayantDroit() { return $this->belongsTo(AyantDroit::class, 'ayant_droit_id'); }
}
