@extends('layouts.admin')
@section('title', 'Certification ' . $certification->reference)

@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <a href="{{ route('admin.certifications.index') }}" class="btn btn-sm btn-outline-secondary me-2">
            <i class="bi bi-arrow-left"></i> Retour
        </a>
        <span class="fw-bold fs-5">{{ $certification->reference }}</span>
    </div>
    @php $badges = ['en_attente'=>['warning','dark'],'en_cours'=>['info','white'],'certifie'=>['success','white'],'refuse'=>['danger','white']]; $b = $badges[$certification->statut] ?? ['secondary','white']; @endphp
    <span class="badge bg-{{ $b[0] }} text-{{ $b[1] }} fs-6">{{ str_replace('_', ' ', $certification->statut) }}</span>
</div>

<div class="row g-3">
    <!-- Infos actif -->
    <div class="col-md-6">
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white fw-semibold">Actif concerné</div>
            <div class="card-body">
                <table class="table table-sm table-borderless">
                    <tr><td class="text-muted">Nom</td><td class="fw-semibold">{{ $certification->asset->nom }}</td></tr>
                    <tr><td class="text-muted">Type</td><td>{{ $certification->asset->type }}</td></tr>
                    <tr><td class="text-muted">Valeur</td><td>{{ number_format($certification->asset->valeur_actuelle) }} {{ $certification->asset->devise }}</td></tr>
                    <tr><td class="text-muted">Pays</td><td>{{ $certification->asset->pays }}</td></tr>
                    <tr><td class="text-muted">Propriétaire</td><td>{{ $certification->user->prenom }} {{ $certification->user->nom }}</td></tr>
                </table>
            </div>
        </div>
    </div>

    <!-- Actions -->
    <div class="col-md-6">
        @if($certification->statut === 'en_attente')
        <!-- Assigner -->
        <div class="card mb-3" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white fw-semibold">Assigner à une autorité</div>
            <div class="card-body">
                <form method="POST" action="{{ route('admin.certifications.assigner', $certification) }}">
                    @csrf
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Autorité compétente</label>
                        <select name="autorite_id" class="form-select" required>
                            <option value="">-- Sélectionner --</option>
                            @foreach($autorites as $a)
                            <option value="{{ $a->id }}">{{ $a->prenom }} {{ $a->nom }} ({{ ucfirst($a->role) }})</option>
                            @endforeach
                        </select>
                    </div>
                    <button class="btn btn-primary w-100">Assigner le dossier</button>
                </form>
            </div>
        </div>
        @endif

        @if(in_array($certification->statut, ['en_attente', 'en_cours']))
        <!-- Approuver -->
        <div class="card mb-3" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white fw-semibold text-success">Approuver la certification</div>
            <div class="card-body">
                <form method="POST" action="{{ route('admin.certifications.approuver', $certification) }}">
                    @csrf
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Frais de certification (XOF)</label>
                        <input type="number" name="frais" class="form-control" placeholder="Ex: 50000" required min="0">
                        <small class="text-muted">70% → Autorité | 30% → Asman</small>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Notes</label>
                        <textarea name="notes" class="form-control" rows="2"></textarea>
                    </div>
                    <button class="btn btn-success w-100"><i class="bi bi-patch-check me-1"></i>Certifier l'actif</button>
                </form>
            </div>
        </div>

        <!-- Rejeter -->
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white fw-semibold text-danger">Rejeter la demande</div>
            <div class="card-body">
                <form method="POST" action="{{ route('admin.certifications.rejeter', $certification) }}">
                    @csrf
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Motif du refus *</label>
                        <textarea name="motif_refus" class="form-control" rows="3" required placeholder="Expliquez la raison du refus..."></textarea>
                    </div>
                    <button class="btn btn-danger w-100"><i class="bi bi-x-circle me-1"></i>Rejeter</button>
                </form>
            </div>
        </div>
        @endif

        @if($certification->statut === 'certifie')
        <div class="alert alert-success">
            <i class="bi bi-patch-check-fill me-2"></i>
            <strong>Certifié le {{ $certification->date_certification?->format('d/m/Y') }}</strong><br>
            Frais : {{ number_format($certification->frais) }} XOF<br>
            Autorité (70%) : {{ number_format($certification->montant_autorite) }} XOF<br>
            Asman (30%) : {{ number_format($certification->montant_plateforme) }} XOF
        </div>
        @endif
    </div>
</div>
@endsection
