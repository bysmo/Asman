<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('loyers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('asset_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('locataire');
            $table->string('contact_locataire')->nullable();
            $table->decimal('montant', 15, 2);
            $table->string('devise')->default('XOF');
            $table->enum('periodicite', ['mensuel', 'trimestriel', 'semestriel', 'annuel'])->default('mensuel');
            $table->date('date_debut');
            $table->date('date_fin')->nullable();
            $table->date('date_echeance');
            $table->boolean('est_paye')->default(false);
            $table->date('date_paiement')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });

        Schema::create('marketplace_listings', function (Blueprint $table) {
            $table->id();
            $table->string('reference')->unique();
            $table->foreignId('asset_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['vente', 'location']);
            $table->enum('statut', ['actif', 'suspendu', 'cloture', 'vendu'])->default('actif');
            $table->decimal('prix', 15, 2);
            $table->string('devise')->default('XOF');
            $table->text('description')->nullable();
            $table->json('photos')->nullable();
            $table->boolean('negociable')->default(false);
            $table->timestamp('date_expiration')->nullable();
            $table->integer('vues')->default(0);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('evaluations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('asset_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('evaluateur_id')->nullable()->constrained('users');
            $table->decimal('valeur_precedente', 15, 2);
            $table->decimal('valeur_nouvelle', 15, 2);
            $table->string('devise')->default('XOF');
            $table->string('methode')->nullable();
            $table->text('justification')->nullable();
            $table->json('documents')->nullable();
            $table->timestamps();
        });

        Schema::create('liquidations', function (Blueprint $table) {
            $table->id();
            $table->string('reference')->unique();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('testament_id')->nullable()->constrained()->onDelete('set null');
            $table->enum('type', ['succession', 'donation', 'vente', 'autre'])->default('succession');
            $table->enum('mode', ['manuel', 'automatique'])->default('manuel');
            $table->enum('statut', ['en_attente', 'en_cours', 'execute', 'annule'])->default('en_attente');
            $table->json('assets_concernes')->nullable();
            $table->decimal('valeur_totale', 15, 2)->default(0);
            $table->text('notes')->nullable();
            $table->foreignId('traite_par')->nullable()->constrained('users');
            $table->timestamp('date_execution')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('revenue_shares', function (Blueprint $table) {
            $table->id();
            $table->foreignId('certification_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('autorite_id')->constrained('users')->onDelete('cascade');
            $table->decimal('montant_total', 15, 2);
            $table->decimal('montant_autorite', 15, 2); // 70%
            $table->decimal('montant_plateforme', 15, 2); // 30%
            $table->string('devise')->default('XOF');
            $table->enum('statut', ['en_attente', 'distribue'])->default('en_attente');
            $table->timestamp('date_distribution')->nullable();
            $table->timestamps();
        });
    }
    public function down(): void {
        Schema::dropIfExists('revenue_shares');
        Schema::dropIfExists('liquidations');
        Schema::dropIfExists('evaluations');
        Schema::dropIfExists('marketplace_listings');
        Schema::dropIfExists('loyers');
    }
};
