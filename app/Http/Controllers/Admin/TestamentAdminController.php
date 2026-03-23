<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Testament;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TestamentAdminController extends Controller
{
    public function index()
    {
        $testaments = Testament::with(['user', 'notaire'])
            ->orderByDesc('created_at')
            ->paginate(20);
        return view('admin.testaments.index', compact('testaments'));
    }

    public function show(Testament $testament)
    {
        $testament->load(['user', 'notaire', 'ayantsDroit', 'allocations.asset']);
        return view('admin.testaments.show', compact('testament'));
    }

    public function certifier(Request $request, Testament $testament)
    {
        abort_if($testament->statut !== 'finalise', 403, 'Seul un testament finalisé peut être certifié.');

        $testament->update([
            'statut'             => 'certifie',
            'notaire_id'         => Auth::id(),
            'date_certification' => now()->toDateString(),
        ]);

        return redirect()->route('admin.testaments.show', $testament)
            ->with('success', 'Testament certifié par ' . Auth::user()->prenom . ' ' . Auth::user()->nom . '.');
    }
}
