<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Routing\Controller as BaseController;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Validation\ValidatesRequests;

abstract class Controller extends BaseController
{
    use AuthorizesRequests, ValidatesRequests;

    /**
     * Réponse succès standardisée.
     */
    protected function successResponse($data, string $message = 'Succès', int $code = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data'    => $data,
        ], $code);
    }

    /**
     * Réponse erreur standardisée.
     */
    protected function errorResponse($errors, int $code = 400): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => is_string($errors) ? $errors : 'Erreur de validation',
            'errors'  => is_string($errors) ? null : $errors,
        ], $code);
    }

    /**
     * Réponse paginée standardisée.
     */
    protected function paginatedResponse($paginator, string $key = 'items'): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => [
                $key        => $paginator->items(),
                'meta'      => [
                    'current_page'  => $paginator->currentPage(),
                    'last_page'     => $paginator->lastPage(),
                    'per_page'      => $paginator->perPage(),
                    'total'         => $paginator->total(),
                    'has_more'      => $paginator->hasMorePages(),
                ],
            ],
        ]);
    }
}
