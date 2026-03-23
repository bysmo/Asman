<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $role  = $request->get('role', 'all');
        $query = User::query();

        if ($role !== 'all') {
            $query->where('role', $role);
        }

        $users = $query->orderByDesc('created_at')->paginate(20);
        return view('admin.users.index', compact('users', 'role'));
    }

    public function create()
    {
        return view('admin.users.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'nom'     => 'required|string',
            'prenom'  => 'required|string',
            'email'   => 'required|email|unique:users',
            'role'    => 'required|in:client,notaire,huissier,avocat,admin',
            'password' => 'required|min:8|confirmed',
        ]);

        User::create([
            'nom'       => $request->nom,
            'prenom'    => $request->prenom,
            'email'     => $request->email,
            'role'      => $request->role,
            'password'  => Hash::make($request->password),
            'telephone' => $request->telephone,
            'pays'      => $request->pays ?? 'BF',
            'statut'    => 'actif',
            'numero_professionnel' => $request->numero_professionnel,
            'ordre_professionnel'  => $request->ordre_professionnel,
            'cabinet'              => $request->cabinet,
            'juridiction'          => $request->juridiction,
        ]);

        return redirect()->route('admin.users.index')->with('success', 'Utilisateur créé avec succès.');
    }

    public function show(User $user)
    {
        $user->load(['assets', 'certifications', 'testaments']);
        return view('admin.users.show', compact('user'));
    }

    public function edit(User $user)
    {
        return view('admin.users.edit', compact('user'));
    }

    public function update(Request $request, User $user)
    {
        $request->validate([
            'nom'    => 'required|string',
            'prenom' => 'required|string',
            'email'  => ['required', 'email', Rule::unique('users')->ignore($user->id)],
            'role'   => 'required|in:client,notaire,huissier,avocat,admin',
        ]);

        $data = $request->except(['password', 'password_confirmation', '_token', '_method']);

        if ($request->filled('password')) {
            $request->validate(['password' => 'min:8|confirmed']);
            $data['password'] = Hash::make($request->password);
        }

        $user->update($data);
        return redirect()->route('admin.users.show', $user)->with('success', 'Utilisateur mis à jour.');
    }

    public function destroy(User $user)
    {
        $user->delete();
        return redirect()->route('admin.users.index')->with('success', 'Utilisateur supprimé.');
    }

    public function activate(User $user)
    {
        $user->update(['statut' => 'actif']);
        return back()->with('success', 'Compte activé.');
    }

    public function deactivate(User $user)
    {
        $user->update(['statut' => 'suspendu']);
        return back()->with('success', 'Compte suspendu.');
    }

    public function changeRole(Request $request, User $user)
    {
        $request->validate(['role' => 'required|in:client,notaire,huissier,avocat,admin']);
        $user->update(['role' => $request->role]);
        return back()->with('success', 'Rôle modifié.');
    }
}
