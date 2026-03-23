<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Liquidation;
use App\Models\Asset;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class LiquidationController extends Controller
{
    public function index(Request $request)
    {
        $liquidations = Liquidation::with(['user', 'testament', 'traitePar'])
            ->orderByDesc('created_at')
            ->paginate(20);
        return view('admin.liquidations.index', compact('liquidations'));
    }

    public function show(Liquidation $liquidation)
    {
        $liquidation->load(['user', 'testament', 'traitePar']);
        return view('admin.liquidations.show', compact('liquidation'));
    }

    public function creerManuelle(Request $request)
    {
        $request->validate([
            'user_id'           => 'required|exists:users,id',
            'type'              => 'required|in:succession,donation,vente,autre',
            'assets_concernes'  => 'required|array',
            'notes'             => 'nullable|string',
        ]);

        $assets        = Asset::whereIn('id', $request->assets_concernes)->get();
        $valeurTotale  = $assets->sum('valeur_actuelle');

        $liquidation = Liquidation::create([
            'reference'        => 'LIQ-' . strtoupper(Str::random(8)),
            'user_id'          => $request->user_id,
            'testament_id'     => $request->testament_id,
            'type'             => $request->type,
            'mode'             => 'manuel',
            'statut'           => 'en_attente',
            'assets_concernes' => $request->assets_concernes,
            'valeur_totale'    => $valeurTotale,
            'notes'            => $request->notes,
        ]);

        return redirect()->route('admin.liquidations.show', $liquidation)
            ->with('success', 'Liquidation créée. Valeur totale : ' . number_format($valeurTotale) . ' XOF');
    }

    public function executer(Request $request, Liquidation $liquidation)
    {
        abort_if($liquidation->statut !== 'en_attente', 403, 'Liquidation déjà traitée.');

        $liquidation->update([
            'statut'         => 'execute',
            'traite_par'     => Auth::id(),
            'date_execution' => now(),
        ]);

        // Marquer les assets comme vendus/transférés
        Asset::whereIn('id', $liquidation->assets_concernes ?? [])
            ->update(['statut' => 'vendu']);

        return redirect()->route('admin.liquidations.show', $liquidation)
            ->with('success', 'Liquidation exécutée avec succès.');
    }

    public function annuler(Request $request, Liquidation $liquidation)
    {
        abort_if($liquidation->statut === 'execute', 403, 'Impossible d\'annuler une liquidation exécutée.');
        $liquidation->update(['statut' => 'annule']);
        return back()->with('success', 'Liquidation annulée.');
    }
}
