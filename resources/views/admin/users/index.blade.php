@extends('layouts.admin')
@section('title', 'Gestion des utilisateurs')
@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <h5 class="fw-bold mb-0">Utilisateurs</h5>
    <a href="{{ route('admin.users.create') }}" class="btn btn-primary">
        <i class="bi bi-plus me-1"></i>Nouvel utilisateur
    </a>
</div>
<div class="mb-3 d-flex gap-2 flex-wrap">
    @foreach(['all'=>'Tous','client'=>'Clients','notaire'=>'Notaires','huissier'=>'Huissiers','avocat'=>'Avocats','admin'=>'Admins'] as $r => $label)
    <a href="{{ request()->fullUrlWithQuery(['role'=>$r]) }}" class="btn btn-sm {{ $role==$r ? 'btn-primary' : 'btn-outline-secondary' }}">{{ $label }}</a>
    @endforeach
</div>
<div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
                <tr><th>Nom</th><th>Email</th><th>Rôle</th><th>KYC</th><th>Statut</th><th>Inscrit le</th><th>Actions</th></tr>
            </thead>
            <tbody>
                @forelse($users as $user)
                <tr>
                    <td><span class="fw-semibold">{{ $user->prenom }} {{ $user->nom }}</span></td>
                    <td class="small text-muted">{{ $user->email }}</td>
                    <td>
                        @php $colors=['client'=>'#37474F','notaire'=>'#1565C0','huissier'=>'#2E7D32','avocat'=>'#E65100','admin'=>'#7B1FA2']; @endphp
                        <span class="badge" style="background:{{ $colors[$user->role]??'#999' }}">{{ ucfirst($user->role) }}</span>
                    </td>
                    <td><span class="badge bg-{{ $user->kyc_statut=='approuve'?'success':($user->kyc_statut=='en_attente'?'warning text-dark':'secondary') }}">{{ str_replace('_',' ',$user->kyc_statut) }}</span></td>
                    <td><span class="badge bg-{{ $user->statut=='actif'?'success':($user->statut=='suspendu'?'danger':'secondary') }}">{{ $user->statut }}</span></td>
                    <td class="small text-muted">{{ $user->created_at->format('d/m/Y') }}</td>
                    <td class="d-flex gap-1">
                        <a href="{{ route('admin.users.show', $user) }}" class="btn btn-xs btn-outline-primary" style="padding:2px 8px;font-size:.75rem;"><i class="bi bi-eye"></i></a>
                        <a href="{{ route('admin.users.edit', $user) }}" class="btn btn-xs btn-outline-secondary" style="padding:2px 8px;font-size:.75rem;"><i class="bi bi-pencil"></i></a>
                    </td>
                </tr>
                @empty
                <tr><td colspan="7" class="text-center py-4 text-muted">Aucun utilisateur</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div class="card-footer bg-white">{{ $users->links() }}</div>
</div>
@endsection
