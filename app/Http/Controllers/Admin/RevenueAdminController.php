<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\RevenueShare;
use App\Models\Certification;
use App\Models\User;
use Illuminate\Http\Request;

class RevenueAdminController extends Controller
{
    public function index()
    {
        $stats = [
            'plateforme_total'    => RevenueShare::sum('montant_plateforme'),
            'autorites_total'     => RevenueShare::sum('montant_autorite'),
            'en_attente'          => RevenueShare::where('statut', 'en_attente')->sum('montant_autorite'),
            'distribue'           => RevenueShare::where('statut', 'distribue')->sum('montant_autorite'),
        ];

        $par_autorite = User::withSum(['revenueShares as total_revenus' => function($q) {
                $q->where('statut', 'en_attente');
            }], 'montant_autorite')
            ->whereIn('role', ['notaire', 'huissier', 'avocat'])
            ->get();

        $recent = RevenueShare::with(['certification.asset', 'autorite'])
            ->orderByDesc('created_at')
            ->take(20)
            ->get();

        return view('admin.revenus.index', compact('stats', 'par_autorite', 'recent'));
    }

    public function rapport(Request $request)
    {
        $mois  = $request->get('mois', now()->format('Y-m'));
        $start = $mois . '-01';
        $end   = date('Y-m-t', strtotime($start));

        $shares = RevenueShare::with(['certification.asset', 'autorite'])
            ->whereBetween('created_at', [$start, $end])
            ->get();

        $repartition = Certification::selectRaw(
            'type_autorite, 
             COUNT(*) as nb, 
             SUM(montant_autorite) as total_autorite, 
             SUM(montant_plateforme) as total_plateforme,
             SUM(frais) as total_frais'
        )->where('statut', 'certifie')
         ->whereBetween('date_certification', [$start, $end])
         ->groupBy('type_autorite')
         ->get();

        return view('admin.revenus.rapport', compact('shares', 'repartition', 'mois'));
    }

    public function distribuer(Request $request)
    {
        $request->validate(['autorite_id' => 'required|exists:users,id']);

        $count = RevenueShare::where('autorite_id', $request->autorite_id)
            ->where('statut', 'en_attente')
            ->update([
                'statut'              => 'distribue',
                'date_distribution'   => now(),
            ]);

        return back()->with('success', "{$count} paiement(s) marqué(s) comme distribués.");
    }
}
