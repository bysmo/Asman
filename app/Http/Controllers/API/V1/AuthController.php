<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\OtpService;
use App\Services\KycService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function __construct(
        protected OtpService $otpService,
        protected KycService $kycService
    ) {}

    // ─── INSCRIPTION ──────────────────────────────────────────────────────────

    public function register(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'nom'           => 'required|string|max:100',
            'prenom'        => 'required|string|max:100',
            'telephone'     => 'required|string|unique:users,telephone|max:20',
            'email'         => 'nullable|email|unique:users,email',
            'password'      => ['required', Password::min(8)->mixedCase()->numbers()],
            'pays'          => 'required|string|max:100',
            'devise'        => 'required|string|max:10',
            'date_naissance'=> 'nullable|date|before:-18 years',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $user = User::create([
            'nom'           => $request->nom,
            'prenom'        => $request->prenom,
            'telephone'     => $request->telephone,
            'email'         => $request->email,
            'password'      => Hash::make($request->password),
            'pays'          => $request->pays,
            'devise'        => $request->devise,
            'date_naissance'=> $request->date_naissance,
            'type'          => User::TYPE_USER,
            'kyc_status'    => User::KYC_PENDING,
            'is_active'     => true,
        ]);

        $user->assignRole('user');

        // Envoyer OTP de vérification
        $this->otpService->sendOtp($user);

        $token = $user->createToken('mobile-app')->plainTextToken;

        return $this->successResponse([
            'user'              => $this->formatUser($user),
            'token'             => $token,
            'otp_required'      => true,
            'kyc_required'      => config('asman.kyc_required', true),
        ], 'Inscription réussie. Vérifiez votre OTP.', 201);
    }

    // ─── CONNEXION ────────────────────────────────────────────────────────────

    public function login(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'telephone' => 'required|string',
            'password'  => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $user = User::where('telephone', $request->telephone)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return $this->errorResponse('Identifiants incorrects.', 401);
        }

        if (!$user->is_active) {
            return $this->errorResponse('Compte désactivé. Contactez le support.', 403);
        }

        $user->update(['last_login_at' => now()]);

        // Révoquer les anciens tokens
        $user->tokens()->delete();
        $token = $user->createToken('mobile-app')->plainTextToken;

        return $this->successResponse([
            'user'          => $this->formatUser($user),
            'token'         => $token,
            'otp_required'  => !$user->otp_verified,
            'pin_set'       => !is_null($user->pin_hash),
            'kyc_status'    => $user->kyc_status,
        ], 'Connexion réussie.');
    }

    // ─── VÉRIFICATION OTP ─────────────────────────────────────────────────────

    public function verifyOtp(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'otp' => 'required|string|size:' . config('asman.otp_length', 6),
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $user = $request->user();

        if (!$this->otpService->verifyOtp($user, $request->otp)) {
            return $this->errorResponse('Code OTP invalide ou expiré.', 400);
        }

        $user->update(['otp_verified' => true]);

        return $this->successResponse([
            'user' => $this->formatUser($user),
        ], 'OTP vérifié avec succès.');
    }

    // ─── RENVOI OTP ───────────────────────────────────────────────────────────

    public function resendOtp(Request $request): JsonResponse
    {
        $user = $request->user();
        $this->otpService->sendOtp($user);

        return $this->successResponse([], 'OTP renvoyé avec succès.');
    }

    // ─── CONFIGURATION PIN ────────────────────────────────────────────────────

    public function setupPin(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'pin'             => 'required|string|size:4|confirmed',
            'pin_confirmation'=> 'required|string|size:4',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $user = $request->user();
        $user->update([
            'pin_hash'   => Hash::make($request->pin),
            'pin_set_at' => now(),
        ]);

        return $this->successResponse([], 'PIN configuré avec succès.');
    }

    // ─── VÉRIFICATION PIN ─────────────────────────────────────────────────────

    public function verifyPin(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'pin' => 'required|string|size:4',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $user = $request->user();

        if (!Hash::check($request->pin, $user->pin_hash)) {
            return $this->errorResponse('PIN incorrect.', 401);
        }

        return $this->successResponse(['verified' => true], 'PIN validé.');
    }

    // ─── MOT DE PASSE OUBLIÉ ──────────────────────────────────────────────────

    public function forgotPassword(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'telephone' => 'required|string|exists:users,telephone',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $user = User::where('telephone', $request->telephone)->first();
        $this->otpService->sendOtp($user);

        return $this->successResponse([], 'Code de réinitialisation envoyé.');
    }

    // ─── RÉINITIALISATION MOT DE PASSE ────────────────────────────────────────

    public function resetPassword(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'telephone'             => 'required|exists:users,telephone',
            'otp'                   => 'required|string',
            'password'              => ['required', Password::min(8)->mixedCase()->numbers(), 'confirmed'],
            'password_confirmation' => 'required',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $user = User::where('telephone', $request->telephone)->first();

        if (!$this->otpService->verifyOtp($user, $request->otp)) {
            return $this->errorResponse('Code OTP invalide ou expiré.', 400);
        }

        $user->update(['password' => Hash::make($request->password)]);
        $user->tokens()->delete();

        return $this->successResponse([], 'Mot de passe réinitialisé avec succès.');
    }

    // ─── DÉCONNEXION ──────────────────────────────────────────────────────────

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        return $this->successResponse([], 'Déconnecté avec succès.');
    }

    // ─── PROFIL ───────────────────────────────────────────────────────────────

    public function profile(Request $request): JsonResponse
    {
        $user = $request->user()->load(['kyc', 'assets', 'comptesBancaires']);
        return $this->successResponse(['user' => $this->formatUser($user, true)]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'nom'    => 'sometimes|string|max:100',
            'prenom' => 'sometimes|string|max:100',
            'email'  => 'sometimes|email|unique:users,email,' . $request->user()->id,
            'pays'   => 'sometimes|string|max:100',
            'devise' => 'sometimes|string|max:10',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $request->user()->update($request->only(['nom', 'prenom', 'email', 'pays', 'devise']));

        return $this->successResponse([
            'user' => $this->formatUser($request->user()->fresh()),
        ], 'Profil mis à jour.');
    }

    // ─── HELPERS ──────────────────────────────────────────────────────────────

    protected function formatUser(User $user, bool $detailed = false): array
    {
        $data = [
            'id'            => $user->id,
            'nom'           => $user->nom,
            'prenom'        => $user->prenom,
            'nom_complet'   => $user->nom_complet,
            'telephone'     => $user->telephone,
            'email'         => $user->email,
            'pays'          => $user->pays,
            'devise'        => $user->devise,
            'type'          => $user->type,
            'kyc_status'    => $user->kyc_status,
            'is_active'     => $user->is_active,
            'otp_verified'  => $user->otp_verified,
            'pin_set'       => !is_null($user->pin_hash),
            'created_at'    => $user->created_at?->toISOString(),
        ];

        if ($detailed) {
            $data['date_naissance'] = $user->date_naissance?->toDateString();
            $data['last_login_at']  = $user->last_login_at?->toISOString();
            $data['kyc_verified_at']= $user->kyc_verified_at?->toISOString();
        }

        return $data;
    }

    protected function successResponse($data, string $message = 'Succès', int $code = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data'    => $data,
        ], $code);
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
