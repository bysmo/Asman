<?php

namespace App\Console\Commands;

use App\Models\Liquidation;
use App\Models\Asset;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcessLiquidations extends Command
{
    protected $signature   = 'asman:process-liquidations';
    protected $description = 'Traiter les liquidations automatiques planifiées';

    public function handle(): int
    {
        $this->info('Traitement des liquidations automatiques...');

        $liquidations = Liquidation::where('type', 'automatique')
            ->where('statut', 'en_attente')
            ->where('date_declenchement', '<=', now())
            ->get();

        if ($liquidations->isEmpty()) {
            $this->info('Aucune liquidation à traiter.');
            return Command::SUCCESS;
        }

        $processed = 0;
        $errors    = 0;

        foreach ($liquidations as $liquidation) {
            try {
                DB::transaction(function () use ($liquidation) {
                    // Marquer les actifs comme vendus
                    foreach ($liquidation->assets as $asset) {
                        $asset->update([
                            'statut'         => Asset::STATUS_VENDU,
                            'liquidation_id' => $liquidation->id,
                        ]);
                    }

                    // Calculer la répartition
                    $reserve    = $liquidation->montant_total * config('asman.liquidation_reserve_rate', 0.10);
                    $aDistribuer = $liquidation->montant_total - $reserve;

                    $liquidation->update([
                        'statut'                => 'en_cours',
                        'montant_reserve'       => $reserve,
                        'montant_a_distribuer'  => $aDistribuer,
                        'traite_le'             => now(),
                    ]);
                });
                $processed++;
                Log::info("Liquidation #{$liquidation->id} traitée.");
            } catch (\Throwable $e) {
                $errors++;
                Log::error("Erreur liquidation #{$liquidation->id}: {$e->getMessage()}");
            }
        }

        $this->info("Traitées: {$processed} | Erreurs: {$errors}");
        return $errors > 0 ? Command::FAILURE : Command::SUCCESS;
    }
}
