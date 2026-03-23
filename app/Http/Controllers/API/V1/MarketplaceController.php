<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\MarketplaceListing;
use App\Models\Asset;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class MarketplaceController extends Controller
{
    public function index(Request $request)
    {
        $query = MarketplaceListing::with('asset')
            ->where('statut', 'actif');

        if ($request->type) {
            $query->where('type', $request->type);
        }
        if ($request->prix_min) {
            $query->where('prix', '>=', $request->prix_min);
        }
        if ($request->prix_max) {
            $query->where('prix', '<=', $request->prix_max);
        }

        $listings = $query->orderByDesc('created_at')->paginate(20);
        return response()->json(['success' => true, 'data' => $listings]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'asset_id'    => 'required|exists:assets,id',
            'type'        => 'required|in:vente,location',
            'prix'        => 'required|numeric|min:0',
            'description' => 'nullable|string',
        ]);

        $asset = Asset::where('id', $request->asset_id)
            ->where('user_id', Auth::id())
            ->where('certification_statut', 'certifie')
            ->firstOrFail();

        $listing = MarketplaceListing::create([
            'reference'       => 'LST-' . strtoupper(Str::random(8)),
            'asset_id'        => $asset->id,
            'user_id'         => Auth::id(),
            'type'            => $request->type,
            'statut'          => 'actif',
            'prix'            => $request->prix,
            'devise'          => $request->devise ?? 'XOF',
            'description'     => $request->description,
            'negociable'      => $request->negociable ?? false,
            'date_expiration' => $request->date_expiration,
        ]);

        // Mettre à jour l'asset
        $asset->update([
            'en_vente'    => $request->type === 'vente',
            'en_location' => $request->type === 'location',
            'prix_vente'  => $request->type === 'vente' ? $request->prix : null,
            'prix_location' => $request->type === 'location' ? $request->prix : null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Annonce publiée avec succès.',
            'data'    => $listing->load('asset')
        ], 201);
    }

    public function show(MarketplaceListing $listing)
    {
        $listing->increment('vues');
        return response()->json([
            'success' => true,
            'data'    => $listing->load('asset.user')
        ]);
    }

    public function update(Request $request, MarketplaceListing $listing)
    {
        abort_if($listing->user_id !== Auth::id(), 403);
        $listing->update($request->only(['prix', 'description', 'negociable', 'date_expiration']));
        return response()->json(['success' => true, 'data' => $listing]);
    }

    public function destroy(MarketplaceListing $listing)
    {
        abort_if($listing->user_id !== Auth::id(), 403);
        $listing->update(['statut' => 'cloture']);
        $listing->asset->update(['en_vente' => false, 'en_location' => false]);
        return response()->json(['success' => true, 'message' => 'Annonce retirée.']);
    }

    public function contact(Request $request, MarketplaceListing $listing)
    {
        $request->validate([
            'message' => 'required|string|max:1000',
        ]);
        // Envoyer notification au propriétaire (à implémenter avec notifications)
        return response()->json([
            'success' => true,
            'message' => 'Message envoyé au propriétaire.'
        ]);
    }

    public function suspendre(MarketplaceListing $listing)
    {
        abort_if($listing->user_id !== Auth::id(), 403);
        $listing->update(['statut' => 'suspendu']);
        return response()->json(['success' => true, 'message' => 'Annonce suspendue.']);
    }
}
