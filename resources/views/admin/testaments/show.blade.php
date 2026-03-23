@extends('layouts.admin')
@section('title', 'Testament ' . $testament->reference)
@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <div class="d-flex align-items-center gap-3">
        <a href="{{ route('admin.testaments.index') }}" class="btn btn-sm btn-outline-secondary"><i class="bi bi-arrow-left"></i></a>
        <div><h5 class="fw-bold mb-0">{{ $testament->reference }}</h5><small class="text-muted">{{ $testament->user->prenom ?? '' }} {{ $testament->user->nom ?? '' }}</small></div>
    </div>
    @php $b=['brouillon'=>'secondary','finalise'=>'info','certifie'=>'success','revoque'=>'danger']; @endphp
    <span class="badge fs-6 bg-{{ $b[$testament->statut]??'secondary' }}">{{ ucfirst($testament->statut) }}</span>
</div>
<div class="row g-3">
    <div class="col-md-7">
        <div class="card mb-3" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white fw-semibold">Contenu du testament</div>
            <div class="card-body">
                <p class="small text-muted">{{ $testament->contenu ?? 'Aucun contenu rédigé.' }}</p>
                @if($testament->dispositions_speciales)<p class="small"><strong>Dispositions spéciales :</strong> {{ $testament->dispositions_speciales }}</p>@endif
                @if($testament->clauses)<p class="small"><strong>Clauses :</strong> {{ $testament->clauses }}</p>@endif
                <div class="row mt-3">
                    <div class="col-6"><small class="text-muted">Témoin 1 :</small><div class="small fw-semibold">{{ $testament->temoin_1 ?? '—' }}</div></div>
                    <div class="col-6"><small class="text-muted">Témoin 2 :</small><div class="small fw-semibold">{{ $testament->temoin_2 ?? '—' }}</div></div>
                </div>
            </div>
        </div>
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white fw-semibold">Ayants droit ({{ $testament->ayantsDroit->count() }})</div>
            <div class="card-body p-0">
                <table class="table table-hover mb-0">
                    <thead class="table-light"><tr><th>Nom</th><th>Type</th><th>Lien</th><th>Part %</th></tr></thead>
                    <tbody>
                        @forelse($testament->ayantsDroit as $a)
                        <tr>
                            <td class="small fw-semibold">{{ $a->prenom }} {{ $a->nom }}</td>
                            <td><span class="badge bg-secondary">{{ $a->type }}</span></td>
                            <td class="small">{{ $a->lien_parente }}</td>
                            <td class="fw-bold">{{ $a->pourcentage }}%</td>
                        </tr>
                        @empty<tr><td colspan="4" class="text-center py-3 text-muted">Aucun ayant droit</td></tr>@endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <div class="col-md-5">
        <div class="card mb-3" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white fw-semibold">Notaire</div>
            <div class="card-body">
                @if($testament->notaire)
                    <p class="mb-1 fw-semibold">{{ $testament->notaire->prenom }} {{ $testament->notaire->nom }}</p>
                    <p class="small text-muted mb-0">{{ $testament->notaire->cabinet }}</p>
                @else
                    <p class="text-muted small">Non assigné</p>
                @endif
                @if($testament->date_certification)
                    <div class="mt-2 alert alert-success py-2 mb-0 small"><i class="bi bi-patch-check me-1"></i>Certifié le {{ $testament->date_certification }}</div>
                @endif
            </div>
        </div>
        @if($testament->statut === 'finalise' && in_array(auth()->user()->role, ['notaire','admin']))
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white fw-semibold text-success">Certifier ce testament</div>
            <div class="card-body">
                <form method="POST" action="{{ route('admin.testaments.certifier', $testament) }}">
                    @csrf
                    <p class="small text-muted">En certifiant ce testament, vous confirmez avoir vérifié l'identité du testateur et la conformité légale du document.</p>
                    <button class="btn btn-success w-100" onclick="return confirm('Certifier ce testament ?')"><i class="bi bi-patch-check me-1"></i>Certifier</button>
                </form>
            </div>
        </div>
        @endif
    </div>
</div>
@endsection
