<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\AsmanScore;
use App\Services\AsmanScoreService;
use Illuminate\Http\Request;

class AsmanScoreController extends Controller
{
    public function __construct(private AsmanScoreService $scoreService) {}

    // ─── Score courant de l'utilisateur ──────────────────────────────────────
    public function current(Request $request)
    {
        $user  = $request->user();
        $score = AsmanScore::where('user_id', $user->id)
                           ->orderBy('created_at', 'desc')
                           ->first();

        if (!$score) {
            // Calculer à la volée
            $result = $this->scoreService->calculateScore($user->id);
            return $this->successResponse($result, 'Score calculé');
        }

        return $this->successResponse([
            'score_total'        => $score->score_total,
            'niveau'             => $score->niveau,
            'score_diversification' => $score->score_diversification,
            'score_certification'   => $score->score_certification,
            'score_liquidite'       => $score->score_liquidite,
            'score_documentation'   => $score->score_documentation,
            'score_regularite'      => $score->score_regularite,
            'badge_color'        => $this->getBadgeColor($score->score_total),
            'recommandations'    => $score->recommandations ?? [],
            'updated_at'         => $score->updated_at,
        ]);
    }

    // ─── Recalculer le score ──────────────────────────────────────────────────
    public function recalculate(Request $request)
    {
        $result = $this->scoreService->calculateScore($request->user()->id);
        return $this->successResponse($result, 'Score recalculé');
    }

    // ─── Historique du score ──────────────────────────────────────────────────
    public function history(Request $request)
    {
        $history = AsmanScore::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->limit(12)
            ->get()
            ->map(fn($s) => [
                'score'  => $s->score_total,
                'niveau' => $s->niveau,
                'date'   => $s->created_at->format('Y-m'),
            ]);

        return $this->successResponse($history);
    }

    // ─── Classement anonymisé (Leaderboard) ──────────────────────────────────
    public function leaderboard(Request $request)
    {
        $topScores = AsmanScore::select('score_total', 'niveau', 'created_at')
            ->orderBy('score_total', 'desc')
            ->limit(10)
            ->get()
            ->map((fn($s, $i) => [
                'rang'   => $i + 1,
                'score'  => $s->score_total,
                'niveau' => $s->niveau,
            ]))->values();

        $userScore = AsmanScore::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->value('score_total');

        return $this->successResponse([
            'top_10'     => $topScores,
            'user_score' => $userScore,
        ]);
    }

    private function getBadgeColor(int $score): string
    {
        return match(true) {
            $score >= 800 => '#7B1FA2', // Elite - violet
            $score >= 600 => '#FFB300', // Premium - or
            $score >= 400 => '#1976D2', // Standard - bleu
            default       => '#78909C', // Découverte - gris
        };
    }
}
