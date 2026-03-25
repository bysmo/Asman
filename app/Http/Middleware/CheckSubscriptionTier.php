<?php

namespace App\Http\Middleware;

use App\Models\Subscription;
use Closure;
use Illuminate\Http\Request;

class CheckSubscriptionTier
{
    /**
     * Vérifie que l'utilisateur possède le tier minimum requis.
     * Usage dans les routes : middleware('tier:premium')
     */
    public function handle(Request $request, Closure $next, string ...$allowedTiers)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['message' => 'Non authentifié', 'success' => false], 401);
        }

        $currentTier = $this->getUserTier($user);

        // 'decouverte' est toujours autorisé si pas de restriction
        if (empty($allowedTiers) || in_array($currentTier, $allowedTiers)) {
            // Injecter le tier dans la request pour usage dans les controllers
            $request->merge(['_user_tier' => $currentTier]);
            return $next($request);
        }

        $tierHierarchy = ['decouverte' => 0, 'standard' => 1, 'premium' => 2, 'elite' => 3, 'family' => 3];
        $userLevel    = $tierHierarchy[$currentTier] ?? 0;
        $minRequired  = min(array_map(fn($t) => $tierHierarchy[$t] ?? 99, $allowedTiers));

        if ($userLevel >= $minRequired) {
            $request->merge(['_user_tier' => $currentTier]);
            return $next($request);
        }

        $tierNames = [
            'standard' => 'Standard (5 000 XOF/mois)',
            'premium'  => 'Premium (25 000 XOF/mois)',
            'elite'    => 'Elite (100 000 XOF/mois)',
            'family'   => 'Family (150 000 XOF/mois)',
        ];

        $requiredTierName = $tierNames[$allowedTiers[0]] ?? $allowedTiers[0];

        return response()->json([
            'success'     => false,
            'message'     => 'Cette fonctionnalité nécessite un abonnement supérieur.',
            'error_code'  => 'SUBSCRIPTION_REQUIRED',
            'current_tier' => $currentTier,
            'required_tier' => $allowedTiers[0],
            'upgrade_url'  => '/api/v1/subscriptions/plans',
            'upgrade_message' => "Passez au plan {$requiredTierName} pour accéder à cette fonctionnalité.",
        ], 403);
    }

    private function getUserTier($user): string
    {
        $sub = Subscription::with('plan')
            ->where('user_id', $user->id)
            ->where('statut', 'actif')
            ->where('date_fin', '>', now())
            ->first();
        return $sub ? $sub->plan->slug : 'decouverte';
    }
}
