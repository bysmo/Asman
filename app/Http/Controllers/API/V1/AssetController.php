<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\Asset;
use App\Models\Evaluation;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class AssetController extends Controller
{
    // ─── LISTE DES ACTIFS ─────────────────────────────────────────────────────

    public function index(Request $request): JsonResponse
    {
        $query = Asset::where('user_id', $request->user()->id)
            ->withCount('certifications')
            ->with('certificationActive');

        if ($request->type) {
            $query->where('type', $request->type);
        }
        if ($request->statut) {
            $query->where('statut', $request->statut);
        }
        if ($request->search) {
            $query->where('nom', 'like', "%{$request->search}%");
        }

        $assets = $query->orderByDesc('created_at')->get();

        return $this->successResponse([
            'assets'  => $assets->map(fn($a) => $this->formatAsset($a)),
            'summary' => $this->getSummary($request->user()->id),
        ]);
    }

    // ─── DÉTAIL D'UN ACTIF ────────────────────────────────────────────────────

    public function show(Request $request, int $id): JsonResponse
    {
        $asset = Asset::where('user_id', $request->user()->id)
            ->with(['certificationActive', 'loyers', 'evaluations', 'marketplaceListings'])
            ->findOrFail($id);

        return $this->successResponse(['asset' => $this->formatAsset($asset, true)]);
    }

    // ─── CRÉER UN ACTIF ───────────────────────────────────────────────────────

    public function store(Request $request): JsonResponse
    {
        $rules = $this->getValidationRules($request->type);
        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $data = $request->only(array_keys($rules));
        $data['user_id']                = $request->user()->id;
        $data['certification_status']   = Asset::CERT_NON_DEMANDE;
        $data['details']                = $request->details ?? [];
        $data['photos']                 = $request->photos ?? [];

        // Champs spécifiques immobilier
        if ($request->type === Asset::TYPE_IMMOBILIER) {
            $data['coordonnees_gps']    = $request->coordonnees_gps ?? [];
            $data['adresse']            = $request->adresse;
            $data['ville']              = $request->ville;
            $data['commune']            = $request->commune;
            $data['village']            = $request->village;
            $data['province']           = $request->province;
            $data['region']             = $request->region;
            $data['superficie']         = $request->superficie;
            $data['superficie_unite']   = $request->superficie_unite ?? 'm2';
            $data['numero_lot']         = $request->numero_lot;
            $data['section_cadastrale'] = $request->section_cadastrale;
            $data['titre_foncier']      = $request->titre_foncier;
            $data['reference_cadastrale']= $request->reference_cadastrale;
            $data['type_propriete']     = $request->type_propriete;
        }

        // Champs spécifiques véhicule
        if ($request->type === Asset::TYPE_VEHICULE) {
            $data['marque']                 = $request->marque;
            $data['modele']                 = $request->modele;
            $data['annee_fabrication']      = $request->annee_fabrication;
            $data['numero_chassis']         = $request->numero_chassis;
            $data['numero_immatriculation'] = $request->numero_immatriculation;
            $data['couleur']                = $request->couleur;
            $data['carburant']              = $request->carburant;
            $data['kilometrage']            = $request->kilometrage;
        }

        // Champs spécifiques investissement
        if ($request->type === Asset::TYPE_INVESTISSEMENT) {
            $data['nom_societe']            = $request->nom_societe;
            $data['type_investissement']    = $request->type_investissement;
            $data['nombre_parts']           = $request->nombre_parts;
            $data['valeur_part']            = $request->valeur_part;
            $data['courtier']               = $request->courtier;
            $data['numero_compte_titre']    = $request->numero_compte_titre;
            $data['isin']                   = $request->isin;
        }

        $asset = Asset::create($data);

        return $this->successResponse(
            ['asset' => $this->formatAsset($asset)],
            'Actif créé avec succès.',
            201
        );
    }

    // ─── MODIFIER UN ACTIF ────────────────────────────────────────────────────

    public function update(Request $request, int $id): JsonResponse
    {
        $asset = Asset::where('user_id', $request->user()->id)->findOrFail($id);

        $updatable = [
            'nom', 'description', 'valeur_actuelle', 'valeur_initiale',
            'devise', 'pays', 'statut', 'est_loue', 'loyer_mensuel',
            'locataire', 'date_fin_bail', 'details', 'photos',
            // Immobilier
            'adresse', 'ville', 'commune', 'village', 'province', 'region',
            'superficie', 'superficie_unite', 'numero_lot', 'section_cadastrale',
            'coordonnees_gps', 'titre_foncier', 'reference_cadastrale', 'type_propriete',
            // Véhicule
            'marque', 'modele', 'annee_fabrication', 'numero_chassis',
            'numero_immatriculation', 'couleur', 'carburant', 'kilometrage',
            // Investissement
            'nom_societe', 'type_investissement', 'nombre_parts', 'valeur_part',
            'courtier', 'numero_compte_titre', 'isin',
        ];

        $asset->update($request->only($updatable));

        return $this->successResponse(
            ['asset' => $this->formatAsset($asset->fresh())],
            'Actif mis à jour.'
        );
    }

    // ─── SUPPRIMER UN ACTIF ───────────────────────────────────────────────────

    public function destroy(Request $request, int $id): JsonResponse
    {
        $asset = Asset::where('user_id', $request->user()->id)->findOrFail($id);

        if ($asset->certification_status === Asset::CERT_CERTIFIE) {
            return $this->errorResponse(
                'Un actif certifié ne peut pas être supprimé directement. Contactez un notaire.', 403
            );
        }

        $asset->delete();

        return $this->successResponse([], 'Actif supprimé.');
    }

    // ─── RÉÉVALUATION ─────────────────────────────────────────────────────────

    public function reevaluer(Request $request, int $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'valeur_nouvelle' => 'required|numeric|min:0',
            'notes'           => 'nullable|string|max:500',
            'methode'         => 'nullable|string|in:manuel,expert,marche',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $asset = Asset::where('user_id', $request->user()->id)->findOrFail($id);

        // Enregistrer l'historique d'évaluation
        Evaluation::create([
            'asset_id'          => $asset->id,
            'user_id'           => $request->user()->id,
            'valeur_precedente' => $asset->valeur_actuelle,
            'valeur_nouvelle'   => $request->valeur_nouvelle,
            'devise'            => $asset->devise,
            'methode_evaluation'=> $request->methode ?? 'manuel',
            'notes'             => $request->notes,
            'date_evaluation'   => now(),
            'source'            => 'mobile',
        ]);

        $asset->update([
            'valeur_actuelle'           => $request->valeur_nouvelle,
            'date_derniere_evaluation'  => now(),
        ]);

        return $this->successResponse(
            ['asset' => $this->formatAsset($asset->fresh())],
            'Réévaluation enregistrée.'
        );
    }

    // ─── RÉSUMÉ DU PATRIMOINE ─────────────────────────────────────────────────

    public function patrimoine(Request $request): JsonResponse
    {
        return $this->successResponse([
            'summary' => $this->getSummary($request->user()->id),
        ]);
    }

    // ─── MÉTHODES PRIVÉES ─────────────────────────────────────────────────────

    private function getSummary(int $userId): array
    {
        $assets = Asset::where('user_id', $userId)
            ->where('statut', '!=', Asset::STATUS_VENDU)
            ->get();

        $byType = $assets->groupBy('type')->map(fn($group) => [
            'count' => $group->count(),
            'total' => $group->sum('valeur_actuelle'),
        ]);

        $loyes = $assets->where('est_loue', true);

        return [
            'patrimoine_brut'       => $assets->sum('valeur_actuelle'),
            'revenus_locatifs'      => $loyes->sum('loyer_mensuel'),
            'nb_actifs'             => $assets->count(),
            'nb_certifies'          => $assets->where('certification_status', Asset::CERT_CERTIFIE)->count(),
            'nb_loues'              => $loyes->count(),
            'repartition_par_type'  => $byType,
        ];
    }

    private function formatAsset(Asset $asset, bool $detailed = false): array
    {
        $data = [
            'id'                    => $asset->id,
            'nom'                   => $asset->nom,
            'type'                  => $asset->type,
            'statut'                => $asset->statut,
            'description'           => $asset->description,
            'valeur_actuelle'       => (float) $asset->valeur_actuelle,
            'valeur_initiale'       => (float) $asset->valeur_initiale,
            'plus_value'            => (float) $asset->plus_value,
            'plus_value_pct'        => round((float) $asset->plus_value_pct, 2),
            'devise'                => $asset->devise,
            'pays'                  => $asset->pays,
            'date_acquisition'      => $asset->date_acquisition?->toDateString(),
            'date_derniere_evaluation' => $asset->date_derniere_evaluation?->toDateString(),
            'certification_status'  => $asset->certification_status,
            'est_certifie'          => $asset->est_certifie,
            'est_loue'              => $asset->est_loue,
            'loyer_mensuel'         => $asset->loyer_mensuel ? (float) $asset->loyer_mensuel : null,
            'locataire'             => $asset->locataire,
            'date_fin_bail'         => $asset->date_fin_bail?->toDateString(),
            'en_vente'              => $asset->en_vente,
            'en_location'           => $asset->en_location,
            'photos'                => $asset->photos ?? [],
            'created_at'            => $asset->created_at?->toISOString(),
            'updated_at'            => $asset->updated_at?->toISOString(),
        ];

        if ($detailed) {
            $data['details']                = $asset->details ?? [];
            // Immobilier
            $data['adresse']                = $asset->adresse;
            $data['ville']                  = $asset->ville;
            $data['commune']                = $asset->commune;
            $data['village']                = $asset->village;
            $data['province']               = $asset->province;
            $data['region']                 = $asset->region;
            $data['superficie']             = $asset->superficie;
            $data['superficie_unite']       = $asset->superficie_unite;
            $data['numero_lot']             = $asset->numero_lot;
            $data['section_cadastrale']     = $asset->section_cadastrale;
            $data['coordonnees_gps']        = $asset->coordonnees_gps ?? [];
            $data['titre_foncier']          = $asset->titre_foncier;
            $data['reference_cadastrale']   = $asset->reference_cadastrale;
            $data['type_propriete']         = $asset->type_propriete;
            // Véhicule
            $data['marque']                 = $asset->marque;
            $data['modele']                 = $asset->modele;
            $data['annee_fabrication']      = $asset->annee_fabrication;
            $data['numero_chassis']         = $asset->numero_chassis;
            $data['numero_immatriculation'] = $asset->numero_immatriculation;
            $data['couleur']                = $asset->couleur;
            $data['carburant']              = $asset->carburant;
            $data['kilometrage']            = $asset->kilometrage;
            // Investissement
            $data['nom_societe']            = $asset->nom_societe;
            $data['type_investissement']    = $asset->type_investissement;
            $data['nombre_parts']           = $asset->nombre_parts;
            $data['valeur_part']            = $asset->valeur_part ? (float) $asset->valeur_part : null;
            $data['courtier']               = $asset->courtier;
            $data['numero_compte_titre']    = $asset->numero_compte_titre;
            $data['isin']                   = $asset->isin;
        }

        return $data;
    }

    private function getValidationRules(string $type): array
    {
        $common = [
            'nom'               => 'required|string|max:255',
            'type'              => 'required|string|in:immobilier,vehicule,investissement,creance,dette,compte_bancaire,autre',
            'statut'            => 'required|string|in:actif,loue,vendu,inactif',
            'valeur_actuelle'   => 'required|numeric|min:0',
            'valeur_initiale'   => 'required|numeric|min:0',
            'devise'            => 'required|string|max:10',
            'pays'              => 'required|string|max:100',
            'date_acquisition'  => 'required|date',
            'description'       => 'nullable|string|max:1000',
        ];

        $typeRules = match($type) {
            Asset::TYPE_IMMOBILIER => [
                'type_propriete'    => 'required|string',
                'pays'              => 'required|string',
                'region'            => 'nullable|string|max:100',
                'province'          => 'nullable|string|max:100',
                'ville'             => 'nullable|string|max:100',
                'commune'           => 'nullable|string|max:100',
                'village'           => 'nullable|string|max:100',
                'superficie'        => 'nullable|numeric|min:0',
                'numero_lot'        => 'nullable|string|max:100',
                'section_cadastrale'=> 'nullable|string|max:100',
                'coordonnees_gps'   => 'nullable|array',
                'coordonnees_gps.*.lat' => 'nullable|numeric|between:-90,90',
                'coordonnees_gps.*.lng' => 'nullable|numeric|between:-180,180',
            ],
            Asset::TYPE_VEHICULE => [
                'marque'                => 'required|string|max:100',
                'modele'                => 'required|string|max:100',
                'annee_fabrication'     => 'required|integer|min:1900|max:' . (date('Y') + 1),
                'numero_chassis'        => 'nullable|string|max:50',
                'numero_immatriculation'=> 'nullable|string|max:30',
            ],
            Asset::TYPE_INVESTISSEMENT => [
                'type_investissement'   => 'required|string',
                'nom_societe'           => 'nullable|string|max:255',
                'nombre_parts'          => 'nullable|numeric|min:0',
                'valeur_part'           => 'nullable|numeric|min:0',
            ],
            default => [],
        };

        return array_merge($common, $typeRules);
    }

    protected function successResponse($data, string $message = 'Succès', int $code = 200): JsonResponse
    {
        return response()->json(['success' => true, 'message' => $message, 'data' => $data], $code);
    }

    protected function errorResponse($errors, int $code = 400): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => is_string($errors) ? $errors : 'Erreur de validation',
            'errors'  => is_string($errors) ? null : $errors,
        ], $code);
    }
}
