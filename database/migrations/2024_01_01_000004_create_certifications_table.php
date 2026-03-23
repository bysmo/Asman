<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('certifications', function (Blueprint $table) {
            $table->id();
            $table->string('reference')->unique();
            $table->foreignId('asset_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('assigne_a')->nullable()->constrained('users');
            $table->enum('type_autorite', ['notaire', 'huissier', 'avocat', 'administration']);
            $table->enum('statut', [
                'en_attente', 'en_cours', 'documents_requis',
                'paiement_requis', 'certifie', 'refuse', 'annule'
            ])->default('en_attente');
            $table->text('notes')->nullable();
            $table->text('motif_refus')->nullable();
            $table->decimal('frais', 15, 2)->default(0);
            $table->string('devise_frais')->default('XOF');
            $table->enum('statut_paiement', ['non_paye', 'en_attente', 'paye'])->default('non_paye');
            $table->json('documents')->nullable();
            $table->timestamp('date_soumission')->nullable();
            $table->timestamp('date_traitement')->nullable();
            $table->timestamp('date_certification')->nullable();
            // Partage revenus
            $table->decimal('montant_autorite', 15, 2)->default(0); // 70%
            $table->decimal('montant_plateforme', 15, 2)->default(0); // 30%
            $table->timestamps();
            $table->softDeletes();
        });
    }
    public function down(): void { Schema::dropIfExists('certifications'); }
};
