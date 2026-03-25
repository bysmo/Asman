<?php
namespace App\Services;

use App\Models\User;
use App\Models\Asset;
use App\Models\AsmanScore;

class AsmanScoreService
{
    /**
     * Calcule et sauvegarde le score patrimonial d'un utilisateur.
     * Score max : 1000 pts
     */
    public function calculate(User $user): AsmanScore
    {
        $assets = Asset::where('user_id', $user->id)->get();
        $total  = $assets->count();

        // ── 1. Score Diversification (200 pts) ──────────────────────────────
        // Plus les types d'actifs sont variés, meilleur est le score
        $types = $assets->pluck('type')->unique()->count();
        $scoreDiversification = min(200, $types * 40);

        // ── 2. Score Certification (300 pts) ────────────────────────────────
        // % d'actifs certifiés × 300
        $certifies = $assets->where('certification_status', 'certifie')->count();
        $scoreCertification = $total > 0 ? (int) round($certifies / $total * 300) : 0;

        // ── 3. Score Liquidité (200 pts) ────────────────────────────────────
        // Présence de comptes bancaires + créances liquides
        $comptes  = \App\Models\CompteBancaire::where('user_id', $user->id)->count();
        $scoreLiquidite = min(200, $comptes * 40 + ($total > 0 ? 20 : 0));

        // ── 4. Score Documentation (150 pts) ────────────────────────────────
        // % d'actifs avec photos + KYC complet
        $avecPhotos = $assets->filter(fn($a) => !empty($a->photos))->count();
        $docScore   = $total > 0 ? (int) round($avecPhotos / $total * 100) : 0;
        $kycBonus   = $user->kyc_status === 'approuve' ? 50 : 0;
        $scoreDocumentation = min(150, $docScore + $kycBonus);

        // ── 5. Score Régularité (150 pts) ────────────────────────────────────
        // Ancienneté du compte + évaluations récentes
        $moisAnciennete = max(0, $user->created_at?->diffInMonths(now()) ?? 0);
        $reEvalues = $assets->filter(fn($a) =>
            $a->date_derniere_evaluation &&
            \Carbon\Carbon::parse($a->date_derniere_evaluation)->gt(now()->subYear())
        )->count();
        $scoreRegularite = min(150, min(75, $moisAnciennete * 5) + ($total > 0 ? (int)round($reEvalues/$total*75) : 0));

        $total_score = $scoreDiversification + $scoreCertification + $scoreLiquidite + $scoreDocumentation + $scoreRegularite;
        $niveau      = AsmanScore::niveauFromScore($total_score);

        $recommandations = $this->buildRecommandations(
            $total, $types, $certifies, $comptes, $user->kyc_status, $niveau
        );

        return AsmanScore::updateOrCreate(
            ['user_id' => $user->id],
            [
                'score_total'            => $total_score,
                'score_diversification'  => $scoreDiversification,
                'score_certification'    => $scoreCertification,
                'score_liquidite'        => $scoreLiquidite,
                'score_documentation'    => $scoreDocumentation,
                'score_regularite'       => $scoreRegularite,
                'niveau'                 => $niveau,
                'recommandations'        => $recommandations,
                'calcule_le'             => now(),
                'expire_le'              => now()->addDays(30),
            ]
        );
    }

    private function buildRecommandations(int $total, int $types, int $certifies, int $comptes, string $kycStatus, string $niveau): string
    {
        $recs = [];

        if ($kycStatus !== 'approuve') {
            $recs[] = '✅ Complétez votre KYC pour débloquer tous les services et améliorer votre score.';
        }
        if ($total < 3) {
            $recs[] = '📊 Ajoutez plus d\'actifs à votre portfolio pour améliorer la diversification.';
        }
        if ($types < 3) {
            $recs[] = '🔀 Diversifiez vos types d\'actifs (immobilier, véhicule, investissement, épargne).';
        }
        if ($certifies < $total && $total > 0) {
            $recs[] = '⚖️ Faites certifier vos actifs par un notaire — cela représente jusqu\'à 300 pts.';
        }
        if ($comptes === 0) {
            $recs[] = '🏦 Liez au moins un compte bancaire pour améliorer votre score de liquidité.';
        }
        if ($niveau === AsmanScore::NIVEAU_BRONZE) {
            $recs[] = '🚀 Commencez par le KYC + 1 certification pour passer au niveau Argent.';
        }

        return implode("\n", $recs) ?: 'Votre patrimoine est bien structuré. Continuez ainsi !';
    }

    public function format(AsmanScore $score): array
    {
        return [
            'score_total'           => $score->score_total,
            'niveau'                => $score->niveau,
            'niveau_color'          => AsmanScore::niveauColor($score->niveau),
            'details'               => [
                'diversification'   => ['score' => $score->score_diversification, 'max' => 200],
                'certification'     => ['score' => $score->score_certification,   'max' => 300],
                'liquidite'         => ['score' => $score->score_liquidite,       'max' => 200],
                'documentation'     => ['score' => $score->score_documentation,   'max' => 150],
                'regularite'        => ['score' => $score->score_regularite,      'max' => 150],
            ],
            'recommandations'       => $score->recommandations,
            'rapport_certifie'      => $score->rapport_certifie,
            'calcule_le'            => $score->calcule_le?->toISOString(),
            'expire_le'             => $score->expire_le?->toISOString(),
        ];
    }
}
