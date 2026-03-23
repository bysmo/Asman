<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Auth;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Admin\CertificationAdminController;
use App\Http\Controllers\Admin\LiquidationController;
use App\Http\Controllers\Admin\TestamentAdminController;
use App\Http\Controllers\Admin\RevenueAdminController;

/*
|--------------------------------------------------------------------------
| Web Routes - Interface Admin
|--------------------------------------------------------------------------
*/

Route::get('/', function () {
    return redirect()->route('admin.dashboard');
});

// Auth
Auth::routes(['register' => false]);

// Admin routes (protégés par auth + rôle)
Route::middleware(['auth', 'role:admin,notaire,huissier,avocat'])
    ->prefix('admin')
    ->name('admin.')
    ->group(function () {

        Route::get('dashboard',      [DashboardController::class, 'index'])->name('dashboard');

        // Utilisateurs (admin seulement)
        Route::middleware('role:admin')->group(function () {
            Route::resource('users', UserController::class);
            Route::post('users/{user}/activate',   [UserController::class, 'activate']);
            Route::post('users/{user}/deactivate', [UserController::class, 'deactivate']);
            Route::post('users/{user}/change-role', [UserController::class, 'changeRole']);
        });

        // Certifications
        Route::prefix('certifications')->name('certifications.')->group(function () {
            Route::get('/',                             [CertificationAdminController::class, 'index'])->name('index');
            Route::get('{certification}',               [CertificationAdminController::class, 'show'])->name('show');
            Route::post('{certification}/approuver',    [CertificationAdminController::class, 'approuver'])->name('approuver');
            Route::post('{certification}/rejeter',      [CertificationAdminController::class, 'rejeter'])->name('rejeter');
            Route::post('{certification}/assigner',     [CertificationAdminController::class, 'assigner'])->name('assigner');
        });

        // Liquidations
        Route::prefix('liquidations')->name('liquidations.')->group(function () {
            Route::get('/',                             [LiquidationController::class, 'index'])->name('index');
            Route::get('{liquidation}',                 [LiquidationController::class, 'show'])->name('show');
            Route::post('manuel',                       [LiquidationController::class, 'creerManuelle'])->name('creer');
            Route::post('{liquidation}/executer',       [LiquidationController::class, 'executer'])->name('executer');
            Route::post('{liquidation}/annuler',        [LiquidationController::class, 'annuler'])->name('annuler');
        });

        // Testaments
        Route::prefix('testaments')->name('testaments.')->group(function () {
            Route::get('/',                             [TestamentAdminController::class, 'index'])->name('index');
            Route::get('{testament}',                   [TestamentAdminController::class, 'show'])->name('show');
            Route::post('{testament}/certifier',        [TestamentAdminController::class, 'certifier'])->name('certifier');
        });

        // Revenus et partage
        Route::prefix('revenus')->name('revenus.')->group(function () {
            Route::get('/',                             [RevenueAdminController::class, 'index'])->name('index');
            Route::get('rapport',                       [RevenueAdminController::class, 'rapport'])->name('rapport');
            Route::post('distribuer',                   [RevenueAdminController::class, 'distribuer'])->name('distribuer');
        });
    });
