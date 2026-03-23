<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\RevenueShare;
use App\Models\Certification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RevenueController extends Controller
{
    public function summary()
    {
        $user = Auth::user();

        if (in_array($user->role, ['notaire', 'huissier', 'avocat'])) {
            $shares = RevenueShare::where('autorite_id', $user->id)->get();
            $certifications = Certification::where('assigne_a', $user->id)->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'role'                    => $user->role,
                    'total_certifications'    => $certifications->count(),
                    'certifications_certifiees' => $certifications->where('statut', 'certifie')->count(),
                    'revenus_total'           => $shares->sum('montant_autorite'),
                    'revenus_distribues'      => $shares->where('statut', 'distribue')->sum('montant_autorite'),
                    'revenus_en_attente'      => $shares->where('statut', 'en_attente')->sum('montant_autorite'),
                    'plateforme_total'        => $shares->sum('montant_plateforme'),
                ]
            ]);
        }

        if ($user->role === 'admin') {
            $allShares = RevenueShare::all();
            return response()->json([
                'success' => true,
                'data' => [
                    'total_revenus_plateforme' => $allShares->sum('montant_plateforme'),
                    'total_revenus_autorites'  => $allShares->sum('montant_autorite'),
                    'total_transactions'       => $allShares->count(),
                    'repartition_par_type'     => Certification::selectRaw(
                        'type_autorite, SUM(montant_autorite) as total_autorite, SUM(montant_plateforme) as total_plateforme, COUNT(*) as nb'
                    )->where('statut', 'certifie')
                     ->groupBy('type_autorite')
                     ->get(),
                ]
            ]);
        }

        return response()->json(['success' => false, 'message' => 'Accès non autorisé.'], 403);
    }

    public function transactions()
    {
        $user = Auth::user();
        $query = RevenueShare::with('certification.asset');

        if (in_array($user->role, ['notaire', 'huissier', 'avocat'])) {
            $query->where('autorite_id', $user->id);
        } elseif ($user->role !== 'admin') {
            return response()->json(['success' => false, 'message' => 'Accès non autorisé.'], 403);
        }

        return response()->json([
            'success' => true,
            'data'    => $query->orderByDesc('created_at')->paginate(20)
        ]);
    }
}
