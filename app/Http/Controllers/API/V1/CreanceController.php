<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\Creance;
use App\Models\Dette;
use App\Models\Remboursement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CreanceController extends Controller
{
    // Créances
    public function index(Request $request)
    {
        $type  = $request->query('type', 'creance');
        $model = $type === 'dette' ? Dette::class : Creance::class;

        $items = $model::where('user_id', Auth::id())
            ->with('remboursements')
            ->get();

        return response()->json(['success' => true, 'data' => $items]);
    }

    public function store(Request $request)
    {
        $type = $request->input('type', 'creance');

        $rules = [
            'nom_contact'     => 'required|string',
            'montant_initial' => 'required|numeric|min:0',
            'taux_interet'    => 'nullable|numeric|min:0',
            'devise'          => 'nullable|string|max:3',
            'date_debut'      => 'required|date',
            'date_echeance'   => 'required|date|after:date_debut',
            'description'     => 'nullable|string',
            'garantie'        => 'nullable|string',
        ];

        $validated = $request->validate($rules);

        if ($type === 'dette') {
            $item = Dette::create([
                'user_id'          => Auth::id(),
                'nom_creancier'    => $request->nom_contact,
                'contact_creancier' => $request->contact,
                'montant_initial'  => $request->montant_initial,
                'montant_restant'  => $request->montant_initial,
                'taux_interet'     => $request->taux_interet ?? 0,
                'devise'           => $request->devise ?? 'XOF',
                'date_emprunt'     => $request->date_debut,
                'date_echeance'    => $request->date_echeance,
                'statut'           => 'en_cours',
                'description'      => $request->description,
                'garantie'         => $request->garantie,
            ]);
            $label = 'Dette';
        } else {
            $item = Creance::create([
                'user_id'          => Auth::id(),
                'nom_debiteur'     => $request->nom_contact,
                'contact_debiteur' => $request->contact,
                'montant_initial'  => $request->montant_initial,
                'montant_restant'  => $request->montant_initial,
                'taux_interet'     => $request->taux_interet ?? 0,
                'devise'           => $request->devise ?? 'XOF',
                'date_pret'        => $request->date_debut,
                'date_echeance'    => $request->date_echeance,
                'statut'           => 'en_cours',
                'description'      => $request->description,
                'garantie'         => $request->garantie,
            ]);
            $label = 'Créance';
        }

        return response()->json([
            'success' => true,
            'message' => "{$label} ajoutée avec succès.",
            'data'    => $item
        ], 201);
    }

    public function show($id, Request $request)
    {
        $type  = $request->query('type', 'creance');
        $model = $type === 'dette' ? Dette::class : Creance::class;
        $item  = $model::where('id', $id)->where('user_id', Auth::id())->firstOrFail();
        return response()->json(['success' => true, 'data' => $item->load('remboursements')]);
    }

    public function update(Request $request, $id)
    {
        $type  = $request->input('type', 'creance');
        $model = $type === 'dette' ? Dette::class : Creance::class;
        $item  = $model::where('id', $id)->where('user_id', Auth::id())->firstOrFail();
        $item->update($request->except(['user_id', 'type']));
        return response()->json(['success' => true, 'data' => $item]);
    }

    public function destroy($id, Request $request)
    {
        $type  = $request->query('type', 'creance');
        $model = $type === 'dette' ? Dette::class : Creance::class;
        $item  = $model::where('id', $id)->where('user_id', Auth::id())->firstOrFail();
        $item->delete();
        return response()->json(['success' => true, 'message' => 'Supprimé avec succès.']);
    }

    public function addRemboursement(Request $request, $id)
    {
        $request->validate([
            'montant'              => 'required|numeric|min:0.01',
            'date_remboursement'   => 'required|date',
            'mode_paiement'        => 'nullable|string',
            'notes'                => 'nullable|string',
        ]);

        $type  = $request->query('type', 'creance');
        $model = $type === 'dette' ? Dette::class : Creance::class;
        $item  = $model::where('id', $id)->where('user_id', Auth::id())->firstOrFail();

        $remboursement = $item->remboursements()->create([
            'montant'            => $request->montant,
            'date_remboursement' => $request->date_remboursement,
            'mode_paiement'      => $request->mode_paiement,
            'notes'              => $request->notes,
        ]);

        $nouveauRestant = max(0, $item->montant_restant - $request->montant);
        $statut = $nouveauRestant <= 0 ? 'rembourse' : 'partiellement_rembourse';
        $item->update(['montant_restant' => $nouveauRestant, 'statut' => $statut]);

        return response()->json([
            'success' => true,
            'message' => 'Remboursement enregistré.',
            'data'    => ['remboursement' => $remboursement, 'montant_restant' => $nouveauRestant]
        ], 201);
    }
}
