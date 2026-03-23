<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\CompteBancaire;
use App\Models\TransactionBancaire;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CompteController extends Controller
{
    public function index()
    {
        $comptes = CompteBancaire::where('user_id', Auth::id())->get();
        return response()->json(['success' => true, 'data' => $comptes]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'nom'    => 'required|string',
            'banque' => 'required|string',
            'type'   => 'required|in:courant,epargne,dat,titres,autre',
            'solde'  => 'required|numeric',
            'devise' => 'nullable|string|max:3',
        ]);

        $compte = CompteBancaire::create([
            'user_id'       => Auth::id(),
            'nom'           => $request->nom,
            'banque'        => $request->banque,
            'iban'          => $request->iban,
            'numero_compte' => $request->numero_compte,
            'swift_bic'     => $request->swift_bic,
            'type'          => $request->type,
            'solde'         => $request->solde,
            'devise'        => $request->devise ?? 'XOF',
            'pays'          => $request->pays ?? 'BF',
            'date_ouverture' => $request->date_ouverture,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Compte bancaire ajouté.',
            'data'    => $compte
        ], 201);
    }

    public function show(CompteBancaire $compte)
    {
        abort_if($compte->user_id !== Auth::id(), 403);
        return response()->json(['success' => true, 'data' => $compte->load('transactions')]);
    }

    public function update(Request $request, CompteBancaire $compte)
    {
        abort_if($compte->user_id !== Auth::id(), 403);
        $compte->update($request->only([
            'nom', 'banque', 'iban', 'numero_compte', 'swift_bic',
            'type', 'solde', 'devise', 'pays', 'statut', 'date_ouverture'
        ]));
        return response()->json(['success' => true, 'data' => $compte]);
    }

    public function destroy(CompteBancaire $compte)
    {
        abort_if($compte->user_id !== Auth::id(), 403);
        $compte->delete();
        return response()->json(['success' => true, 'message' => 'Compte supprimé.']);
    }

    public function addTransaction(Request $request, CompteBancaire $compte)
    {
        abort_if($compte->user_id !== Auth::id(), 403);
        $request->validate([
            'type'             => 'required|in:credit,debit',
            'montant'          => 'required|numeric|min:0.01',
            'libelle'          => 'required|string',
            'date_transaction' => 'required|date',
        ]);

        $soldeApres = $request->type === 'credit'
            ? $compte->solde + $request->montant
            : $compte->solde - $request->montant;

        $transaction = $compte->transactions()->create([
            'type'             => $request->type,
            'montant'          => $request->montant,
            'libelle'          => $request->libelle,
            'description'      => $request->description,
            'date_transaction' => $request->date_transaction,
            'solde_apres'      => $soldeApres,
        ]);

        $compte->update(['solde' => $soldeApres]);

        return response()->json([
            'success' => true,
            'message' => 'Transaction ajoutée.',
            'data'    => $transaction
        ], 201);
    }

    public function transactions(CompteBancaire $compte)
    {
        abort_if($compte->user_id !== Auth::id(), 403);
        return response()->json([
            'success' => true,
            'data'    => $compte->transactions()->orderByDesc('date_transaction')->get()
        ]);
    }
}
