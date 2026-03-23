@extends('layouts.admin')
@section('title', 'Nouvel utilisateur')
@section('content')
<div class="d-flex align-items-center mb-4 gap-3">
    <a href="{{ route('admin.users.index') }}" class="btn btn-sm btn-outline-secondary"><i class="bi bi-arrow-left"></i></a>
    <h5 class="fw-bold mb-0">Créer un utilisateur</h5>
</div>
<div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);max-width:700px;">
    <div class="card-body p-4">
        <form method="POST" action="{{ route('admin.users.store') }}">
            @csrf
            <div class="row g-3">
                <div class="col-md-6"><label class="form-label fw-semibold">Prénom *</label><input type="text" name="prenom" class="form-control @error('prenom') is-invalid @enderror" value="{{ old('prenom') }}" required><div class="invalid-feedback">@error('prenom'){{ $message }}@enderror</div></div>
                <div class="col-md-6"><label class="form-label fw-semibold">Nom *</label><input type="text" name="nom" class="form-control @error('nom') is-invalid @enderror" value="{{ old('nom') }}" required></div>
                <div class="col-md-6"><label class="form-label fw-semibold">Email *</label><input type="email" name="email" class="form-control @error('email') is-invalid @enderror" value="{{ old('email') }}" required><div class="invalid-feedback">@error('email'){{ $message }}@enderror</div></div>
                <div class="col-md-6"><label class="form-label fw-semibold">Téléphone</label><input type="text" name="telephone" class="form-control" value="{{ old('telephone') }}"></div>
                <div class="col-md-6">
                    <label class="form-label fw-semibold">Rôle *</label>
                    <select name="role" class="form-select" required>
                        <option value="client" {{ old('role')=='client'?'selected':'' }}>Client</option>
                        <option value="notaire" {{ old('role')=='notaire'?'selected':'' }}>Notaire</option>
                        <option value="huissier" {{ old('role')=='huissier'?'selected':'' }}>Huissier</option>
                        <option value="avocat" {{ old('role')=='avocat'?'selected':'' }}>Avocat</option>
                        <option value="admin" {{ old('role')=='admin'?'selected':'' }}>Admin</option>
                    </select>
                </div>
                <div class="col-md-6"><label class="form-label fw-semibold">Pays</label><input type="text" name="pays" class="form-control" value="{{ old('pays','BF') }}"></div>
                <div class="col-md-6"><label class="form-label fw-semibold">Mot de passe *</label><input type="password" name="password" class="form-control @error('password') is-invalid @enderror" required><div class="invalid-feedback">@error('password'){{ $message }}@enderror</div></div>
                <div class="col-md-6"><label class="form-label fw-semibold">Confirmer mot de passe *</label><input type="password" name="password_confirmation" class="form-control" required></div>
                <div class="col-12"><hr><p class="text-muted small fw-semibold mb-2">Informations professionnelles (notaire/huissier/avocat)</p></div>
                <div class="col-md-6"><label class="form-label small">N° professionnel</label><input type="text" name="numero_professionnel" class="form-control" value="{{ old('numero_professionnel') }}"></div>
                <div class="col-md-6"><label class="form-label small">Ordre professionnel</label><input type="text" name="ordre_professionnel" class="form-control" value="{{ old('ordre_professionnel') }}"></div>
                <div class="col-md-6"><label class="form-label small">Cabinet</label><input type="text" name="cabinet" class="form-control" value="{{ old('cabinet') }}"></div>
                <div class="col-md-6"><label class="form-label small">Juridiction</label><input type="text" name="juridiction" class="form-control" value="{{ old('juridiction') }}"></div>
                <div class="col-12 d-flex gap-2 justify-content-end">
                    <a href="{{ route('admin.users.index') }}" class="btn btn-outline-secondary">Annuler</a>
                    <button class="btn btn-primary"><i class="bi bi-person-plus me-1"></i>Créer</button>
                </div>
            </div>
        </form>
    </div>
</div>
@endsection
