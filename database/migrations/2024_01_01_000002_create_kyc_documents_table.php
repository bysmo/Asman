<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('kyc_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['piece_identite', 'justificatif_domicile', 'photo_selfie', 'autre']);
            $table->string('fichier');
            $table->string('nom_original')->nullable();
            $table->enum('statut', ['en_attente', 'approuve', 'rejete'])->default('en_attente');
            $table->text('commentaire')->nullable();
            $table->foreignId('verifie_par')->nullable()->constrained('users');
            $table->timestamp('verifie_le')->nullable();
            $table->timestamps();
        });
    }
    public function down(): void { Schema::dropIfExists('kyc_documents'); }
};
