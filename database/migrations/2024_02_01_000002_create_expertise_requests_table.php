<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // ── Demandes d'expertise & services professionnels ────────────────────
        Schema::create('expertise_requests', function (Blueprint $table) {
            $table->id();
            $table->string('reference')->unique(); // EXP-2024-001234
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('asset_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('professional_license_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('assigned_to')->nullable()->constrained('users')->onDelete('set null');

            // Type de service
            $table->string('type_service');
            // expertise_immobiliere|expertise_vehicule|expertise_entreprise|
            // expertise_bijoux|expertise_agricole|expertise_industrielle|
            // certification_notariale|constat_huissier|consultation_avocat|testament

            $table->string('sous_type')->nullable(); // villa|parcelle|camion|flotte|tpe|pme|bijoux|oeuvre...

            // Statut workflow
            $table->string('statut')->default('en_attente');
            // en_attente|assignee|en_cours|rapport_soumis|validee|livree|annulee|litigee

            // Tarification
            $table->decimal('montant_ht', 12, 2)->default(0);
            $table->decimal('taux_remise', 5, 2)->default(0);      // % remise plan membre
            $table->decimal('montant_remise', 12, 2)->default(0);
            $table->decimal('montant_ttc', 12, 2)->default(0);
            $table->string('devise', 10)->default('XOF');
            $table->boolean('est_paye')->default(false);
            $table->string('methode_paiement')->nullable();
            $table->string('reference_paiement')->nullable();
            $table->timestamp('paye_le')->nullable();

            // Revenue sharing calculé
            $table->decimal('part_professionnel', 12, 2)->default(0);
            $table->decimal('part_plateforme',    12, 2)->default(0);
            $table->decimal('part_fonds_garantie', 12, 2)->default(0);
            $table->decimal('part_superviseur',   12, 2)->default(0);
            $table->boolean('versement_effectue')->default(false);
            $table->timestamp('verse_le')->nullable();

            // Détails de la demande
            $table->text('description')->nullable();
            $table->text('notes_client')->nullable();
            $table->text('notes_professionnel')->nullable();
            $table->json('documents_client')->nullable();   // docs fournis par client
            $table->json('documents_rapport')->nullable();  // rapport + docs du pro
            $table->decimal('valeur_estimee', 15, 2)->nullable(); // résultat expertise
            $table->string('devise_estimee', 10)->default('XOF');
            $table->text('conclusion_rapport')->nullable();

            // Logistique
            $table->string('urgence')->default('normale'); // normale|prioritaire|express
            $table->timestamp('date_souhaitee')->nullable();
            $table->timestamp('date_assignee')->nullable();
            $table->timestamp('date_debut_expertise')->nullable();
            $table->timestamp('date_rendu')->nullable();
            $table->string('lieu_expertise')->nullable();
            $table->json('coordonnees_lieu')->nullable();

            // Évaluation / satisfaction
            $table->integer('note_client')->nullable(); // 1-5
            $table->text('avis_client')->nullable();
            $table->timestamp('evalue_le')->nullable();

            $table->timestamps();
            $table->softDeletes();

            $table->index(['user_id', 'statut']);
            $table->index(['professional_license_id', 'statut']);
            $table->index('type_service');
        });

        // ── Grille tarifaire des services ─────────────────────────────────────
        Schema::create('service_tarifs', function (Blueprint $table) {
            $table->id();
            $table->string('type_service');
            $table->string('sous_type')->nullable();
            $table->string('nom');
            $table->text('description')->nullable();
            $table->decimal('prix_base', 12, 2);
            $table->string('devise', 10)->default('XOF');
            $table->string('unite')->default('forfait'); // forfait|heure|pourcentage
            $table->decimal('pct_professionnel', 5, 2)->default(60);
            $table->decimal('pct_plateforme', 5, 2)->default(30);
            $table->decimal('pct_fonds', 5, 2)->default(5);
            $table->decimal('pct_superviseur', 5, 2)->default(5);
            $table->boolean('is_active')->default(true);
            $table->integer('duree_estimee_heures')->nullable();
            $table->timestamps();
        });

        // ── Asman Score ───────────────────────────────────────────────────────
        Schema::create('asman_scores', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->integer('score_total')->default(0);        // 0-1000
            $table->integer('score_diversification')->default(0); // /200
            $table->integer('score_certification')->default(0);   // /300
            $table->integer('score_liquidite')->default(0);       // /200
            $table->integer('score_documentation')->default(0);   // /150
            $table->integer('score_regularite')->default(0);      // /150
            $table->string('niveau')->default('bronze'); // bronze|argent|or|platine|diamant
            $table->text('recommandations')->nullable();
            $table->boolean('rapport_certifie')->default(false);
            $table->timestamp('calcule_le');
            $table->timestamp('expire_le')->nullable();
            $table->timestamps();
        });

        // ── Produits one-shot (Pack Héritage, Pack Divorce...) ────────────────
        Schema::create('product_orders', function (Blueprint $table) {
            $table->id();
            $table->string('reference')->unique();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('produit_code'); // pack_heritage|pack_divorce|pack_sci|pack_transmission|vault|score_certifie
            $table->string('nom_produit');
            $table->decimal('montant', 12, 2);
            $table->string('devise', 10)->default('XOF');
            $table->string('statut')->default('en_attente'); // en_attente|paye|en_cours|livre|rembourse
            $table->string('methode_paiement')->nullable();
            $table->string('reference_paiement')->nullable();
            $table->timestamp('paye_le')->nullable();
            $table->timestamp('livre_le')->nullable();
            $table->json('details')->nullable();
            $table->timestamps();
        });

        // ── Historique des revenus Asman (dashboard finances) ─────────────────
        Schema::create('platform_revenues', function (Blueprint $table) {
            $table->id();
            $table->string('source_type'); // subscription|expertise|marketplace|product|license
            $table->unsignedBigInteger('source_id');
            $table->string('description');
            $table->decimal('montant_brut', 12, 2);
            $table->decimal('montant_net_plateforme', 12, 2);
            $table->decimal('montant_professionnel', 12, 2)->default(0);
            $table->decimal('montant_fonds_garantie', 12, 2)->default(0);
            $table->string('devise', 10)->default('XOF');
            $table->timestamp('encaisse_le');
            $table->string('statut')->default('encaisse'); // encaisse|rembourse|litige
            $table->timestamps();
            $table->index(['source_type', 'source_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('platform_revenues');
        Schema::dropIfExists('product_orders');
        Schema::dropIfExists('asman_scores');
        Schema::dropIfExists('service_tarifs');
        Schema::dropIfExists('expertise_requests');
    }
};
