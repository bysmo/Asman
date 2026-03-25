<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // ── Plans d'abonnement membres ────────────────────────────────────────
        Schema::create('subscription_plans', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();          // decouverte|standard|premium|elite|famille
            $table->string('nom');
            $table->text('description')->nullable();
            $table->decimal('prix_mensuel', 12, 2)->default(0);
            $table->decimal('prix_annuel',  12, 2)->default(0);
            $table->string('devise', 10)->default('XOF');
            $table->boolean('is_active')->default(true);
            $table->integer('max_actifs')->default(-1);         // -1 = illimité
            $table->integer('max_comptes')->default(1);
            $table->integer('max_publications_marketplace')->default(0);
            $table->integer('max_reevaluations_annuelles')->default(0);
            $table->integer('marketplace_delay_days')->default(30); // délai avant visibilité
            $table->integer('certification_delay_hours')->default(0); // 0=standard
            $table->decimal('remise_services_pct', 5, 2)->default(0); // % remise sur services
            $table->boolean('has_conseiller_financier')->default(false);
            $table->integer('sessions_conseiller_trimestre')->default(0);
            $table->boolean('has_expert_dedie')->default(false);
            $table->integer('vault_storage_gb')->default(0);
            $table->boolean('has_simulation_succession')->default(false);
            $table->integer('max_pays')->default(1);
            $table->integer('max_membres_famille')->default(0);
            $table->string('support_level')->default('faq'); // faq|email|chat|telephone
            $table->string('rapport_frequence')->default('none'); // none|trimestriel|mensuel|hebdomadaire
            $table->json('features')->nullable(); // features additionnelles en JSON
            $table->integer('ordre_affichage')->default(0);
            $table->timestamps();
        });

        // ── Abonnements membres ───────────────────────────────────────────────
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('subscription_plan_id')->constrained();
            $table->string('statut')->default('active'); // active|suspended|cancelled|expired
            $table->string('periodicite')->default('mensuel'); // mensuel|annuel
            $table->decimal('montant_paye', 12, 2);
            $table->string('devise', 10)->default('XOF');
            $table->timestamp('debut_le');
            $table->timestamp('expire_le');
            $table->timestamp('renouvele_le')->nullable();
            $table->boolean('renouvellement_auto')->default(true);
            $table->string('methode_paiement')->nullable(); // orange_money|moov_money|carte|virement
            $table->string('reference_paiement')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        // ── Licences professionnelles (cabinets) ──────────────────────────────
        Schema::create('professional_licenses', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('nom_cabinet');
            $table->string('type_cabinet'); // notaire|huissier|avocat|expert_immo|expert_general
            $table->string('specialites')->nullable(); // vehicule,entreprise,bijoux,art,agricole
            $table->string('plan'); // starter|business|enterprise
            $table->decimal('prix_mensuel', 12, 2);
            $table->string('devise', 10)->default('XOF');
            $table->string('statut')->default('pending'); // pending|active|suspended|expired
            $table->integer('max_professionnels')->default(1);
            $table->string('pays')->default('BF');
            $table->string('ville')->nullable();
            $table->string('adresse')->nullable();
            $table->string('telephone')->nullable();
            $table->string('email')->nullable();
            $table->string('numero_agrément')->nullable();
            $table->string('logo')->nullable();
            $table->decimal('commission_pct', 5, 2)->default(60); // % reversé au cabinet
            $table->boolean('badge_certifie')->default(false);
            $table->timestamp('debut_le')->nullable();
            $table->timestamp('expire_le')->nullable();
            $table->foreignId('validated_by')->nullable()->constrained('users');
            $table->timestamp('validated_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        // ── Professionnels membres d'un cabinet ───────────────────────────────
        Schema::create('professional_members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('professional_license_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('role')->default('member'); // owner|manager|member
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['professional_license_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('professional_members');
        Schema::dropIfExists('professional_licenses');
        Schema::dropIfExists('subscriptions');
        Schema::dropIfExists('subscription_plans');
    }
};
