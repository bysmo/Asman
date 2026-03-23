<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class CompteBancaire extends Model {
    use SoftDeletes;
    protected $table = 'comptes_bancaires';
    protected $fillable = ['user_id','nom','banque','iban','numero_compte','swift_bic','type','solde','devise','pays','statut','date_ouverture'];
    public function user()      { return $this->belongsTo(User::class); }
    public function transactions() { return $this->hasMany(TransactionBancaire::class, 'compte_id'); }
}
