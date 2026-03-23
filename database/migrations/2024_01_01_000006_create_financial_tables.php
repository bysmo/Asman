<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {

        // Comptes bancaires
        Schema::create('comptes_bancaires', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('nom');
            $table->string('banque');
            $table->string('iban')->nullable();
            $table->string('numero_compte')->nullable();
            $table->string('swift_bic')->nullable();
            $table->enum('type', ['courant', 'epargne', 'dat', 'titres', 'autre'])->default('courant');
            $table->decimal('solde', 15, 2)->default(0);
            $table->string('devise')->default('XOF');
            $table->string('pays')->default('BF');
            $table->enum('statut', ['actif', 'inactif', 'ferme'])->default('actif');
            $table->date('date_ouverture')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        // Transactions bancaires
        Schema::create('transactions_bancaires', function (Blueprint $table) {
            $table->id();
            $table->foreignId('compte_id')->constrained('comptes_bancaires')->onDelete('cascade');
            $table->enum('type', ['credit', 'debit']);
            $table->decimal('montant', 15, 2);
            $table->string('libelle');
            $table->text('description')->nullable();
            $table->date('date_transaction');
            $table->decimal('solde_apres', 15, 2)->nullable();
            $table->timestamps();
        });

        // Créances (argent dû à l'utilisateur)
        Schema::create('creances', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('nom_debiteur');
            $table->string('contact_debiteur')->nullable();
            $table->decimal('montant_initial', 15, 2);
            $table->decimal('montant_restant', 15, 2);
            $table->decimal('taux_interet', 5, 2)->default(0);
            $table->string('devise')->default('XOF');
            $table->date('date_pret');
            $table->date('date_echeance');
            $table->enum('statut', ['en_cours', 'partiellement_rembourse', 'rembourse', 'en_litige', 'perdu'])->default('en_cours');
            $table->text('description')->nullable();
            $table->string('garantie')->nullable();
            $table->json('documents')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        // Dettes (argent que l'utilisateur doit)
        Schema::create('dettes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('nom_creancier');
            $table->string('contact_creancier')->nullable();
            $table->decimal('montant_initial', 15, 2);
            $table->decimal('montant_restant', 15, 2);
            $table->decimal('taux_interet', 5, 2)->default(0);
            $table->string('devise')->default('XOF');
            $table->date('date_emprunt');
            $table->date('date_echeance');
            $table->enum('statut', ['en_cours', 'partiellement_rembourse', 'rembourse', 'en_defaut'])->default('en_cours');
            $table->text('description')->nullable();
            $table->string('garantie')->nullable();
            $table->json('documents')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        // Remboursements (créances et dettes)
        Schema::create('remboursements', function (Blueprint $table) {
            $table->id();
            $table->nullableMorphs('remboursable'); // creance ou dette
            $table->decimal('montant', 15, 2);
            $table->date('date_remboursement');
            $table->string('mode_paiement')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }
    public function down(): void {
        Schema::dropIfExists('remboursements');
        Schema::dropIfExists('dettes');
        Schema::dropIfExists('creances');
        Schema::dropIfExists('transactions_bancaires');
        Schema::dropIfExists('comptes_bancaires');
    }
};
