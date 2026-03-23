@extends('layouts.admin')
@section('title', 'Testaments')
@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <h5 class="fw-bold mb-0">Testaments</h5>
</div>
<div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
                <tr><th>Référence</th><th>Testateur</th><th>Notaire assigné</th><th>Statut</th><th>Date</th><th>Actions</th></tr>
            </thead>
            <tbody>
                @forelse($testaments as $t)
                <tr>
                    <td class="fw-semibold text-primary">{{ $t->reference }}</td>
                    <td class="small">{{ $t->user->prenom ?? '' }} {{ $t->user->nom ?? '' }}</td>
                    <td class="small">{{ $t->notaire ? $t->notaire->prenom . ' ' . $t->notaire->nom : '—' }}</td>
                    <td>
                        @php $b=['brouillon'=>'secondary','finalise'=>'info','certifie'=>'success','revoque'=>'danger']; @endphp
                        <span class="badge bg-{{ $b[$t->statut]??'secondary' }}">{{ ucfirst($t->statut) }}</span>
                    </td>
                    <td class="small text-muted">{{ $t->created_at->format('d/m/Y') }}</td>
                    <td>
                        <a href="{{ route('admin.testaments.show', $t) }}" class="btn btn-sm btn-outline-primary"><i class="bi bi-eye"></i></a>
                    </td>
                </tr>
                @empty
                <tr><td colspan="6" class="text-center py-4 text-muted"><i class="bi bi-journal-x fs-2 d-block mb-2"></i>Aucun testament</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div class="card-footer bg-white">{{ $testaments->links() }}</div>
</div>
@endsection
