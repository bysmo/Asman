<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Admin principal
        User::updateOrCreate(
            ['email' => 'admin@asman.bf'],
            [
                'nom'       => 'Admin',
                'prenom'    => 'Asman',
                'email'     => 'admin@asman.bf',
                'password'  => Hash::make('Asman@2024!'),
                'role'      => 'admin',
                'statut'    => 'actif',
                'pays'      => 'BF',
                'devise'    => 'XOF',
                'kyc_statut' => 'approuve',
            ]
        );

        // Notaire test
        User::updateOrCreate(
            ['email' => 'notaire@asman.bf'],
            [
                'nom'                  => 'Ouédraogo',
                'prenom'               => 'Maître Kofi',
                'email'                => 'notaire@asman.bf',
                'password'             => Hash::make('Notaire@2024!'),
                'role'                 => 'notaire',
                'statut'               => 'actif',
                'pays'                 => 'BF',
                'devise'               => 'XOF',
                'kyc_statut'           => 'approuve',
                'numero_professionnel' => 'NOT-BF-001',
                'ordre_professionnel'  => 'Chambre des Notaires du Burkina Faso',
                'cabinet'              => 'Étude Notariale Ouédraogo',
                'juridiction'          => 'Ouagadougou',
            ]
        );

        // Huissier test
        User::updateOrCreate(
            ['email' => 'huissier@asman.bf'],
            [
                'nom'                  => 'Traoré',
                'prenom'               => 'Maître Aminata',
                'email'                => 'huissier@asman.bf',
                'password'             => Hash::make('Huissier@2024!'),
                'role'                 => 'huissier',
                'statut'               => 'actif',
                'pays'                 => 'BF',
                'devise'               => 'XOF',
                'kyc_statut'           => 'approuve',
                'numero_professionnel' => 'HUI-BF-001',
                'ordre_professionnel'  => 'Chambre des Huissiers du Burkina Faso',
                'juridiction'          => 'Bobo-Dioulasso',
            ]
        );

        // Avocat test
        User::updateOrCreate(
            ['email' => 'avocat@asman.bf'],
            [
                'nom'                  => 'Sawadogo',
                'prenom'               => 'Maître Ibrahim',
                'email'                => 'avocat@asman.bf',
                'password'             => Hash::make('Avocat@2024!'),
                'role'                 => 'avocat',
                'statut'               => 'actif',
                'pays'                 => 'BF',
                'devise'               => 'XOF',
                'kyc_statut'           => 'approuve',
                'numero_professionnel' => 'AVO-BF-001',
                'ordre_professionnel'  => 'Barreau du Burkina Faso',
                'juridiction'          => 'Ouagadougou',
            ]
        );

        // Client test
        User::updateOrCreate(
            ['email' => 'client@asman.bf'],
            [
                'nom'        => 'Kaboré',
                'prenom'     => 'Jean-Pierre',
                'email'      => 'client@asman.bf',
                'password'   => Hash::make('Client@2024!'),
                'role'       => 'client',
                'statut'     => 'actif',
                'pays'       => 'BF',
                'devise'     => 'XOF',
                'kyc_statut' => 'approuve',
                'telephone'  => '+22670000001',
                'ville'      => 'Ouagadougou',
                'province'   => 'Kadiogo',
                'region'     => 'Centre',
            ]
        );

        $this->command->info('✅ Utilisateurs de test créés :');
        $this->command->table(
            ['Rôle', 'Email', 'Mot de passe'],
            [
                ['Admin',    'admin@asman.bf',    'Asman@2024!'],
                ['Notaire',  'notaire@asman.bf',  'Notaire@2024!'],
                ['Huissier', 'huissier@asman.bf', 'Huissier@2024!'],
                ['Avocat',   'avocat@asman.bf',   'Avocat@2024!'],
                ['Client',   'client@asman.bf',   'Client@2024!'],
            ]
        );
    }
}
