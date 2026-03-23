<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote')->hourly();

// Tâche planifiée : liquidations automatiques chaque nuit à minuit
Schedule::command('asman:process-liquidations')
    ->dailyAt('00:00')
    ->withoutOverlapping()
    ->appendOutputTo(storage_path('logs/liquidations.log'));

// Tâche : vérification des loyers en retard (tous les jours à 8h)
Schedule::command('asman:check-loyers-retard')
    ->dailyAt('08:00')
    ->withoutOverlapping();

// Tâche : rapports revenus hebdomadaires (chaque lundi)
Schedule::command('asman:weekly-revenue-report')
    ->weeklyOn(1, '07:00')
    ->withoutOverlapping();
