<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('testaments', function (Blueprint $table) {
            $table->id();
            $table->string('reference')->unique();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('notaire_id')->nullable()->constrained('users');
            $table->enum('statut', ['brouillon', 'finalise', 'certifie', 'revoque'])->default('brouillon');
            $table->text('contenu')->nullable();
            $table->text('dispositions_speciales')->nullable();
            $table->text('clauses')->nullable();
            $table->string('temoin_1')->nullable();
            $table->string('temoin_2')->nullable();
            $table->date('date_redaction')->nullable();
            $table->date('date_certification')->nullable();
            $table->decimal('frais_certification', 15, 2)->default(0);
            $table->string('devise')->default('XOF');
            $table->json('fichiers')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('ayants_droit', function (Blueprint $table) {
            $table->id();
            $table->foreignId('testament_id')->constrained()->onDelete('cascade');
            $table->string('nom');
            $table->string('prenom');
            $table->string('email')->nullable();
            $table->string('telephone')->nullable();
            $table->string('lien_parente');
            $table->enum('type', ['heritier', 'legataire', 'ascendant', 'conjoint', 'autre']);
            $table->decimal('pourcentage', 5, 2)->default(0);
            $table->text('biens_specifiques')->nullable();
            $table->string('adresse')->nullable();
            $table->string('numero_piece')->nullable();
            $table->timestamps();
        });

        Schema::create('allocations_testament', function (Blueprint $table) {
            $table->id();
            $table->foreignId('testament_id')->constrained()->onDelete('cascade');
            $table->foreignId('asset_id')->constrained()->onDelete('cascade');
            $table->foreignId('ayant_droit_id')->constrained('ayants_droit')->onDelete('cascade');
            $table->decimal('pourcentage', 5, 2)->default(100);
            $table->text('conditions')->nullable();
            $table->timestamps();
        });
    }
    public function down(): void {
        Schema::dropIfExists('allocations_testament');
        Schema::dropIfExists('ayants_droit');
        Schema::dropIfExists('testaments');
    }
};
