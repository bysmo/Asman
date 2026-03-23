@extends('layouts.admin')
@section('title', 'Tableau de bord')

@section('content')
<!-- Stats globales -->
<div class="row g-3 mb-4">
    <div class="col-md-3">
        <div class="card stat-card h-100">
            <div class="card-body d-flex align-items-center gap-3">
                <div style="width:48px;height:48px;background:#E3F2FD;border-radius:12px;display:flex;align-items:center;justify-content:center;">
                    <i class="bi bi-people fs-4 text-primary"></i>
                </div>
                <div>
                    <div class="text-muted small">Clients</div>
                    <div class="fw-bold fs-4">{{ number_format($stats['utilisateurs']) }}</div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stat-card h-100">
            <div class="card-body d-flex align-items-center gap-3">
                <div style="width:48px;height:48px;background:#F3E5F5;border-radius:12px;display:flex;align-items:center;justify-content:center;">
                    <i class="bi bi-person-badge fs-4 text-purple" style="color:#7B1FA2;"></i>
                </div>
                <div>
                    <div class="text-muted small">Autorités</div>
                    <div class="fw-bold fs-4">{{ number_format($stats['autorites']) }}</div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stat-card h-100">
            <div class="card-body d-flex align-items-center gap-3">
                <div style="width:48px;height:48px;background:#E8F5E9;border-radius:12px;display:flex;align-items:center;justify-content:center;">
                    <i class="bi bi-house fs-4 text-success"></i>
                </div>
                <div>
                    <div class="text-muted small">Actifs enregistrés</div>
                    <div class="fw-bold fs-4">{{ number_format($stats['assets']) }}</div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stat-card h-100">
            <div class="card-body d-flex align-items-center gap-3">
                <div style="width:48px;height:48px;background:#FFF8E1;border-radius:12px;display:flex;align-items:center;justify-content:center;">
                    <i class="bi bi-patch-check fs-4" style="color:#F57F17;"></i>
                </div>
                <div>
                    <div class="text-muted small">Certifications</div>
                    <div class="fw-bold fs-4">{{ number_format($stats['certifications_total']) }}</div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Certifications détail + Revenus -->
<div class="row g-3 mb-4">
    <div class="col-md-8">
        <div class="card stat-card">
            <div class="card-header bg-white border-bottom-0 pt-3 pb-0">
                <h6 class="fw-bold mb-0">État des certifications</h6>
            </div>
            <div class="card-body">
                <div class="row text-center g-2">
                    <div class="col-4">
                        <div class="p-3 rounded-3" style="background:#FFF3E0;">
                            <div class="fw-bold fs-3" style="color:#E65100;">{{ $stats['certifications_attente'] }}</div>
                            <small class="text-muted">En attente</small>
                        </div>
                    </div>
                    <div class="col-4">
                        <div class="p-3 rounded-3" style="background:#E3F2FD;">
                            <div class="fw-bold fs-3 text-primary">{{ $stats['certifications_cours'] }}</div>
                            <small class="text-muted">En cours</small>
                        </div>
                    </div>
                    <div class="col-4">
                        <div class="p-3 rounded-3" style="background:#E8F5E9;">
                            <div class="fw-bold fs-3 text-success">{{ $stats['certifications_ok'] }}</div>
                            <small class="text-muted">Certifiés</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card stat-card" style="background: linear-gradient(135deg, #1A237E, #283593); color: white;">
            <div class="card-body">
                <div class="mb-3">
                    <div class="small opacity-75">Revenus Plateforme (30%)</div>
                    <div class="fw-bold fs-5">{{ number_format($stats['revenus_plateforme']) }} XOF</div>
                </div>
                <div>
                    <div class="small opacity-75">Revenus Autorités (70%)</div>
                    <div class="fw-bold fs-5" style="color:#FFD700;">{{ number_format($stats['revenus_autorites']) }} XOF</div>
                </div>
                <div class="mt-3 pt-2 border-top border-white border-opacity-25">
                    <small class="opacity-75">Testaments : {{ $stats['testaments_certifies'] }}/{{ $stats['testaments'] }} certifiés</small>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row g-3">
    <!-- Certifications récentes -->
    <div class="col-md-7">
        <div class="card stat-card">
            <div class="card-header bg-white d-flex justify-content-between align-items-center">
                <h6 class="mb-0 fw-bold">Certifications récentes</h6>
                <a href="{{ route('admin.certifications.index') }}" class="btn btn-sm btn-outline-primary">Voir tout</a>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="small">Référence</th>
                                <th class="small">Actif</th>
                                <th class="small">Statut</th>
                                <th class="small">Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($recent_certifications as $cert)
                            <tr>
                                <td><a href="{{ route('admin.certifications.show', $cert) }}" class="text-decoration-none fw-semibold small">{{ $cert->reference }}</a></td>
                                <td class="small">{{ $cert->asset->nom ?? '—' }}</td>
                                <td>
                                    @php
                                    $badges = ['en_attente'=>'warning','en_cours'=>'info','certifie'=>'success','refuse'=>'danger','annule'=>'secondary'];
                                    @endphp
                                    <span class="badge bg-{{ $badges[$cert->statut] ?? 'secondary' }} text-{{ $cert->statut === 'en_attente' ? 'dark' : 'white' }}">
                                        {{ str_replace('_', ' ', $cert->statut) }}
                                    </span>
                                </td>
                                <td class="small text-muted">{{ $cert->created_at->format('d/m/Y') }}</td>
                            </tr>
                            @empty
                            <tr><td colspan="4" class="text-center text-muted py-3">Aucune certification</td></tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Top autorités -->
    <div class="col-md-5">
        <div class="card stat-card">
            <div class="card-header bg-white">
                <h6 class="mb-0 fw-bold">Top Autorités</h6>
            </div>
            <div class="card-body">
                @forelse($top_autorites as $i => $autorite)
                <div class="d-flex align-items-center gap-3 mb-3">
                    <div style="width:36px;height:36px;border-radius:50%;background:#E3F2FD;display:flex;align-items:center;justify-content:center;font-weight:700;color:#1565C0;">
                        {{ $i + 1 }}
                    </div>
                    <div class="flex-grow-1">
                        <div class="fw-semibold small">{{ $autorite->prenom }} {{ $autorite->nom }}</div>
                        <div class="text-muted" style="font-size:0.75rem;">{{ ucfirst($autorite->role) }}</div>
                    </div>
                    <span class="badge bg-primary">{{ $autorite->nb_certifications }} cert.</span>
                </div>
                @empty
                <p class="text-muted text-center">Aucune autorité</p>
                @endforelse
            </div>
        </div>
    </div>
</div>
@endsection
