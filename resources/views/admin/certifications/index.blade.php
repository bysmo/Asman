@extends('layouts.admin')
@section('title', 'Certifications')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <h5 class="fw-bold mb-0">Demandes de certification</h5>
    <div class="d-flex gap-2">
        <form class="d-flex gap-2">
            <select name="statut" class="form-select form-select-sm">
                <option value="">Tous statuts</option>
                <option value="en_attente" {{ request('statut')=='en_attente' ? 'selected' : '' }}>En attente</option>
                <option value="en_cours" {{ request('statut')=='en_cours' ? 'selected' : '' }}>En cours</option>
                <option value="certifie" {{ request('statut')=='certifie' ? 'selected' : '' }}>Certifié</option>
                <option value="refuse" {{ request('statut')=='refuse' ? 'selected' : '' }}>Refusé</option>
            </select>
            <select name="type_autorite" class="form-select form-select-sm">
                <option value="">Tous types</option>
                <option value="notaire" {{ request('type_autorite')=='notaire' ? 'selected' : '' }}>Notaire</option>
                <option value="huissier" {{ request('type_autorite')=='huissier' ? 'selected' : '' }}>Huissier</option>
                <option value="avocat" {{ request('type_autorite')=='avocat' ? 'selected' : '' }}>Avocat</option>
            </select>
            <button class="btn btn-sm btn-primary">Filtrer</button>
        </form>
    </div>
</div>

<div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
                <tr>
                    <th>Référence</th>
                    <th>Actif</th>
                    <th>Demandeur</th>
                    <th>Type</th>
                    <th>Assigné à</th>
                    <th>Statut</th>
                    <th>Frais</th>
                    <th>Date</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse($certifications as $cert)
                <tr>
                    <td><span class="fw-semibold text-primary">{{ $cert->reference }}</span></td>
                    <td>
                        <div class="fw-semibold small">{{ $cert->asset->nom ?? '—' }}</div>
                        <div class="text-muted" style="font-size:0.72rem;">{{ $cert->asset->type ?? '' }}</div>
                    </td>
                    <td class="small">{{ $cert->user->prenom ?? '' }} {{ $cert->user->nom ?? '' }}</td>
                    <td>
                        <span class="badge" style="background: @switch($cert->type_autorite) @case('notaire') #1565C0 @break @case('huissier') #2E7D32 @break @case('avocat') #E65100 @break @default #37474F @endswitch;">
                            {{ ucfirst($cert->type_autorite) }}
                        </span>
                    </td>
                    <td class="small">{{ $cert->assigneA ? $cert->assigneA->prenom . ' ' . $cert->assigneA->nom : '—' }}</td>
                    <td>
                        @php $badges = ['en_attente'=>['warning','dark'],'en_cours'=>['info','white'],'certifie'=>['success','white'],'refuse'=>['danger','white'],'annule'=>['secondary','white']]; $b = $badges[$cert->statut] ?? ['secondary','white']; @endphp
                        <span class="badge bg-{{ $b[0] }} text-{{ $b[1] }}">{{ str_replace('_', ' ', $cert->statut) }}</span>
                    </td>
                    <td class="small">{{ $cert->frais > 0 ? number_format($cert->frais) . ' XOF' : '—' }}</td>
                    <td class="small text-muted">{{ $cert->created_at->format('d/m/Y') }}</td>
                    <td>
                        <a href="{{ route('admin.certifications.show', $cert) }}" class="btn btn-sm btn-outline-primary">
                            <i class="bi bi-eye"></i>
                        </a>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="9" class="text-center text-muted py-4">
                        <i class="bi bi-inbox fs-2 d-block mb-2"></i>
                        Aucune certification trouvée
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div class="card-footer bg-white border-top">
        {{ $certifications->withQueryString()->links() }}
    </div>
</div>
@endsection
