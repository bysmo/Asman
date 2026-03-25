<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AsmanScore extends Model
{
    protected $fillable = [
        'user_id','score_total','score_diversification','score_certification',
        'score_liquidite','score_documentation','score_regularite',
        'niveau','recommandations','rapport_certifie','calcule_le','expire_le',
    ];

    protected $casts = [
        'rapport_certifie' => 'boolean',
        'calcule_le'       => 'datetime',
        'expire_le'        => 'datetime',
    ];

    const NIVEAU_BRONZE   = 'bronze';   // 0-299
    const NIVEAU_ARGENT   = 'argent';   // 300-499
    const NIVEAU_OR       = 'or';       // 500-699
    const NIVEAU_PLATINE  = 'platine';  // 700-899
    const NIVEAU_DIAMANT  = 'diamant';  // 900-1000

    public function user(): BelongsTo { return $this->belongsTo(User::class); }

    public static function niveauFromScore(int $score): string
    {
        return match(true) {
            $score >= 900 => self::NIVEAU_DIAMANT,
            $score >= 700 => self::NIVEAU_PLATINE,
            $score >= 500 => self::NIVEAU_OR,
            $score >= 300 => self::NIVEAU_ARGENT,
            default       => self::NIVEAU_BRONZE,
        };
    }

    public static function niveauColor(string $niveau): string
    {
        return match($niveau) {
            self::NIVEAU_DIAMANT => '#B9F2FF',
            self::NIVEAU_PLATINE => '#E5E4E2',
            self::NIVEAU_OR      => '#FFD700',
            self::NIVEAU_ARGENT  => '#C0C0C0',
            default              => '#CD7F32',
        };
    }
}
