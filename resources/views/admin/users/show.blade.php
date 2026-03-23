@extends('layouts.admin')
@section('title', $user->prenom . ' ' . $user->nom)
@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <div class="d-flex align-items-center gap-3">
        <a href="{{ route('admin.users.index') }}" class="btn btn-sm btn-outline-secondary"><i class="bi bi-arrow-left"></i></a>
        <div>
            <h5 class="fw-bold mb-0">{{ $user->prenom }} {{ $user->nom }}</h5>
            <small class="text-muted">{{ $user->email }}</small>
        </div>
    </div>
    <div class="d-flex gap-2">
        @php $colors=['client'=>'#37474F','notaire'=>'#1565C0','huissier'=>'#2E7D32','avocat'=>'#E65100','admin'=>'#7B1FA2']; @endphp
        <span class="badge fs-6" style="background:{{ $colors[$user->role]??'#999' }}">{{ ucfirst($user->role) }}</span>
        <span class="badge fs-6 bg-{{ $user->statut=='actif'?'success':($user->statut=='suspendu'?'danger':'secondary') }}">{{ $user->statut }}</span>
    </div>
</div>
<div class="row g-3">
    <div class="col-md-4">
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white fw-semibold">Informations</div>
            <div class="card-body">
                <table class="table table-sm table-borderless">
                    <tr><td class="text-muted small">Téléphone</td><td class="small">{{ $user->telephone ?? '—' }}</td></tr>
                    <tr><td class="text-muted small">Pays</td><td class="small">{{ $user->pays }}</td></tr>
                    <tr><td class="text-muted small">Ville</td><td class="small">{{ $user->ville ?? '—' }}</td></tr>
                    <tr><td class="text-muted small">KYC</td><td><span class="badge bg-{{ $user->kyc_statut=='approuve'?'success':'warning text-dark' }}">{{ $user->kyc_statut }}</span></td></tr>
                    <tr><td class="text-muted small">Inscrit le</td><td class="small">{{ $user->created_at->format('d/m/Y') }}</td></tr>
                </table>
                <div class="d-flex gap-2 mt-3">
                    <a href="{{ route('admin.users.edit', $user) }}" class="btn btn-sm btn-outline-primary flex-fill">Modifier</a>
                    @if($user->statut == 'actif')
                    <form method="POST" action="{{ route('admin.users.deactivate', $user) }}" class="flex-fill">@csrf<button class="btn btn-sm btn-outline-danger w-100">Suspendre</button></form>
                    @else
                    <form method="POST" action="{{ route('admin.users.activate', $user) }}" class="flex-fill">@csrf<button class="btn btn-sm btn-outline-success w-100">Activer</button></form>
                    @endif
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-8">
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white fw-semibold">Actifs ({{ $user->assets->count() }})</div>
            <div class="card-body p-0">
                <table class="table table-hover mb-0">
                    <thead class="table-light"><tr><th>Nom</th><th>Type</th><th>Valeur</th><th>Certification</th></tr></thead>
                    <tbody>
                        @forelse($user->assets->take(5) as $a)
                        <tr>
                            <td class="small fw-semibold">{{ $a->nom }}</td>
                            <td class="small">{{ $a->type }}</td>
                            <td class="small">{{ number_format($a->valeur_actuelle) }} {{ $a->devise }}</td>
                            <td><span class="badge bg-{{ $a->certification_statut=='certifie'?'success':'secondary' }}">{{ $a->certification_statut }}</span></td>
                        </tr>
                        @empty
                        <tr><td colspan="4" class="text-center py-3 text-muted">Aucun actif</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
@endsection
