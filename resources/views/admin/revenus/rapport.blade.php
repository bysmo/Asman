@extends('layouts.admin')
@section('title', 'Rapport mensuel - ' . $mois)
@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <div class="d-flex align-items-center gap-3">
        <a href="{{ route('admin.revenus.index') }}" class="btn btn-sm btn-outline-secondary"><i class="bi bi-arrow-left"></i></a>
        <h5 class="fw-bold mb-0">Rapport : {{ \Carbon\Carbon::parse($mois.'-01')->format('F Y') }}</h5>
    </div>
    <form class="d-flex gap-2">
        <input type="month" name="mois" value="{{ $mois }}" class="form-control form-control-sm">
        <button class="btn btn-sm btn-primary">Appliquer</button>
    </form>
</div>
<div class="row g-3 mb-4">
    @foreach($repartition as $r)
    <div class="col-md-4">
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-body text-center">
                <div class="fw-bold fs-5">{{ ucfirst($r->type_autorite) }}</div>
                <div class="text-muted small mb-2">{{ $r->nb }} certification(s)</div>
                <div class="text-success fw-bold">{{ number_format($r->total_autorite) }} XOF <small class="text-muted">(70%)</small></div>
                <div class="text-primary fw-bold">{{ number_format($r->total_plateforme) }} XOF <small class="text-muted">(30%)</small></div>
                <div class="text-dark fw-bold mt-1 border-top pt-2">Total : {{ number_format($r->total_frais) }} XOF</div>
            </div>
        </div>
    </div>
    @endforeach
</div>
<div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
    <div class="card-header bg-white fw-semibold">Transactions du mois</div>
    <div class="table-responsive">
        <table class="table table-hover mb-0">
            <thead class="table-light"><tr><th>Certification</th><th>Actif</th><th>Autorité</th><th>Autorité (70%)</th><th>Asman (30%)</th><th>Statut</th></tr></thead>
            <tbody>
                @forelse($shares as $s)
                <tr>
                    <td class="small">{{ $s->certification->reference ?? '—' }}</td>
                    <td class="small">{{ $s->certification->asset->nom ?? '—' }}</td>
                    <td class="small fw-semibold">{{ $s->autorite->prenom ?? '' }} {{ $s->autorite->nom ?? '' }}</td>
                    <td class="small fw-bold text-success">{{ number_format($s->montant_autorite) }} XOF</td>
                    <td class="small fw-bold text-primary">{{ number_format($s->montant_plateforme) }} XOF</td>
                    <td><span class="badge bg-{{ $s->statut=='distribue'?'success':'warning text-dark' }}">{{ $s->statut }}</span></td>
                </tr>
                @empty<tr><td colspan="6" class="text-center py-4 text-muted">Aucune transaction ce mois</td></tr>@endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
