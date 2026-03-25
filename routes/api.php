<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\V1\AuthController;
use App\Http\Controllers\API\V1\AssetController;
use App\Http\Controllers\API\V1\CertificationController;
use App\Http\Controllers\API\V1\KycController;
use App\Http\Controllers\API\V1\TestamentController;
use App\Http\Controllers\API\V1\MarketplaceController;
use App\Http\Controllers\API\V1\CompteController;
use App\Http\Controllers\API\V1\CreanceController;
use App\Http\Controllers\API\V1\LoyerController;
use App\Http\Controllers\API\V1\EvaluationController;
use App\Http\Controllers\API\V1\RevenueController;
use App\Http\Controllers\API\V1\SubscriptionController;
use App\Http\Controllers\API\V1\ExpertiseController;
use App\Http\Controllers\API\V1\AsmanScoreController;

/*
|--------------------------------------------------------------------------
| API Routes - Version 1
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // ─── Auth (public) ───────────────────────────────────────────────────
    Route::prefix('auth')->group(function () {
        Route::post('register',          [AuthController::class, 'register']);
        Route::post('login',             [AuthController::class, 'login']);
        Route::post('forgot-password',   [AuthController::class, 'forgotPassword']);
        Route::post('reset-password',    [AuthController::class, 'resetPassword']);
        Route::post('verify-otp',        [AuthController::class, 'verifyOtp']);
        Route::post('resend-otp',        [AuthController::class, 'resendOtp']);
    });

    // ─── Authenticated routes ─────────────────────────────────────────────
    Route::middleware('auth:sanctum')->group(function () {

        // Auth
        Route::prefix('auth')->group(function () {
            Route::post('logout',        [AuthController::class, 'logout']);
            Route::get('me',             [AuthController::class, 'me']);
            Route::put('profile',        [AuthController::class, 'updateProfile']);
            Route::post('change-password', [AuthController::class, 'changePassword']);
            Route::post('setup-pin',     [AuthController::class, 'setupPin']);
            Route::post('verify-pin',    [AuthController::class, 'verifyPin']);
        });

        // KYC
        Route::prefix('kyc')->group(function () {
            Route::get('status',         [KycController::class, 'status']);
            Route::post('submit',        [KycController::class, 'submit']);
            Route::post('documents',     [KycController::class, 'uploadDocuments']);
        });

        // Assets
        Route::apiResource('assets', AssetController::class);
        Route::get('assets/types/list',  [AssetController::class, 'types']);
        Route::get('assets/stats/summary', [AssetController::class, 'stats']);
        Route::post('assets/{asset}/photos', [AssetController::class, 'uploadPhotos']);
        Route::delete('assets/{asset}/photos/{photo}', [AssetController::class, 'deletePhoto']);

        // Comptes bancaires
        Route::apiResource('comptes', CompteController::class);
        Route::post('comptes/{compte}/transactions', [CompteController::class, 'addTransaction']);
        Route::get('comptes/{compte}/transactions',  [CompteController::class, 'transactions']);

        // Créances & Dettes
        Route::apiResource('creances', CreanceController::class);
        Route::post('creances/{creance}/remboursements', [CreanceController::class, 'addRemboursement']);
        Route::apiResource('dettes', CreanceController::class); // same controller, type=dette

        // Loyers / Locations
        Route::prefix('loyers')->group(function () {
            Route::get('/',              [LoyerController::class, 'index']);
            Route::post('/',             [LoyerController::class, 'store']);
            Route::get('{loyer}',        [LoyerController::class, 'show']);
            Route::put('{loyer}',        [LoyerController::class, 'update']);
            Route::delete('{loyer}',     [LoyerController::class, 'destroy']);
            Route::post('{loyer}/payer', [LoyerController::class, 'marquerPaye']);
        });

        // Certifications
        Route::prefix('certifications')->group(function () {
            Route::get('/',              [CertificationController::class, 'index']);
            Route::post('/',             [CertificationController::class, 'store']);
            Route::get('{certification}', [CertificationController::class, 'show']);
            Route::post('{certification}/soumettre',  [CertificationController::class, 'soumettre']);
            Route::post('{certification}/approuver',  [CertificationController::class, 'approuver']);
            Route::post('{certification}/rejeter',    [CertificationController::class, 'rejeter']);
            Route::post('{certification}/documents',  [CertificationController::class, 'uploadDocuments']);
        });

        // Testaments
        Route::prefix('testaments')->group(function () {
            Route::get('/',              [TestamentController::class, 'index']);
            Route::post('/',             [TestamentController::class, 'store']);
            Route::get('{testament}',    [TestamentController::class, 'show']);
            Route::put('{testament}',    [TestamentController::class, 'update']);
            Route::delete('{testament}', [TestamentController::class, 'destroy']);
            Route::post('{testament}/finaliser',   [TestamentController::class, 'finaliser']);
            Route::post('{testament}/certifier',   [TestamentController::class, 'certifier']);
            Route::get('{testament}/ayants-droit', [TestamentController::class, 'ayantsDroit']);
            Route::post('{testament}/ayants-droit', [TestamentController::class, 'addAyantDroit']);
        });

        // Marketplace
        Route::prefix('marketplace')->group(function () {
            Route::get('/',              [MarketplaceController::class, 'index']);
            Route::post('/',             [MarketplaceController::class, 'store']);
            Route::get('{listing}',      [MarketplaceController::class, 'show']);
            Route::put('{listing}',      [MarketplaceController::class, 'update']);
            Route::delete('{listing}',   [MarketplaceController::class, 'destroy']);
            Route::post('{listing}/contact', [MarketplaceController::class, 'contact']);
            Route::post('{listing}/suspendre', [MarketplaceController::class, 'suspendre']);
        });

        // Évaluations
        Route::prefix('evaluations')->group(function () {
            Route::get('/',              [EvaluationController::class, 'index']);
            Route::post('/',             [EvaluationController::class, 'store']);
            Route::get('{evaluation}',   [EvaluationController::class, 'show']);
        });

        // Revenus / partage autorités
        Route::prefix('revenus')->group(function () {
            Route::get('summary',        [RevenueController::class, 'summary']);
            Route::get('transactions',   [RevenueController::class, 'transactions']);
        });

        // Dashboard stats
        Route::get('dashboard/stats',    [AssetController::class, 'dashboardStats']);

        // ─── Abonnements ─────────────────────────────────────────────────────
        Route::prefix('subscriptions')->group(function () {
            Route::get('plans',          [SubscriptionController::class, 'plans']);
            Route::get('current',        [SubscriptionController::class, 'current']);
            Route::post('subscribe',     [SubscriptionController::class, 'subscribe']);
            Route::post('cancel',        [SubscriptionController::class, 'cancel']);
            Route::get('feature/{feature}', [SubscriptionController::class, 'checkFeature']);
        });

        // ─── Expertise (cabinets: notaire/huissier/avocat/expert/comptable) ──
        Route::prefix('expertises')->group(function () {
            Route::get('cabinets',       [ExpertiseController::class, 'cabinets']);
            Route::get('/',              [ExpertiseController::class, 'index']);
            Route::post('/',             [ExpertiseController::class, 'store']);
            Route::get('{id}',           [ExpertiseController::class, 'show']);
            // Expert: soumettre rapport (réservé aux cabinets authentifiés)
            Route::post('{id}/rapport',  [ExpertiseController::class, 'submitReport'])
                ->middleware('role:expert|notaire|huissier|avocat');
        });

        // ─── Asman Score ─────────────────────────────────────────────────────
        Route::prefix('score')->middleware('tier:standard,premium,elite,family')->group(function () {
            Route::get('current',        [AsmanScoreController::class, 'current']);
            Route::post('recalculate',   [AsmanScoreController::class, 'recalculate']);
            Route::get('history',        [AsmanScoreController::class, 'history']);
            Route::get('leaderboard',    [AsmanScoreController::class, 'leaderboard']);
        });

        // ─── Fonctionnalités Premium+ ─────────────────────────────────────────
        Route::middleware('tier:premium,elite,family')->group(function () {
            Route::post('certifications/{certification}/prioritaire',
                [CertificationController::class, 'setPrioritaire']);
        });

        // ─── Fonctionnalités Elite/Family ────────────────────────────────────
        Route::middleware('tier:elite,family')->group(function () {
            Route::get('revenus/rapport-complet', [RevenueController::class, 'rapportComplet']);
        });
    });
});
