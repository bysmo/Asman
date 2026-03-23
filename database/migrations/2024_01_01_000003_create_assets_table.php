<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('assets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('nom');
            $table->enum('type', [
                'immobilier', 'parcelle', 'vehicule', 'investissement',
                'creance', 'dette', 'compte_bancaire', 'bijou',
                'oeuvre_art', 'entreprise', 'autre'
            ]);
            $table->enum('statut', ['actif', 'loue', 'vendu', 'inactif'])->default('actif');
            $table->decimal('valeur_actuelle', 15, 2)->default(0);
            $table->decimal('valeur_initiale', 15, 2)->default(0);
            $table->text('description')->nullable();
            $table->string('devise')->default('XOF');
            $table->string('pays')->default('BF');
            $table->date('date_acquisition')->nullable();
            $table->date('date_derniere_evaluation')->nullable();

            // Localisation (immobilier / parcelle)
            $table->string('adresse')->nullable();
            $table->string('ville')->nullable();
            $table->string('commune')->nullable();
            $table->string('village')->nullable();
            $table->string('province')->nullable();
            $table->string('region')->nullable();
            $table->string('lot')->nullable();
            $table->string('section')->nullable();
            $table->string('numero_parcelle')->nullable();
            $table->decimal('superficie', 15, 4)->nullable(); // m²
            $table->json('coordonnees_gps')->nullable(); // polygone délimitant la parcelle

            // Véhicule
            $table->string('immatriculation')->nullable();
            $table->string('marque')->nullable();
            $table->string('modele')->nullable();
            $table->integer('annee')->nullable();
            $table->string('numero_chassis')->nullable();
            $table->string('couleur')->nullable();

            // Investissement / Compte
            $table->string('numero_titre')->nullable();
            $table->string('etablissement')->nullable();
            $table->string('iban')->nullable();
            $table->enum('type_compte', ['courant', 'epargne', 'dat', 'titres', 'autre'])->nullable();
            $table->decimal('solde', 15, 2)->nullable();

            // Location
            $table->boolean('est_loue')->default(false);
            $table->decimal('loyer_mensuel', 15, 2)->nullable();
            $table->string('locataire')->nullable();
            $table->date('date_fin_bail')->nullable();

            // Certification
            $table->enum('certification_statut', [
                'non_demande', 'en_attente', 'en_cours', 'certifie', 'refuse'
            ])->default('non_demande');
            $table->string('certification_id')->nullable();
            $table->string('certification_autorite_nom')->nullable();
            $table->date('date_certification')->nullable();

            // Marketplace
            $table->boolean('en_vente')->default(false);
            $table->boolean('en_location')->default(false);
            $table->decimal('prix_vente', 15, 2)->nullable();
            $table->decimal('prix_location', 15, 2)->nullable();

            $table->json('photos')->nullable();
            $table->json('details')->nullable(); // champs supplémentaires

            $table->timestamps();
            $table->softDeletes();
        });
    }
    public function down(): void { Schema::dropIfExists('assets'); }
};
