<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\Certification;
use App\Models\Asset;
use App\Models\Paiement;
use App\Services\CertificationService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class CertificationController extends Controller
{
    public function __construct(protected CertificationService $certService) {}

    // ─── MES DEMANDES ─────────────────────────────────────────────────────────

    public function index(Request $request): JsonResponse
    {
        $certs = Certification::where('demandeur_id', $request->user()->id)
            ->with(['asset', 'autorite'])
            ->orderByDesc('created_at')
            ->get();

        return $this->successResponse([
            'certifications' => $certs->map(fn($c) => $this->formatCert($c)),
            'stats' => [
                'total'        => $certs->count(),
                'en_attente'   => $certs->where('statut', Certification::STATUS_EN_ATTENTE)->count(),
                'certifiees'   => $certs->where('statut', Certification::STATUS_CERTIFIE)->count(),
                'refusees'     => $certs->where('statut', Certification::STATUS_REFUSE)->count(),
            ],
        ]);
    }

    // ─── CRÉER UNE DEMANDE ────────────────────────────────────────────────────

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'asset_id'      => 'required|integer|exists:assets,id',
            'type_autorite' => 'required|string|in:notaire,huissier,avocat,tribunal,cadastre',
            'autorite_id'   => 'nullable|integer|exists:users,id',
            'frais'         => 'required|numeric|min:0',
            'devise'        => 'required|string|max:10',
            'notes'         => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        // Vérifier que l'actif appartient à l'utilisateur
        $asset = Asset::where('user_id', $request->user()->id)
            ->findOrFail($request->asset_id);

        // Vérification anti-doublon
        $doublon = $this->certService->detecterDoublon($asset);
        if ($doublon) {
            return $this->errorResponse(
                "Cet actif est déjà certifié (ref: {$doublon->reference_certification}). La double certification est interdite.",
                409
            );
        }

        // Vérifier s'il n'y a pas une demande en cours
        if (in_array($asset->certification_status, [
            Asset::CERT_EN_ATTENTE, Asset::CERT_EN_COURS
        ])) {
            return $this->errorResponse(
                'Une demande de certification est déjà en cours pour cet actif.', 409
            );
        }

        $cert = $this->certService->creerDemande(
            asset:         $asset,
            demandeur:     $request->user(),
            typeAutorite:  $request->type_autorite,
            frais:         $request->frais,
            devise:        $request->devise,
            autoriteId:    $request->autorite_id,
            notes:         $request->notes,
        );

        return $this->successResponse(
            ['certification' => $this->formatCert($cert->load(['asset', 'autorite']))],
            'Demande de certification soumise.',
            201
        );
    }

    // ─── DÉTAIL D'UNE CERTIFICATION ───────────────────────────────────────────

    public function show(Request $request, int $id): JsonResponse
    {
        $cert = Certification::where('demandeur_id', $request->user()->id)
            ->with(['asset', 'autorite', 'paiements'])
            ->findOrFail($id);

        return $this->successResponse(['certification' => $this->formatCert($cert, true)]);
    }

    // ─── ANNULER UNE DEMANDE ──────────────────────────────────────────────────

    public function annuler(Request $request, int $id): JsonResponse
    {
        $cert = Certification::where('demandeur_id', $request->user()->id)
            ->where('statut', Certification::STATUS_EN_ATTENTE)
            ->findOrFail($id);

        $this->certService->annuler($cert);

        return $this->successResponse([], 'Demande de certification annulée.');
    }

    // ─── LISTE DES NOTAIRES DISPONIBLES ──────────────────────────────────────

    public function notairesDisponibles(Request $request): JsonResponse
    {
        $type = $request->type ?? 'notaire';
        $pays = $request->pays ?? $request->user()->pays;

        $autorites = \App\Models\User::autorites()
            ->where('type', $type)
            ->where('autorite_valide', true)
            ->where('is_active', true)
            ->where(function ($q) use ($pays) {
                $q->whereNull('pays')->orWhere('pays', $pays);
            })
            ->select('id', 'nom', 'prenom', 'telephone', 'email',
                'autorite_cabinet', 'autorite_adresse', 'autorite_specialite',
                'autorite_numero_agrement', 'pays')
            ->get();

        return $this->successResponse([
            'autorites' => $autorites->map(fn($a) => [
                'id'            => $a->id,
                'nom_complet'   => $a->nom_complet,
                'telephone'     => $a->telephone,
                'email'         => $a->email,
                'cabinet'       => $a->autorite_cabinet,
                'adresse'       => $a->autorite_adresse,
                'specialite'    => $a->autorite_specialite,
                'agrement'      => $a->autorite_numero_agrement,
                'pays'          => $a->pays,
            ]),
        ]);
    }

    // ─── [AUTORITÉ] CERTIFICATIONS ASSIGNÉES ─────────────────────────────────

    public function mesAssignations(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->is_autorite) {
            return $this->errorResponse('Accès réservé aux autorités habilitées.', 403);
        }

        $certs = Certification::where('autorite_id', $user->id)
            ->with(['asset', 'demandeur'])
            ->orderByDesc('created_at')
            ->get();

        return $this->successResponse([
            'certifications' => $certs->map(fn($c) => $this->formatCert($c, true)),
        ]);
    }

    // ─── [AUTORITÉ] APPROUVER / REFUSER ──────────────────────────────────────

    public function approuver(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if (!$user->is_autorite) {
            return $this->errorResponse('Accès réservé aux autorités.', 403);
        }

        $cert = Certification::where('autorite_id', $user->id)
            ->where('statut', Certification::STATUS_EN_ATTENTE)
            ->findOrFail($id);

        $this->certService->approuver($cert, $user);

        return $this->successResponse(
            ['certification' => $this->formatCert($cert->fresh())],
            'Certification approuvée.'
        );
    }

    public function refuser(Request $request, int $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'motif' => 'required|string|max:500',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $user = $request->user();
        if (!$user->is_autorite) {
            return $this->errorResponse('Accès réservé aux autorités.', 403);
        }

        $cert = Certification::where('autorite_id', $user->id)
            ->whereIn('statut', [Certification::STATUS_EN_ATTENTE, Certification::STATUS_EN_COURS])
            ->findOrFail($id);

        $this->certService->refuser($cert, $request->motif);

        return $this->successResponse(
            ['certification' => $this->formatCert($cert->fresh())],
            'Certification refusée.'
        );
    }

    // ─── FORMAT ───────────────────────────────────────────────────────────────

    private function formatCert(Certification $cert, bool $detailed = false): array
    {
        $data = [
            'id'                    => $cert->id,
            'asset_id'              => $cert->asset_id,
            'asset_nom'             => $cert->asset?->nom,
            'asset_type'            => $cert->asset?->type,
            'statut'                => $cert->statut,
            'type_autorite'         => $cert->type_autorite,
            'autorite_nom'          => $cert->autorite_nom,
            'autorite_contact'      => $cert->autorite_contact,
            'frais'                 => (float) $cert->frais,
            'devise'                => $cert->devise,
            'paiement_effectue'     => $cert->paiement_effectue,
            'part_autorite_pct'     => $cert->part_autorite_pct ?? 70,
            'part_plateforme_pct'   => $cert->part_plateforme_pct ?? 30,
            'montant_autorite'      => $cert->montant_autorite ? (float) $cert->montant_autorite : null,
            'montant_plateforme'    => $cert->montant_plateforme ? (float) $cert->montant_plateforme : null,
            'reference_certification' => $cert->reference_certification,
            'date_demande'          => $cert->date_demande?->toISOString(),
            'date_traitement'       => $cert->date_traitement?->toISOString(),
            'notes'                 => $cert->notes,
            'motif_refus'           => $cert->motif_refus,
        ];

        if ($detailed && $cert->autorite) {
            $data['autorite'] = [
                'id'         => $cert->autorite->id,
                'nom_complet'=> $cert->autorite->nom_complet,
                'telephone'  => $cert->autorite->telephone,
                'cabinet'    => $cert->autorite->autorite_cabinet,
            ];
        }

        return $data;
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
