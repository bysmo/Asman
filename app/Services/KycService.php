<?php

namespace App\Services;

use App\Models\User;
use App\Models\KycDocument;
use Illuminate\Support\Facades\Storage;

class KycService
{
    /**
     * Retourner le statut KYC complet de l'utilisateur.
     */
    public function getStatus(User $user): array
    {
        $documents = KycDocument::where('user_id', $user->id)->get();

        $required = ['piece_identite', 'justificatif_domicile', 'photo_selfie'];
        $submitted = $documents->pluck('type')->toArray();
        $approved  = $documents->where('statut', 'approuve')->pluck('type')->toArray();
        $rejected  = $documents->where('statut', 'rejete')->pluck('type')->toArray();

        $missingRequired = array_diff($required, $submitted);
        $allApproved     = count(array_diff($required, $approved)) === 0;

        return [
            'kyc_status'       => $user->kyc_status,
            'documents'        => $documents->map(fn($d) => [
                'id'           => $d->id,
                'type'         => $d->type,
                'nom_original' => $d->nom_original,
                'statut'       => $d->statut,
                'commentaire'  => $d->commentaire,
                'verifie_le'   => $d->verifie_le?->toISOString(),
            ])->values(),
            'missing_required' => array_values($missingRequired),
            'approved_types'   => array_values($approved),
            'rejected_types'   => array_values($rejected),
            'all_approved'     => $allApproved,
            'can_use_app'      => in_array($user->kyc_status, [User::KYC_APPROVED, User::KYC_PENDING]),
        ];
    }

    /**
     * Soumettre les documents KYC.
     */
    public function submitDocuments(User $user, array $documents): void
    {
        foreach ($documents as $docData) {
            KycDocument::updateOrCreate(
                ['user_id' => $user->id, 'type' => $docData['type']],
                [
                    'fichier'       => $docData['fichier'],
                    'nom_original'  => $docData['nom_original'] ?? basename($docData['fichier']),
                    'statut'        => 'en_attente',
                    'commentaire'   => null,
                    'verifie_par'   => null,
                    'verifie_le'    => null,
                ]
            );
        }

        // Passer le statut en "submitted" si tous les docs requis sont fournis
        $this->updateUserKycStatus($user);
    }

    /**
     * Approuver un document KYC.
     */
    public function approveDocument(KycDocument $document, int $adminId): void
    {
        $document->update([
            'statut'      => 'approuve',
            'verifie_par' => $adminId,
            'verifie_le'  => now(),
            'commentaire' => null,
        ]);

        $this->updateUserKycStatus($document->user);
    }

    /**
     * Rejeter un document KYC.
     */
    public function rejectDocument(KycDocument $document, int $adminId, string $reason): void
    {
        $document->update([
            'statut'      => 'rejete',
            'verifie_par' => $adminId,
            'verifie_le'  => now(),
            'commentaire' => $reason,
        ]);

        $document->user->update(['kyc_status' => User::KYC_REJECTED]);
    }

    /**
     * Mettre à jour le statut KYC de l'utilisateur selon les documents.
     */
    private function updateUserKycStatus(User $user): void
    {
        $required  = ['piece_identite', 'justificatif_domicile', 'photo_selfie'];
        $documents = KycDocument::where('user_id', $user->id)->get();
        $approved  = $documents->where('statut', 'approuve')->pluck('type')->toArray();

        if (count(array_diff($required, $approved)) === 0) {
            $user->update([
                'kyc_status'      => User::KYC_APPROVED,
                'kyc_verified_at' => now(),
            ]);
        } elseif ($documents->where('statut', 'en_attente')->count() > 0) {
            $user->update(['kyc_status' => User::KYC_PENDING]);
        }
    }
}
