<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\SubscriptionPlan;
use App\Models\Subscription;
use App\Models\AsmanScore;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class SubscriptionController extends Controller
{
    // ─── Lister les plans disponibles ────────────────────────────────────────
    public function plans()
    {
        $plans = SubscriptionPlan::where('is_active', true)
            ->orderBy('monthly_price')
            ->get()
            ->map(fn($p) => $this->formatPlan($p));

        return $this->successResponse($plans, 'Plans récupérés');
    }

    // ─── Abonnement courant de l'utilisateur ─────────────────────────────────
    public function current(Request $request)
    {
        $user = $request->user();
        $subscription = Subscription::with('plan')
            ->where('user_id', $user->id)
            ->where('statut', 'actif')
            ->where('date_fin', '>', now())
            ->first();

        return $this->successResponse([
            'has_subscription' => !is_null($subscription),
            'subscription' => $subscription ? $this->formatSubscription($subscription) : null,
            'tier' => $subscription ? $subscription->plan->slug : 'decouverte',
        ]);
    }

    // ─── Souscrire à un plan ──────────────────────────────────────────────────
    public function subscribe(Request $request)
    {
        $request->validate([
            'plan_slug'       => 'required|string|exists:subscription_plans,slug',
            'billing_period'  => 'required|in:mensuel,annuel',
            'payment_method'  => 'required|in:mobile_money,carte,virement',
            'payment_ref'     => 'required|string',
        ]);

        $user = $request->user();
        $plan = SubscriptionPlan::where('slug', $request->plan_slug)->firstOrFail();

        if ($plan->slug === 'decouverte') {
            return $this->errorResponse('Le plan Découverte est gratuit', 422);
        }

        $price = $request->billing_period === 'annuel'
            ? $plan->annual_price
            : $plan->monthly_price;

        DB::beginTransaction();
        try {
            // Annuler l'abonnement actif s'il existe
            Subscription::where('user_id', $user->id)
                ->where('statut', 'actif')
                ->update(['statut' => 'annule']);

            $dateDebut = now();
            $dateFin = $request->billing_period === 'annuel'
                ? $dateDebut->copy()->addYear()
                : $dateDebut->copy()->addMonth();

            $subscription = Subscription::create([
                'user_id'           => $user->id,
                'subscription_plan_id' => $plan->id,
                'billing_period'    => $request->billing_period,
                'date_debut'        => $dateDebut,
                'date_fin'          => $dateFin,
                'montant_paye'      => $price,
                'statut'            => 'actif',
                'payment_method'    => $request->payment_method,
                'payment_reference' => $request->payment_ref,
                'auto_renew'        => true,
            ]);

            DB::commit();
            return $this->successResponse(
                $this->formatSubscription($subscription->load('plan')),
                'Abonnement activé avec succès'
            );
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Erreur lors de la souscription: ' . $e->getMessage(), 500);
        }
    }

    // ─── Résilier l'abonnement ────────────────────────────────────────────────
    public function cancel(Request $request)
    {
        $subscription = Subscription::where('user_id', $request->user()->id)
            ->where('statut', 'actif')
            ->first();

        if (!$subscription) {
            return $this->errorResponse('Aucun abonnement actif', 404);
        }

        $subscription->update(['statut' => 'annule', 'auto_renew' => false]);
        return $this->successResponse(null, 'Abonnement résilié');
    }

    // ─── Vérifier les droits d'accès à une fonctionnalité ────────────────────
    public function checkFeature(Request $request, string $feature)
    {
        $user = $request->user();
        $tier = $this->getUserTier($user);
        $plan = SubscriptionPlan::where('slug', $tier)->first();

        $hasAccess = false;
        $features  = $plan ? ($plan->features ?? []) : [];

        $featureMap = [
            'marketplace_priority'      => ['premium', 'elite', 'family'],
            'certification_prioritaire' => ['premium', 'elite', 'family'],
            'conseiller_financier'      => ['premium', 'elite', 'family'],
            'expertise_illimitee'       => ['elite', 'family'],
            'rapport_mensuel'           => ['premium', 'elite', 'family'],
            'asman_score'               => ['standard', 'premium', 'elite', 'family'],
        ];

        $allowedTiers = $featureMap[$feature] ?? [];
        $hasAccess = in_array($tier, $allowedTiers);

        return $this->successResponse([
            'feature'    => $feature,
            'has_access' => $hasAccess,
            'tier'       => $tier,
            'upgrade_to' => $hasAccess ? null : ($allowedTiers[0] ?? 'standard'),
        ]);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────
    private function getUserTier($user): string
    {
        $sub = Subscription::with('plan')
            ->where('user_id', $user->id)
            ->where('statut', 'actif')
            ->where('date_fin', '>', now())
            ->first();
        return $sub ? $sub->plan->slug : 'decouverte';
    }

    private function formatPlan(SubscriptionPlan $plan): array
    {
        return [
            'id'             => $plan->id,
            'slug'           => $plan->slug,
            'nom'            => $plan->nom,
            'description'    => $plan->description,
            'monthly_price'  => $plan->monthly_price,
            'annual_price'   => $plan->annual_price,
            'currency'       => 'XOF',
            'features'       => $plan->features ?? [],
            'limits'         => $plan->limits ?? [],
            'badge_color'    => $this->getBadgeColor($plan->slug),
            'is_popular'     => $plan->slug === 'premium',
        ];
    }

    private function formatSubscription(Subscription $sub): array
    {
        return [
            'id'             => $sub->id,
            'plan'           => $this->formatPlan($sub->plan),
            'billing_period' => $sub->billing_period,
            'date_debut'     => $sub->date_debut,
            'date_fin'       => $sub->date_fin,
            'days_remaining' => now()->diffInDays($sub->date_fin, false),
            'montant_paye'   => $sub->montant_paye,
            'statut'         => $sub->statut,
            'auto_renew'     => $sub->auto_renew,
        ];
    }

    private function getBadgeColor(string $slug): string
    {
        return match($slug) {
            'standard' => '#78909C',
            'premium'  => '#FFB300',
            'elite'    => '#7B1FA2',
            'family'   => '#2E7D32',
            default    => '#9E9E9E',
        };
    }
}
