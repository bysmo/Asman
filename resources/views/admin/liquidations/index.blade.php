@extends('layouts.admin')
@section('title', 'Liquidations')
@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <h5 class="fw-bold mb-0">Liquidations</h5>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#newLiqModal">
        <i class="bi bi-plus me-1"></i>Nouvelle liquidation
    </button>
</div>
<div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
                <tr><th>Référence</th><th>Utilisateur</th><th>Type</th><th>Mode</th><th>Valeur</th><th>Statut</th><th>Actions</th></tr>
            </thead>
            <tbody>
                @forelse($liquidations as $l)
                <tr>
                    <td class="fw-semibold text-primary">{{ $l->reference }}</td>
                    <td class="small">{{ $l->user->prenom ?? '' }} {{ $l->user->nom ?? '' }}</td>
                    <td><span class="badge bg-secondary">{{ ucfirst($l->type) }}</span></td>
                    <td><span class="badge bg-{{ $l->mode=='automatique'?'info':'warning text-dark' }}">{{ ucfirst($l->mode) }}</span></td>
                    <td class="small fw-bold">{{ number_format($l->valeur_totale) }} XOF</td>
                    <td>
                        @php $b=['en_attente'=>'warning','en_cours'=>'info','execute'=>'success','annule'=>'danger']; @endphp
                        <span class="badge bg-{{ $b[$l->statut]??'secondary' }} {{ $l->statut=='en_attente'?'text-dark':'' }}">{{ str_replace('_',' ',$l->statut) }}</span>
                    </td>
                    <td>
                        <a href="{{ route('admin.liquidations.show', $l) }}" class="btn btn-sm btn-outline-primary"><i class="bi bi-eye"></i></a>
                    </td>
                </tr>
                @empty
                <tr><td colspan="7" class="text-center py-4 text-muted">Aucune liquidation</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div class="card-footer bg-white">{{ $liquidations->links() }}</div>
</div>
@endsection
