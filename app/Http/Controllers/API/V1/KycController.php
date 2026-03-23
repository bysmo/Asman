<?php

namespace App\Http\Controllers\API\V1;

use App\Http\Controllers\Controller;
use App\Models\Asset;
use App\Models\Certification;
use App\Models\Loyer;
use App\Models\CompteBancaire;
use App\Models\Creance;
use App\Models\Dette;
use App\Models\Testament;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class KycController extends Controller
{
    public function status(Request $request)
    {
        $user = Auth::user();
        return response()->json([
            'success' => true,
            'data' => [
                'statut'    => $user->kyc_statut,
                'niveau'    => $user->kyc_niveau,
                'date'      => $user->kyc_date,
                'documents' => $user->kycDocuments ?? [],
            ]
        ]);
    }

    public function submit(Request $request)
    {
        $request->validate([
            'numero_piece'   => 'required|string',
            'type_piece'     => 'required|in:cni,passeport,permis,autre',
            'date_naissance' => 'required|date',
            'lieu_naissance' => 'required|string',
            'adresse'        => 'required|string',
            'ville'          => 'required|string',
        ]);

        $user = Auth::user();
        $user->update([
            'numero_piece'   => $request->numero_piece,
            'type_piece'     => $request->type_piece,
            'date_naissance' => $request->date_naissance,
            'lieu_naissance' => $request->lieu_naissance,
            'adresse'        => $request->adresse,
            'ville'          => $request->ville,
            'province'       => $request->province,
            'region'         => $request->region,
            'kyc_statut'     => 'en_attente',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'KYC soumis avec succès. En attente de vérification.',
            'data'    => ['statut' => 'en_attente']
        ]);
    }

    public function uploadDocuments(Request $request)
    {
        $request->validate([
            'type'    => 'required|in:piece_identite,justificatif_domicile,photo_selfie,autre',
            'fichier' => 'required|file|mimes:jpg,jpeg,png,pdf|max:5120',
        ]);

        $path = $request->file('fichier')->store('kyc/' . Auth::id(), 'public');

        $doc = Auth::user()->kycDocuments()->create([
            'type'         => $request->type,
            'fichier'      => $path,
            'nom_original' => $request->file('fichier')->getClientOriginalName(),
            'statut'       => 'en_attente',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Document téléversé avec succès.',
            'data'    => $doc
        ]);
    }
}
