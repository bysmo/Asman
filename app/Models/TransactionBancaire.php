<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class TransactionBancaire extends Model {
    protected $table = 'transactions_bancaires';
    protected $fillable = ['compte_id','type','montant','libelle','description','date_transaction','solde_apres'];
    public function compte() { return $this->belongsTo(CompteBancaire::class, 'compte_id'); }
}
