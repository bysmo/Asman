<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class SubscriptionPlanSeeder extends Seeder
{
    public function run(): void
    {
        $plans = [
            [
                'slug'         => 'decouverte',
                'nom'          => 'Découverte',
                'description'  => 'Découvrez Asman gratuitement. Idéal pour commencer.',
                'monthly_price' => 0,
                'annual_price'  => 0,
                'is_active'    => true,
                'features'     => json_encode([
                    '3 actifs maximum',
                    'Dashboard basique',
                    'Pas de KYC',
                    'Accès lecture marketplace',
                ]),
                'limits'       => json_encode([
                    'max_assets'          => 3,
                    'max_comptes'         => 1,
                    'reevaluations_year'  => 0,
                    'certifications_year' => 0,
                    'marketplace_delay'   => 14,
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'slug'         => 'standard',
                'nom'          => 'Standard',
                'description'  => 'Gestion complète de votre patrimoine avec certifications notariées.',
                'monthly_price' => 5000,
                'annual_price'  => 50000,
                'is_active'    => true,
                'features'     => json_encode([
                    'Actifs illimités',
                    'KYC complet',
                    '3 comptes bancaires liés',
                    'Marketplace (accès 7j après Elite)',
                    '2 réévaluations/an',
                    'Certification notariée standard',
                    'Testament basique (≤3 héritiers)',
                    'Asman Score',
                    'Support email',
                ]),
                'limits'       => json_encode([
                    'max_assets'          => -1,
                    'max_comptes'         => 3,
                    'reevaluations_year'  => 2,
                    'certifications_year' => 2,
                    'marketplace_delay'   => 7,
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'slug'         => 'premium',
                'nom'          => 'Premium',
                'description'  => 'Priorité sur tous les services + conseiller financier dédié.',
                'monthly_price' => 25000,
                'annual_price'  => 250000,
                'is_active'    => true,
                'features'     => json_encode([
                    'Tout Standard +',
                    'Comptes bancaires illimités',
                    'Marketplace prioritaire (7j avant Standard)',
                    '5 réévaluations/an',
                    'Certification prioritaire (<72h)',
                    'Testament avancé (héritiers illimités)',
                    'Confirmation vie multi-canal',
                    'Rapports PDF mensuels',
                    '2 séances conseil financier/trimestre',
                    'Badge Premium doré',
                    'Support chat & email 24h',
                ]),
                'limits'       => json_encode([
                    'max_assets'          => -1,
                    'max_comptes'         => -1,
                    'reevaluations_year'  => 5,
                    'certifications_year' => 5,
                    'marketplace_delay'   => 0,
                    'expertise_discount'  => 10,
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'slug'         => 'elite',
                'nom'          => 'Elite',
                'description'  => 'L\'expérience patrimoniale la plus complète. Gestionnaire dédié.',
                'monthly_price' => 100000,
                'annual_price'  => 1000000,
                'is_active'    => true,
                'features'     => json_encode([
                    'Tout Premium +',
                    'Marketplace exclusif (2 semaines avant Standard)',
                    'Réévaluations illimitées',
                    'Certification <24h',
                    'Gestionnaire de compte dédié',
                    'Conseil financier illimité',
                    'Assistance liquidation succession',
                    'Actifs multi-pays (UEMOA)',
                    'Rapports personnalisés',
                    'API white-label',
                    '3 comptes famille',
                    'Badge Elite violet',
                    'Support téléphone/WhatsApp direct',
                ]),
                'limits'       => json_encode([
                    'max_assets'          => -1,
                    'max_comptes'         => -1,
                    'reevaluations_year'  => -1,
                    'certifications_year' => -1,
                    'marketplace_delay'   => -14,
                    'expertise_discount'  => 20,
                    'family_accounts'     => 3,
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'slug'         => 'family',
                'nom'          => 'Family',
                'description'  => 'Un abonnement Elite pour toute la famille (jusqu\'à 5 membres).',
                'monthly_price' => 150000,
                'annual_price'  => 1500000,
                'is_active'    => true,
                'features'     => json_encode([
                    'Tout Elite +',
                    '5 comptes membres famille',
                    'Gestion patrimoine familial consolidée',
                    'Conseils succession conjoints',
                    'Badge Family vert',
                ]),
                'limits'       => json_encode([
                    'max_assets'          => -1,
                    'max_comptes'         => -1,
                    'reevaluations_year'  => -1,
                    'certifications_year' => -1,
                    'marketplace_delay'   => -14,
                    'expertise_discount'  => 20,
                    'family_accounts'     => 5,
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($plans as $plan) {
            DB::table('subscription_plans')->updateOrInsert(
                ['slug' => $plan['slug']],
                $plan
            );
        }

        $this->command->info('✅ Plans d\'abonnement insérés');
    }
}
