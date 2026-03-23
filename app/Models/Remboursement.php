<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Remboursement extends Model {
    protected $fillable = ['montant','date_remboursement','mode_paiement','notes'];
    public function remboursable() { return $this->morphTo(); }
}
