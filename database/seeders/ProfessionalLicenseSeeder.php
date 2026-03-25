<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ProfessionalLicenseSeeder extends Seeder
{
    public function run(): void
    {
        $cabinets = [
            // ─── Notaires ────────────────────────────────────────────────────
            [
                'type'          => 'notaire',
                'nom_cabinet'   => 'Étude Notariale Ouédraogo & Associés',
                'responsable_nom' => 'Me Salif Ouédraogo',
                'numero_agrement' => 'NOT-BF-2018-001',
                'ville'         => 'Ouagadougou',
                'pays'          => 'BF',
                'telephone'     => '+226 25 31 45 67',
                'email'         => 'etude.ouedraogo@notaire.bf',
                'specialites'   => json_encode(['succession', 'immobilier', 'droit_des_affaires']),
                'tarif_base'    => 75000,
                'statut'        => 'actif',
                'note_moyenne'  => 4.8,
            ],
            [
                'type'          => 'notaire',
                'nom_cabinet'   => 'Cabinet Notarial Sawadogo',
                'responsable_nom' => 'Me Adama Sawadogo',
                'numero_agrement' => 'NOT-BF-2019-002',
                'ville'         => 'Bobo-Dioulasso',
                'pays'          => 'BF',
                'telephone'     => '+226 20 97 34 12',
                'email'         => 'cabinet.sawadogo@notaire.bf',
                'specialites'   => json_encode(['immobilier', 'mariage', 'succession']),
                'tarif_base'    => 65000,
                'statut'        => 'actif',
                'note_moyenne'  => 4.6,
            ],
            // ─── Huissiers ───────────────────────────────────────────────────
            [
                'type'          => 'huissier',
                'nom_cabinet'   => 'Étude Huissier Compaoré',
                'responsable_nom' => 'Me Rasmané Compaoré',
                'numero_agrement' => 'HUIS-BF-2020-001',
                'ville'         => 'Ouagadougou',
                'pays'          => 'BF',
                'telephone'     => '+226 25 36 78 90',
                'email'         => 'huissier.compaore@justice.bf',
                'specialites'   => json_encode(['signification', 'saisie', 'constat']),
                'tarif_base'    => 30000,
                'statut'        => 'actif',
                'note_moyenne'  => 4.5,
            ],
            // ─── Avocats ─────────────────────────────────────────────────────
            [
                'type'          => 'avocat',
                'nom_cabinet'   => 'Cabinet Juridique Traoré & Partners',
                'responsable_nom' => 'Me Fatima Traoré',
                'numero_agrement' => 'AVT-BF-2017-005',
                'ville'         => 'Ouagadougou',
                'pays'          => 'BF',
                'telephone'     => '+226 25 30 11 22',
                'email'         => 'cabinet.traore@avocat.bf',
                'specialites'   => json_encode(['droit_patrimonial', 'succession', 'contentieux']),
                'tarif_base'    => 50000,
                'statut'        => 'actif',
                'note_moyenne'  => 4.7,
            ],
            // ─── Experts immobiliers ──────────────────────────────────────────
            [
                'type'          => 'expert_immobilier',
                'nom_cabinet'   => 'Cabinet Expertise Immobilière BURKI-ESTIM',
                'responsable_nom' => 'Ing. Jean-Baptiste Kaboré',
                'numero_agrement' => 'EXP-IMM-BF-2021-001',
                'ville'         => 'Ouagadougou',
                'pays'          => 'BF',
                'telephone'     => '+226 25 44 55 66',
                'email'         => 'burki.estim@expertise.bf',
                'specialites'   => json_encode(['immobilier_residentiel', 'commercial', 'industriel', 'foncier']),
                'tarif_base'    => 50000,
                'statut'        => 'actif',
                'note_moyenne'  => 4.9,
            ],
            [
                'type'          => 'expert_immobilier',
                'nom_cabinet'   => 'WEST AFRICA VALUATION',
                'responsable_nom' => 'M. Moussa Diallo',
                'numero_agrement' => 'EXP-IMM-BF-2022-002',
                'ville'         => 'Bobo-Dioulasso',
                'pays'          => 'BF',
                'telephone'     => '+226 20 88 99 11',
                'email'         => 'info@waf-valuation.com',
                'specialites'   => json_encode(['foncier', 'rural', 'periurbain']),
                'tarif_base'    => 45000,
                'statut'        => 'actif',
                'note_moyenne'  => 4.4,
            ],
            // ─── Experts véhicules ────────────────────────────────────────────
            [
                'type'          => 'expert_vehicule',
                'nom_cabinet'   => 'AUTO-EXPERTISE BURKINA',
                'responsable_nom' => 'M. Issouf Nikiéma',
                'numero_agrement' => 'EXP-VEH-BF-2020-001',
                'ville'         => 'Ouagadougou',
                'pays'          => 'BF',
                'telephone'     => '+226 25 77 88 33',
                'email'         => 'auto.expertise@gmail.com',
                'specialites'   => json_encode(['vehicules_legers', 'engins', 'motos', 'sinistre']),
                'tarif_base'    => 25000,
                'statut'        => 'actif',
                'note_moyenne'  => 4.3,
            ],
            // ─── Experts financiers / investissement ──────────────────────────
            [
                'type'          => 'expert_financier',
                'nom_cabinet'   => 'SAHEL FINANCE CONSEIL',
                'responsable_nom' => 'Dr. Aïssata Belem',
                'numero_agrement' => 'CG-BF-2019-003',
                'ville'         => 'Ouagadougou',
                'pays'          => 'BF',
                'telephone'     => '+226 25 60 70 80',
                'email'         => 'contact@sahel-finance.bf',
                'specialites'   => json_encode(['investissement', 'bourse_regionale', 'gestion_portefeuille', 'succession']),
                'tarif_base'    => 75000,
                'statut'        => 'actif',
                'note_moyenne'  => 4.8,
            ],
        ];

        foreach ($cabinets as $cabinet) {
            DB::table('professional_licenses')->updateOrInsert(
                ['numero_agrement' => $cabinet['numero_agrement']],
                array_merge($cabinet, ['created_at' => now(), 'updated_at' => now()])
            );
        }

        $this->command->info('✅ Cabinets professionnels insérés (' . count($cabinets) . ')');
    }
}
