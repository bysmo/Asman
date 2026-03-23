<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('nom');
            $table->string('prenom');
            $table->string('email')->unique();
            $table->string('telephone')->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->enum('role', ['client', 'notaire', 'huissier', 'avocat', 'admin'])->default('client');
            $table->enum('statut', ['actif', 'inactif', 'suspendu'])->default('actif');
            $table->string('pays')->default('BF');
            $table->string('devise')->default('XOF');
            $table->string('langue')->default('fr');
            $table->string('photo')->nullable();
            $table->string('pin_hash')->nullable();
            $table->boolean('pin_enabled')->default(false);
            $table->string('otp_code')->nullable();
            $table->timestamp('otp_expires_at')->nullable();
            $table->boolean('otp_verified')->default(false);
            // KYC
            $table->enum('kyc_statut', ['non_soumis', 'en_attente', 'approuve', 'rejete'])->default('non_soumis');
            $table->timestamp('kyc_date')->nullable();
            $table->string('kyc_niveau')->nullable(); // basique, standard, avance
            $table->string('numero_piece')->nullable();
            $table->enum('type_piece', ['cni', 'passeport', 'permis', 'autre'])->nullable();
            $table->date('date_naissance')->nullable();
            $table->string('lieu_naissance')->nullable();
            $table->string('adresse')->nullable();
            $table->string('ville')->nullable();
            $table->string('province')->nullable();
            $table->string('region')->nullable();
            // Professionnel (notaire, huissier, avocat)
            $table->string('numero_professionnel')->nullable();
            $table->string('ordre_professionnel')->nullable();
            $table->string('cabinet')->nullable();
            $table->string('juridiction')->nullable();
            $table->rememberToken();
            $table->timestamps();
            $table->softDeletes();
        });
    }
    public function down(): void { Schema::dropIfExists('users'); }
};
