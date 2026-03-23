<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Certification;
use App\Models\User;
use App\Models\RevenueShare;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CertificationAdminController extends Controller
{
    public function index(Request $request)
    {
        $query = Certification::with(['asset.user', 'user', 'assigneA']);

        if ($statut = $request->statut) {
            $query->where('statut', $statut);
        }
        if ($type = $request->type_autorite) {
            $query->where('type_autorite', $type);
        }

        // Notaire/Huissier/Avocat ne voit que ses dossiers
        if (in_array(Auth::user()->role, ['notaire', 'huissier', 'avocat'])) {
            $query->where('assigne_a', Auth::id());
        }

        $certifications = $query->orderByDesc('created_at')->paginate(20);
        $autorites = User::whereIn('role', ['notaire', 'huissier', 'avocat'])
            ->where('statut', 'actif')
            ->get();

        return view('admin.certifications.index', compact('certifications', 'autorites'));
    }

    public function show(Certification $certification)
    {
        $certification->load(['asset', 'user', 'assigneA']);
        return view('admin.certifications.show', compact('certification'));
    }

    public function approuver(Request $request, Certification $certification)
    {
        $request->validate([
            'frais'  => 'required|numeric|min:0',
            'notes'  => 'nullable|string',
        ]);

        $frais            = $request->frais;
        $montantAutorite  = $frais * 0.70;
        $montantPlateforme = $frais * 0.30;

        $certification->update([
            'statut'             => 'certifie',
            'notes'              => $request->notes,
            'frais'              => $frais,
            'statut_paiement'    => 'paye',
            'date_certification' => now(),
            'montant_autorite'   => $montantAutorite,
            'montant_plateforme' => $montantPlateforme,
        ]);

        // Mettre à jour l'actif
        $certification->asset->update([
            'certification_statut'       => 'certifie',
            'certification_id'           => $certification->reference,
            'certification_autorite_nom' => Auth::user()->nom . ' ' . Auth::user()->prenom,
            'date_certification'         => now()->toDateString(),
        ]);

        // Enregistrer le partage de revenus
        RevenueShare::create([
            'certification_id'  => $certification->id,
            'autorite_id'       => $certification->assigne_a,
            'montant_total'     => $frais,
            'montant_autorite'  => $montantAutorite,
            'montant_plateforme' => $montantPlateforme,
            'devise'            => $certification->devise_frais,
            'statut'            => 'en_attente',
        ]);

        return redirect()->route('admin.certifications.show', $certification)
            ->with('success', 'Certification approuvée. Revenus : Autorité ' . number_format($montantAutorite) . ' XOF | Asman ' . number_format($montantPlateforme) . ' XOF');
    }

    public function rejeter(Request $request, Certification $certification)
    {
        $request->validate(['motif_refus' => 'required|string']);
        $certification->update([
            'statut'      => 'refuse',
            'motif_refus' => $request->motif_refus,
        ]);
        $certification->asset->update(['certification_statut' => 'refuse']);
        return redirect()->route('admin.certifications.index')->with('success', 'Certification refusée.');
    }

    public function assigner(Request $request, Certification $certification)
    {
        $request->validate(['autorite_id' => 'required|exists:users,id']);
        $autorite = User::findOrFail($request->autorite_id);

        $certification->update([
            'assigne_a'      => $autorite->id,
            'type_autorite'  => $autorite->role,
            'statut'         => 'en_cours',
        ]);

        return back()->with('success', 'Dossier assigné à ' . $autorite->prenom . ' ' . $autorite->nom . '.');
    }
}
