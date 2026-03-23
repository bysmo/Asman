@extends('layouts.admin')
@section('title', 'Modifier ' . $user->prenom . ' ' . $user->nom)
@section('content')
<div class="d-flex align-items-center mb-4 gap-3">
    <a href="{{ route('admin.users.show', $user) }}" class="btn btn-sm btn-outline-secondary"><i class="bi bi-arrow-left"></i></a>
    <h5 class="fw-bold mb-0">Modifier : {{ $user->prenom }} {{ $user->nom }}</h5>
</div>
<div class="card" style="border:none;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);max-width:700px;">
    <div class="card-body p-4">
        <form method="POST" action="{{ route('admin.users.update', $user) }}">
            @csrf @method('PUT')
            <div class="row g-3">
                <div class="col-md-6"><label class="form-label fw-semibold">Prénom *</label><input type="text" name="prenom" class="form-control" value="{{ old('prenom', $user->prenom) }}" required></div>
                <div class="col-md-6"><label class="form-label fw-semibold">Nom *</label><input type="text" name="nom" class="form-control" value="{{ old('nom', $user->nom) }}" required></div>
                <div class="col-md-6"><label class="form-label fw-semibold">Email *</label><input type="email" name="email" class="form-control" value="{{ old('email', $user->email) }}" required></div>
                <div class="col-md-6"><label class="form-label fw-semibold">Téléphone</label><input type="text" name="telephone" class="form-control" value="{{ old('telephone', $user->telephone) }}"></div>
                <div class="col-md-6">
                    <label class="form-label fw-semibold">Rôle *</label>
                    <select name="role" class="form-select" required>
                        @foreach(['client','notaire','huissier','avocat','admin'] as $r)
                        <option value="{{ $r }}" {{ old('role',$user->role)==$r?'selected':'' }}>{{ ucfirst($r) }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-semibold">Statut</label>
                    <select name="statut" class="form-select">
                        @foreach(['actif','inactif','suspendu'] as $s)
                        <option value="{{ $s }}" {{ old('statut',$user->statut)==$s?'selected':'' }}>{{ ucfirst($s) }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-6"><label class="form-label small">Nouveau mot de passe <span class="text-muted">(laisser vide = inchangé)</span></label><input type="password" name="password" class="form-control"></div>
                <div class="col-md-6"><label class="form-label small">Confirmer</label><input type="password" name="password_confirmation" class="form-control"></div>
                <div class="col-md-6"><label class="form-label small">N° professionnel</label><input type="text" name="numero_professionnel" class="form-control" value="{{ old('numero_professionnel',$user->numero_professionnel) }}"></div>
                <div class="col-md-6"><label class="form-label small">Cabinet</label><input type="text" name="cabinet" class="form-control" value="{{ old('cabinet',$user->cabinet) }}"></div>
                <div class="col-12 d-flex gap-2 justify-content-end">
                    <a href="{{ route('admin.users.show', $user) }}" class="btn btn-outline-secondary">Annuler</a>
                    <button class="btn btn-primary"><i class="bi bi-save me-1"></i>Sauvegarder</button>
                </div>
            </div>
        </form>
    </div>
</div>
@endsection
