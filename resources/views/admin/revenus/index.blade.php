@extends('layouts.admin')
@section('title', 'Revenus & Partage')
@section('content')
<div class="row g-3 mb-4">
    <div class="col-md-3">
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-body text-center">
                <div class="text-muted small mb-1">Total Plateforme (30%)</div>
                <div class="fw-bold fs-4 text-primary">{{ number_format($stats['plateforme_total']) }} XOF</div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-body text-center">
                <div class="text-muted small mb-1">Total Autorités (70%)</div>
                <div class="fw-bold fs-4 text-success">{{ number_format($stats['autorites_total']) }} XOF</div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-body text-center">
                <div class="text-muted small mb-1">En attente distribution</div>
                <div class="fw-bold fs-4 text-warning">{{ number_format($stats['en_attente']) }} XOF</div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-body text-center">
                <div class="text-muted small mb-1">Distribué</div>
                <div class="fw-bold fs-4 text-success">{{ number_format($stats['distribue']) }} XOF</div>
            </div>
        </div>
    </div>
</div>

<div class="row g-3">
    <div class="col-md-5">
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white fw-semibold">Revenus par autorité (en attente)</div>
            <div class="card-body p-0">
                <table class="table table-hover mb-0">
                    <thead class="table-light"><tr><th>Autorité</th><th>Rôle</th><th>Montant</th><th>Action</th></tr></thead>
                    <tbody>
                        @forelse($par_autorite as $a)
                        <tr>
                            <td class="fw-semibold small">{{ $a->prenom }} {{ $a->nom }}</td>
                            <td><span class="badge bg-secondary">{{ ucfirst($a->role) }}</span></td>
                            <td class="fw-bold text-success small">{{ number_format($a->total_revenus ?? 0) }} XOF</td>
                            <td>
                                @if(($a->total_revenus ?? 0) > 0)
                                <form method="POST" action="{{ route('admin.revenus.distribuer') }}" class="d-inline">
                                    @csrf
                                    <input type="hidden" name="autorite_id" value="{{ $a->id }}">
                                    <button class="btn btn-xs btn-success" style="padding:2px 8px;font-size:.75rem;" onclick="return confirm('Marquer comme distribué ?')">Distribuer</button>
                                </form>
                                @endif
                            </td>
                        </tr>
                        @empty
                        <tr><td colspan="4" class="text-center py-3 text-muted">Aucun revenu en attente</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <div class="col-md-7">
        <div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
            <div class="card-header bg-white d-flex justify-content-between">
                <span class="fw-semibold">Transactions récentes</span>
                <a href="{{ route('admin.revenus.rapport') }}" class="btn btn-sm btn-outline-primary">Rapport mensuel</a>
            </div>
            <div class="card-body p-0">
                <table class="table table-hover mb-0">
                    <thead class="table-light"><tr><th>Certification</th><th>Autorité</th><th>Autorite (70%)</th><th>Asman (30%)</th><th>Statut</th></tr></thead>
                    <tbody>
                        @forelse($recent as $s)
                        <tr>
                            <td class="small">{{ $s->certification->reference ?? '—' }}</td>
                            <td class="small">{{ $s->autorite->prenom ?? '' }} {{ $s->autorite->nom ?? '' }}</td>
                            <td class="small fw-bold text-success">{{ number_format($s->montant_autorite) }}</td>
                            <td class="small fw-bold text-primary">{{ number_format($s->montant_plateforme) }}</td>
                            <td><span class="badge bg-{{ $s->statut=='distribue'?'success':'warning text-dark' }}">{{ $s->statut }}</span></td>
                        </tr>
                        @empty
                        <tr><td colspan="5" class="text-center py-3 text-muted">Aucune transaction</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
@endsection
