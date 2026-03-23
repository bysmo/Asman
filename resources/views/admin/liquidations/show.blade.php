@extends('layouts.admin')
@section('title', 'Liquidation ' . $liquidation->reference)
@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <div class="d-flex align-items-center gap-3">
        <a href="{{ route('admin.liquidations.index') }}" class="btn btn-sm btn-outline-secondary"><i class="bi bi-arrow-left"></i></a>
        <h5 class="fw-bold mb-0">{{ $liquidation->reference }}</h5>
    </div>
    @php $b=['en_attente'=>'warning','en_cours'=>'info','execute'=>'success','annule'=>'danger']; @endphp
    <span class="badge fs-6 bg-{{ $b[$liquidation->statut]??'secondary' }} {{ $liquidation->statut=='en_attente'?'text-dark':'' }}">{{ str_replace('_',' ',$liquidation->statut) }}</span>
</div>
<div class="row g-3">
    <div class="col-md-6">
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white fw-semibold">Détails</div>
            <div class="card-body">
                <table class="table table-sm table-borderless">
                    <tr><td class="text-muted">Propriétaire</td><td class="fw-semibold">{{ $liquidation->user->prenom ?? '' }} {{ $liquidation->user->nom ?? '' }}</td></tr>
                    <tr><td class="text-muted">Type</td><td>{{ ucfirst($liquidation->type) }}</td></tr>
                    <tr><td class="text-muted">Mode</td><td>{{ ucfirst($liquidation->mode) }}</td></tr>
                    <tr><td class="text-muted">Valeur totale</td><td class="fw-bold text-success">{{ number_format($liquidation->valeur_totale) }} XOF</td></tr>
                    <tr><td class="text-muted">Testament lié</td><td>{{ $liquidation->testament->reference ?? '—' }}</td></tr>
                    @if($liquidation->traitePar)<tr><td class="text-muted">Traité par</td><td>{{ $liquidation->traitePar->prenom }} {{ $liquidation->traitePar->nom }}</td></tr>@endif
                    @if($liquidation->date_execution)<tr><td class="text-muted">Exécuté le</td><td>{{ \Carbon\Carbon::parse($liquidation->date_execution)->format('d/m/Y H:i') }}</td></tr>@endif
                </table>
                @if($liquidation->notes)<div class="alert alert-light small mt-2">{{ $liquidation->notes }}</div>@endif
            </div>
        </div>
    </div>
    <div class="col-md-6">
        @if($liquidation->statut === 'en_attente')
        <div class="card mb-3" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-body">
                <form method="POST" action="{{ route('admin.liquidations.executer', $liquidation) }}">
                    @csrf
                    <p class="small text-muted">Cette action va marquer tous les actifs concernés comme vendus/transférés.</p>
                    <button class="btn btn-success w-100 mb-2" onclick="return confirm('Exécuter cette liquidation ?')"><i class="bi bi-play-circle me-1"></i>Exécuter la liquidation</button>
                </form>
                <form method="POST" action="{{ route('admin.liquidations.annuler', $liquidation) }}">
                    @csrf
                    <button class="btn btn-outline-danger w-100" onclick="return confirm('Annuler cette liquidation ?')"><i class="bi bi-x-circle me-1"></i>Annuler</button>
                </form>
            </div>
        </div>
        @endif
        @if($liquidation->statut === 'execute')
        <div class="alert alert-success"><i class="bi bi-check-circle-fill me-2"></i>Liquidation exécutée avec succès le {{ \Carbon\Carbon::parse($liquidation->date_execution)->format('d/m/Y') }}.</div>
        @endif
    </div>
</div>
@endsection
