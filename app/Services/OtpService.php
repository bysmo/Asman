<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class OtpService
{
    private int $length;
    private int $ttlMinutes;

    public function __construct()
    {
        $this->length     = config('asman.otp_length', 6);
        $this->ttlMinutes = config('asman.otp_ttl', 10);
    }

    /**
     * Générer et stocker un OTP pour l'utilisateur.
     */
    public function sendOtp(User $user): string
    {
        $otp = str_pad((string) random_int(0, (int) str_repeat('9', $this->length)), $this->length, '0', STR_PAD_LEFT);

        // Stocker dans le cache
        Cache::put($this->cacheKey($user->id), $otp, now()->addMinutes($this->ttlMinutes));

        // En production : envoyer par SMS/email
        // SMS::send($user->telephone, "Votre code Asman : $otp");

        // Log pour développement (à retirer en production)
        Log::info("OTP pour {$user->telephone}: {$otp}");

        return $otp;
    }

    /**
     * Vérifier un OTP soumis par l'utilisateur.
     */
    public function verifyOtp(User $user, string $otp): bool
    {
        $cached = Cache::get($this->cacheKey($user->id));

        if (!$cached || $cached !== $otp) {
            return false;
        }

        // Invalider après vérification (usage unique)
        Cache::forget($this->cacheKey($user->id));

        return true;
    }

    private function cacheKey(int $userId): string
    {
        return "otp_user_{$userId}";
    }
}
