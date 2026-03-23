<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\Evaluation;
use App\Models\Asset;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class EvaluationController extends Controller
{
    public function index()
    {
        $evaluations = Evaluation::with('asset')
            ->whereHas('asset', fn($q) => $q->where('user_id', Auth::id()))
            ->orderByDesc('created_at')
            ->get();
        return response()->json(['success' => true, 'data' => $evaluations]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'asset_id'      => 'required|exists:assets,id',
            'valeur_nouvelle' => 'required|numeric|min:0',
            'methode'       => 'nullable|string',
            'justification' => 'nullable|string',
        ]);

        $asset = Asset::where('id', $request->asset_id)
            ->where('user_id', Auth::id())
            ->firstOrFail();

        $evaluation = Evaluation::create([
            'asset_id'          => $asset->id,
            'user_id'           => Auth::id(),
            'valeur_precedente' => $asset->valeur_actuelle,
            'valeur_nouvelle'   => $request->valeur_nouvelle,
            'devise'            => $request->devise ?? $asset->devise,
            'methode'           => $request->methode,
            'justification'     => $request->justification,
        ]);

        $asset->update([
            'valeur_actuelle'          => $request->valeur_nouvelle,
            'date_derniere_evaluation' => now()->toDateString(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Évaluation enregistrée.',
            'data'    => $evaluation
        ], 201);
    }

    public function show(Evaluation $evaluation)
    {
        return response()->json(['success' => true, 'data' => $evaluation->load('asset')]);
    }
}
