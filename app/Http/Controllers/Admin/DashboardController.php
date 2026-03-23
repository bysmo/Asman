<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Asset;
use App\Models\Certification;
use App\Models\Testament;
use App\Models\Liquidation;
use App\Models\RevenueShare;

class DashboardController extends Controller
{
    public function index()
    {
        $stats = [
            'utilisateurs'         => User::where('role', 'client')->count(),
            'autorites'            => User::whereIn('role', ['notaire', 'huissier', 'avocat'])->count(),
            'assets'               => Asset::count(),
            'certifications_total' => Certification::count(),
            'certifications_attente' => Certification::where('statut', 'en_attente')->count(),
            'certifications_cours'   => Certification::where('statut', 'en_cours')->count(),
            'certifications_ok'      => Certification::where('statut', 'certifie')->count(),
            'testaments'           => Testament::count(),
            'testaments_certifies' => Testament::where('statut', 'certifie')->count(),
            'liquidations'         => Liquidation::count(),
            'revenus_plateforme'   => RevenueShare::sum('montant_plateforme'),
            'revenus_autorites'    => RevenueShare::sum('montant_autorite'),
        ];

        $recent_certifications = Certification::with(['asset', 'user', 'assigneA'])
            ->orderByDesc('created_at')
            ->take(10)
            ->get();

        $top_autorites = User::withCount(['certifications as nb_certifications'])
            ->whereIn('role', ['notaire', 'huissier', 'avocat'])
            ->orderByDesc('nb_certifications')
            ->take(5)
            ->get();

        return view('admin.dashboard', compact('stats', 'recent_certifications', 'top_autorites'));
    }
}
