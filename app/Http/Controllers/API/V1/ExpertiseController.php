<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\ExpertiseRequest;
use App\Models\ProfessionalLicense;
use App\Models\Asset;
use App\Models\RevenueShare;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ExpertiseController extends Controller
{
    // ─── Lister les cabinets d'expertise disponibles ─────────────────────────
    public function cabinets(Request $request)
    {
        $query = ProfessionalLicense::where('statut', 'actif');

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }
        if ($request->filled('ville')) {
            $query->where('ville', $request->ville);
        }

        $cabinets = $query->get()->map(fn($c) => $this->formatCabinet($c));
        return $this->successResponse($cabinets, 'Cabinets récupérés');
    }

    // ─── Créer une demande d'expertise ───────────────────────────────────────
    public function store(Request $request)
    {
        $request->validate([
            'asset_id'              => 'required|exists:assets,id',
            'type_expertise'        => 'required|in:immobilier,vehicule,investissement,judiciaire,succession',
            'professional_license_id' => 'nullable|exists:professional_licenses,id',
            'notes_client'          => 'nullable|string|max:1000',
            'urgence'               => 'boolean',
        ]);

        $user  = $request->user();
        $asset = Asset::where('id', $request->asset_id)
                      ->where('user_id', $user->id)
                      ->firstOrFail();

        // Calculer le tarif
        $tarif = $this->calculerTarif(
            $request->type_expertise,
            $asset->type,
            $user,
            $request->boolean('urgence')
        );

        $expertise = ExpertiseRequest::create([
            'reference'               => 'EXP-' . strtoupper(Str::random(8)),
            'user_id'                 => $user->id,
            'asset_id'                => $asset->id,
            'professional_license_id' => $request->professional_license_id,
            'type_expertise'          => $request->type_expertise,
            'statut'                  => 'en_attente',
            'montant_total'           => $tarif['total'],
            'commission_asman'        => $tarif['asman'],
            'commission_expert'       => $tarif['expert'],
            'commission_superviseur'  => $tarif['superviseur'],
            'notes_client'            => $request->notes_client,
            'urgence'                 => $request->boolean('urgence'),
        ]);

        return $this->successResponse(
            $this->formatExpertise($expertise->load(['asset', 'professional'])),
            'Demande d\'expertise créée',
            201
        );
    }

    // ─── Lister les demandes de l'utilisateur ────────────────────────────────
    public function index(Request $request)
    {
        $expertises = ExpertiseRequest::with(['asset', 'professional'])
            ->where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(fn($e) => $this->formatExpertise($e));

        return $this->successResponse($expertises);
    }

    // ─── Détail d'une expertise ───────────────────────────────────────────────
    public function show(Request $request, int $id)
    {
        $expertise = ExpertiseRequest::with(['asset', 'professional'])
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        return $this->successResponse($this->formatExpertise($expertise));
    }

    // ─── Expert: Valider / Soumettre le rapport ───────────────────────────────
    public function submitReport(Request $request, int $id)
    {
        $request->validate([
            'valeur_estimee' => 'required|numeric|min:0',
            'rapport_url'    => 'required|url',
            'notes_expert'   => 'nullable|string',
        ]);

        $expertise = ExpertiseRequest::findOrFail($id);

        DB::beginTransaction();
        try {
            $expertise->update([
                'statut'          => 'rapport_soumis',
                'valeur_estimee'  => $request->valeur_estimee,
                'rapport_url'     => $request->rapport_url,
                'notes_expert'    => $request->notes_expert,
                'date_rapport'    => now(),
            ]);

            // Mettre à jour la valeur de l'actif
            $expertise->asset->update([
                'valeur_actuelle' => $request->valeur_estimee,
                'derniere_evaluation' => now(),
            ]);

            // Enregistrer le partage de revenus
            RevenueShare::create([
                'expertise_request_id' => $expertise->id,
                'type_service'         => 'expertise',
                'montant_total'        => $expertise->montant_total,
                'part_asman'           => $expertise->commission_asman,
                'part_professionnel'   => $expertise->commission_expert,
                'part_superviseur'     => $expertise->commission_superviseur,
                'statut'               => 'en_attente_paiement',
            ]);

            DB::commit();
            return $this->successResponse(
                $this->formatExpertise($expertise->fresh()),
                'Rapport soumis avec succès'
            );
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->errorResponse('Erreur: ' . $e->getMessage(), 500);
        }
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────
    private function calculerTarif(string $typeExpertise, string $typeAsset, $user, bool $urgence): array
    {
        $tarifsBase = [
            'immobilier'    => 50000,
            'vehicule'      => 25000,
            'investissement' => 75000,
            'judiciaire'    => 100000,
            'succession'    => 150000,
        ];

        $base  = $tarifsBase[$typeExpertise] ?? 50000;
        $total = $urgence ? $base * 1.5 : $base;

        // Réduction selon tier
        $tier = $this->getUserTier($user);
        $reduction = match($tier) {
            'elite', 'family' => 0.20,
            'premium'          => 0.10,
            default            => 0,
        };
        $total = $total * (1 - $reduction);

        return [
            'total'       => round($total),
            'expert'      => round($total * 0.65),
            'asman'       => round($total * 0.30),
            'superviseur' => round($total * 0.05),
        ];
    }

    private function getUserTier($user): string
    {
        $sub = $user->subscriptions()
            ->with('plan')
            ->where('statut', 'actif')
            ->where('date_fin', '>', now())
            ->first();
        return $sub ? $sub->plan->slug : 'decouverte';
    }

    private function formatCabinet(ProfessionalLicense $c): array
    {
        return [
            'id'          => $c->id,
            'type'        => $c->type,
            'nom_cabinet' => $c->nom_cabinet,
            'responsable' => $c->responsable_nom,
            'ville'       => $c->ville,
            'telephone'   => $c->telephone,
            'email'       => $c->email,
            'specialites' => $c->specialites ?? [],
            'note_moyenne' => $c->note_moyenne ?? 0,
            'nb_expertises' => $c->expertises()->count(),
        ];
    }

    private function formatExpertise(ExpertiseRequest $e): array
    {
        return [
            'id'              => $e->id,
            'reference'       => $e->reference,
            'type_expertise'  => $e->type_expertise,
            'statut'          => $e->statut,
            'montant_total'   => $e->montant_total,
            'valeur_estimee'  => $e->valeur_estimee,
            'urgence'         => $e->urgence,
            'rapport_url'     => $e->rapport_url,
            'date_rapport'    => $e->date_rapport,
            'notes_client'    => $e->notes_client,
            'notes_expert'    => $e->notes_expert,
            'asset'           => $e->asset ? ['id' => $e->asset->id, 'nom' => $e->asset->nom, 'type' => $e->asset->type] : null,
            'cabinet'         => $e->professional ? $this->formatCabinet($e->professional) : null,
            'created_at'      => $e->created_at,
        ];
    }
}
