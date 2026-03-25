<?php
namespace App\Services;

use App\Models\User;
use App\Models\Subscription;
use App\Models\SubscriptionPlan;
use App\Models\PlatformRevenue;
use Illuminate\Support\Facades\DB;

class SubscriptionService
{
    /** Retourne le plan actif de l'utilisateur (ou 'decouverte' si aucun) */
    public function getUserPlan(User $user): SubscriptionPlan
    {
        $sub = Subscription::where('user_id', $user->id)
            ->where('statut', Subscription::ACTIVE)
            ->where('expire_le', '>', now())
            ->with('plan')
            ->latest('expire_le')
            ->first();

        if ($sub?->plan) return $sub->plan;

        return SubscriptionPlan::where('code', SubscriptionPlan::DECOUVERTE)->firstOrFail();
    }

    /** Vérifie si l'utilisateur a accès à une fonctionnalité selon son plan */
    public function hasFeature(User $user, string $feature): bool
    {
        $plan = $this->getUserPlan($user);
        return match($feature) {
            'kyc'                    => true,
            'unlimited_assets'       => $plan->max_actifs === -1,
            'marketplace_realtime'   => $plan->marketplace_delay_days === 0,
            'conseiller_financier'   => $plan->has_conseiller_financier,
            'expert_dedie'           => $plan->has_expert_dedie,
            'simulation_succession'  => $plan->has_simulation_succession,
            'multi_pays'             => $plan->max_pays > 1,
            'vault'                  => $plan->vault_storage_gb > 0,
            'famille'                => $plan->max_membres_famille > 0,
            default                  => false,
        };
    }

    /** Calcule le montant avec remise selon le plan */
    public function appliquerRemise(User $user, float $montantBase): array
    {
        $plan   = $this->getUserPlan($user);
        $remise = $plan->remise_services_pct;
        $montantRemise = round($montantBase * $remise / 100, 2);
        $montantTtc    = $montantBase - $montantRemise;

        return [
            'montant_ht'     => $montantBase,
            'taux_remise'    => $remise,
            'montant_remise' => $montantRemise,
            'montant_ttc'    => $montantTtc,
            'plan_code'      => $plan->code,
        ];
    }

    /** Souscrire à un plan */
    public function souscrire(User $user, SubscriptionPlan $plan, string $periodicite, string $methodePaiement, string $refPaiement): Subscription
    {
        return DB::transaction(function () use ($user, $plan, $periodicite, $methodePaiement, $refPaiement) {
            // Annuler l'abonnement actif existant
            Subscription::where('user_id', $user->id)
                ->where('statut', Subscription::ACTIVE)
                ->update(['statut' => Subscription::CANCELLED]);

            $montant = $periodicite === 'annuel' ? $plan->prix_annuel : $plan->prix_mensuel;
            $duree   = $periodicite === 'annuel' ? 365 : 30;

            $sub = Subscription::create([
                'user_id'              => $user->id,
                'subscription_plan_id' => $plan->id,
                'statut'               => Subscription::ACTIVE,
                'periodicite'          => $periodicite,
                'montant_paye'         => $montant,
                'devise'               => $plan->devise,
                'debut_le'             => now(),
                'expire_le'            => now()->addDays($duree),
                'methode_paiement'     => $methodePaiement,
                'reference_paiement'   => $refPaiement,
                'renouvellement_auto'  => true,
            ]);

            // Enregistrer le revenu plateforme
            \App\Models\PlatformRevenue::create([
                'source_type'             => 'subscription',
                'source_id'               => $sub->id,
                'description'             => "Abonnement {$plan->nom} - {$periodicite}",
                'montant_brut'            => $montant,
                'montant_net_plateforme'  => $montant, // 100% pour la plateforme sur abonnements
                'montant_professionnel'   => 0,
                'montant_fonds_garantie'  => 0,
                'devise'                  => $plan->devise,
                'encaisse_le'             => now(),
            ]);

            return $sub;
        });
    }

    /** Données d'abonnement formatées pour l'API */
    public function formatSubscription(User $user): array
    {
        $plan     = $this->getUserPlan($user);
        $activeSub = Subscription::where('user_id', $user->id)
            ->where('statut', Subscription::ACTIVE)
            ->where('expire_le', '>', now())
            ->latest('expire_le')
            ->first();

        return [
            'plan'              => [
                'code'                    => $plan->code,
                'nom'                     => $plan->nom,
                'prix_mensuel'            => (float) $plan->prix_mensuel,
                'prix_annuel'             => (float) $plan->prix_annuel,
                'remise_services_pct'     => (float) $plan->remise_services_pct,
                'marketplace_delay_days'  => $plan->marketplace_delay_days,
                'certification_delay_hours' => $plan->certification_delay_hours,
                'max_actifs'              => $plan->max_actifs,
                'max_comptes'             => $plan->max_comptes,
                'max_reevaluations_annuelles' => $plan->max_reevaluations_annuelles,
                'has_conseiller_financier'=> $plan->has_conseiller_financier,
                'sessions_conseiller_trimestre' => $plan->sessions_conseiller_trimestre,
                'has_expert_dedie'        => $plan->has_expert_dedie,
                'vault_storage_gb'        => $plan->vault_storage_gb,
                'has_simulation_succession' => $plan->has_simulation_succession,
                'max_pays'                => $plan->max_pays,
                'max_membres_famille'     => $plan->max_membres_famille,
                'support_level'           => $plan->support_level,
                'rapport_frequence'       => $plan->rapport_frequence,
                'features'                => $plan->features ?? [],
            ],
            'abonnement'        => $activeSub ? [
                'statut'          => $activeSub->statut,
                'periodicite'     => $activeSub->periodicite,
                'debut_le'        => $activeSub->debut_le?->toISOString(),
                'expire_le'       => $activeSub->expire_le?->toISOString(),
                'jours_restants'  => $activeSub->daysRemaining(),
                'renouvellement_auto' => $activeSub->renouvellement_auto,
            ] : null,
            'is_premium'        => in_array($plan->code, [SubscriptionPlan::PREMIUM, SubscriptionPlan::ELITE, SubscriptionPlan::FAMILLE]),
            'is_elite'          => in_array($plan->code, [SubscriptionPlan::ELITE, SubscriptionPlan::FAMILLE]),
        ];
    }
}
