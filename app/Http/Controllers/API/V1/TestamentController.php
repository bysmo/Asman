<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\Testament;
use App\Models\AyantDroit;
use App\Models\AllocationTestament;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class TestamentController extends Controller
{
    public function index()
    {
        $testaments = Testament::with(['ayantsDroit', 'notaire'])
            ->where('user_id', Auth::id())
            ->get();

        return response()->json(['success' => true, 'data' => $testaments]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'contenu'   => 'nullable|string',
            'clauses'   => 'nullable|string',
            'temoin_1'  => 'nullable|string',
            'temoin_2'  => 'nullable|string',
        ]);

        $testament = Testament::create([
            'reference'              => 'TEST-' . strtoupper(Str::random(8)),
            'user_id'                => Auth::id(),
            'statut'                 => 'brouillon',
            'contenu'                => $request->contenu,
            'dispositions_speciales' => $request->dispositions_speciales,
            'clauses'                => $request->clauses,
            'temoin_1'               => $request->temoin_1,
            'temoin_2'               => $request->temoin_2,
            'date_redaction'         => now()->toDateString(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Testament créé avec succès.',
            'data'    => $testament->load('ayantsDroit')
        ], 201);
    }

    public function show(Testament $testament)
    {
        $this->authorize('view', $testament);
        return response()->json([
            'success' => true,
            'data'    => $testament->load(['ayantsDroit', 'allocations.asset', 'notaire'])
        ]);
    }

    public function update(Request $request, Testament $testament)
    {
        $this->authorize('update', $testament);
        abort_if($testament->statut === 'certifie', 403, 'Un testament certifié ne peut pas être modifié.');

        $testament->update($request->only([
            'contenu', 'dispositions_speciales', 'clauses', 'temoin_1', 'temoin_2'
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Testament mis à jour.',
            'data'    => $testament
        ]);
    }

    public function destroy(Testament $testament)
    {
        $this->authorize('delete', $testament);
        abort_if($testament->statut === 'certifie', 403, 'Impossible de supprimer un testament certifié.');
        $testament->delete();
        return response()->json(['success' => true, 'message' => 'Testament supprimé.']);
    }

    public function finaliser(Testament $testament)
    {
        $this->authorize('update', $testament);
        abort_if(
            !in_array($testament->statut, ['brouillon']),
            403,
            'Seul un brouillon peut être finalisé.'
        );

        $testament->update(['statut' => 'finalise']);
        return response()->json([
            'success' => true,
            'message' => 'Testament finalisé. Vous pouvez maintenant demander la certification.',
            'data'    => $testament
        ]);
    }

    public function certifier(Request $request, Testament $testament)
    {
        $this->authorize('update', $testament);
        $request->validate(['notaire_id' => 'required|exists:users,id']);

        abort_if(
            $testament->statut !== 'finalise',
            403,
            'Seul un testament finalisé peut être soumis à certification.'
        );

        $testament->update([
            'statut'     => 'certifie',
            'notaire_id' => $request->notaire_id,
            'date_certification' => now()->toDateString(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Demande de certification envoyée au notaire.',
            'data'    => $testament->load('notaire')
        ]);
    }

    public function ayantsDroit(Testament $testament)
    {
        $this->authorize('view', $testament);
        return response()->json([
            'success' => true,
            'data'    => $testament->ayantsDroit
        ]);
    }

    public function addAyantDroit(Request $request, Testament $testament)
    {
        $this->authorize('update', $testament);
        $request->validate([
            'nom'          => 'required|string',
            'prenom'       => 'required|string',
            'lien_parente' => 'required|string',
            'type'         => 'required|in:heritier,legataire,ascendant,conjoint,autre',
            'pourcentage'  => 'required|numeric|min:0|max:100',
        ]);

        $ayantDroit = $testament->ayantsDroit()->create($request->all());
        return response()->json([
            'success' => true,
            'message' => 'Ayant droit ajouté.',
            'data'    => $ayantDroit
        ], 201);
    }
}
