<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Subscription;
use App\Models\ExpertiseRequest;
use App\Models\Certification;
use App\Models\RevenueShare;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DashboardAdminController extends Controller
{
    public function index()
    {
        $today     = Carbon::today();
        $thisMonth = Carbon::now()->startOfMonth();

        // ─── KPIs utilisateurs ───────────────────────────────────────────────
        $users = [
            'total'            => User::count(),
            'actifs_ce_mois'   => User::where('created_at', '>=', $thisMonth)->count(),
            'avec_kyc'         => User::whereHas('kycDocuments', fn($q) => $q->where('statut', 'approuve'))->count(),
            'par_tier'         => $this->getUsersByTier(),
        ];

        // ─── KPIs revenus ────────────────────────────────────────────────────
        $revenus = [
            'abonnements_mois'   => Subscription::where('created_at', '>=', $thisMonth)
                                        ->where('statut', 'actif')
                                        ->sum('montant_paye'),
            'expertise_mois'     => RevenueShare::where('created_at', '>=', $thisMonth)
                                        ->where('type_service', 'expertise')
                                        ->sum('part_asman'),
            'certification_mois' => RevenueShare::where('created_at', '>=', $thisMonth)
                                        ->where('type_service', 'certification')
                                        ->sum('part_asman'),
            'total_mois'         => RevenueShare::where('created_at', '>=', $thisMonth)
                                        ->sum('part_asman')
                                        + Subscription::where('created_at', '>=', $thisMonth)
                                            ->where('statut', 'actif')
                                            ->sum('montant_paye'),
        ];

        // ─── KPIs services ───────────────────────────────────────────────────
        $services = [
            'expertises_en_attente' => ExpertiseRequest::where('statut', 'en_attente')->count(),
            'certifications_attente' => Certification::where('statut', 'soumise')->count(),
            'expertises_ce_mois'    => ExpertiseRequest::where('created_at', '>=', $thisMonth)->count(),
        ];

        // ─── Graphique revenus 6 derniers mois ───────────────────────────────
        $revenusChart = collect(range(5, 0))->map(function ($i) {
            $month = Carbon::now()->subMonths($i);
            return [
                'mois'    => $month->format('M Y'),
                'revenus' => RevenueShare::whereYear('created_at', $month->year)
                                ->whereMonth('created_at', $month->month)
                                ->sum('part_asman'),
            ];
        });

        return $this->successResponse([
            'users'         => $users,
            'revenus'       => $revenus,
            'services'      => $services,
            'revenus_chart' => $revenusChart,
        ], 'Dashboard admin');
    }

    private function getUsersByTier(): array
    {
        $active = Subscription::with('plan')
            ->where('statut', 'actif')
            ->where('date_fin', '>', now())
            ->get()
            ->groupBy(fn($s) => $s->plan->slug ?? 'decouverte')
            ->map(fn($g) => $g->count());

        return [
            'decouverte' => User::count() - $active->sum(),
            'standard'   => $active->get('standard', 0),
            'premium'    => $active->get('premium', 0),
            'elite'      => $active->get('elite', 0),
            'family'     => $active->get('family', 0),
        ];
    }

    // ─── Liste des abonnements actifs ────────────────────────────────────────
    public function subscriptions(Request $request)
    {
        $subs = Subscription::with(['user', 'plan'])
            ->when($request->tier, fn($q, $t) => $q->whereHas('plan', fn($p) => $p->where('slug', $t)))
            ->when($request->statut, fn($q, $s) => $q->where('statut', $s))
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return $this->paginatedResponse($subs->map(fn($s) => [
            'id'         => $s->id,
            'user'       => ['nom' => $s->user->name, 'email' => $s->user->email],
            'plan'       => $s->plan->nom,
            'montant'    => $s->montant_paye,
            'date_fin'   => $s->date_fin,
            'statut'     => $s->statut,
        ]), $subs->total(), $subs->currentPage(), $subs->perPage());
    }

    // ─── Liste des cabinets partenaires ──────────────────────────────────────
    public function cabinets(Request $request)
    {
        $cabinets = \App\Models\ProfessionalLicense::withCount('expertises')
            ->when($request->type, fn($q, $t) => $q->where('type', $t))
            ->orderBy('note_moyenne', 'desc')
            ->paginate(20);

        return $this->paginatedResponse($cabinets->items(), $cabinets->total(), $cabinets->currentPage(), $cabinets->perPage());
    }

    // ─── Revenus par cabinet ─────────────────────────────────────────────────
    public function revenusCabinets()
    {
        $revenus = RevenueShare::with('professional')
            ->select('professional_license_id', DB::raw('SUM(part_professionnel) as total_cabinet'), DB::raw('COUNT(*) as nb_services'))
            ->groupBy('professional_license_id')
            ->orderBy('total_cabinet', 'desc')
            ->limit(20)
            ->get()
            ->map(fn($r) => [
                'cabinet'       => $r->professional ? $r->professional->nom_cabinet : 'N/A',
                'type'          => $r->professional ? $r->professional->type : 'N/A',
                'total_cabinet' => $r->total_cabinet,
                'nb_services'   => $r->nb_services,
            ]);

        return $this->successResponse($revenus);
    }
}
