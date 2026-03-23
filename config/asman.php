<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Configuration Asman
    |--------------------------------------------------------------------------
    */

    // OTP
    'otp_length'       => env('OTP_LENGTH', 6),
    'otp_ttl'          => env('OTP_TTL_MINUTES', 10),    // minutes

    // KYC
    'kyc_required'     => env('KYC_REQUIRED', true),
    'kyc_documents'    => ['piece_identite', 'justificatif_domicile', 'photo_selfie'],

    // Revenue sharing
    'platform_share'   => env('PLATFORM_SHARE_PERCENT', 30),     // 30%
    'authority_share'  => env('AUTHORITY_SHARE_PERCENT', 70),    // 70%

    // Certifications
    'certification_fee' => env('CERTIFICATION_FEE', 5000),       // XOF

    // Liquidations
    'liquidation_reserve_rate' => env('LIQUIDATION_RESERVE_RATE', 0.10), // 10%

    // App
    'app_name'         => env('APP_NAME', 'Asman'),
    'app_version'      => env('APP_VERSION', '1.0.0'),
    'currency_default' => env('DEFAULT_CURRENCY', 'XOF'),
    'country_default'  => env('DEFAULT_COUNTRY', 'BF'),

    // Pagination
    'per_page'         => env('API_PER_PAGE', 20),

    // Upload
    'max_file_size'    => env('MAX_FILE_SIZE_MB', 10),   // MB
    'allowed_mimes'    => ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
    'disk'             => env('FILESYSTEM_DISK', 'local'),
];
