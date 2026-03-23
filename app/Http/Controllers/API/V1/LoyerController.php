<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\Loyer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LoyerController extends Controller
{
    public function index()
    {
        $loyers = Loyer::with('asset')
            ->where('user_id', Auth::id())
            ->orderByDesc('date_echeance')
            ->get();
        return response()->json(['success' => true, 'data' => $loyers]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'asset_id'           => 'required|exists:assets,id',
            'locataire'          => 'required|string',
            'montant'            => 'required|numeric|min:0',
            'periodicite'        => 'required|in:mensuel,trimestriel,semestriel,annuel',
            'date_debut'         => 'required|date',
            'date_echeance'      => 'required|date',
        ]);

        $loyer = Loyer::create([
            'user_id'            => Auth::id(),
            'asset_id'           => $request->asset_id,
            'locataire'          => $request->locataire,
            'contact_locataire'  => $request->contact_locataire,
            'montant'            => $request->montant,
            'devise'             => $request->devise ?? 'XOF',
            'periodicite'        => $request->periodicite,
            'date_debut'         => $request->date_debut,
            'date_fin'           => $request->date_fin,
            'date_echeance'      => $request->date_echeance,
            'est_paye'           => false,
            'notes'              => $request->notes,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Loyer ajouté.',
            'data'    => $loyer->load('asset')
        ], 201);
    }

    public function show(Loyer $loyer)
    {
        abort_if($loyer->user_id !== Auth::id(), 403);
        return response()->json(['success' => true, 'data' => $loyer->load('asset')]);
    }

    public function update(Request $request, Loyer $loyer)
    {
        abort_if($loyer->user_id !== Auth::id(), 403);
        $loyer->update($request->only([
            'locataire', 'contact_locataire', 'montant', 'devise',
            'periodicite', 'date_fin', 'date_echeance', 'notes'
        ]));
        return response()->json(['success' => true, 'data' => $loyer]);
    }

    public function destroy(Loyer $loyer)
    {
        abort_if($loyer->user_id !== Auth::id(), 403);
        $loyer->delete();
        return response()->json(['success' => true, 'message' => 'Loyer supprimé.']);
    }

    public function marquerPaye(Request $request, Loyer $loyer)
    {
        abort_if($loyer->user_id !== Auth::id(), 403);
        $loyer->update([
            'est_paye'       => true,
            'date_paiement'  => now()->toDateString(),
        ]);
        return response()->json([
            'success' => true,
            'message' => 'Loyer marqué comme payé.',
            'data'    => $loyer
        ]);
    }
}
