<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Asman Admin - @yield('title', 'Tableau de bord')</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        :root {
            --sidebar-width: 260px;
            --asman-primary: #1A237E;
            --asman-gold: #FFD700;
            --asman-accent: #FFA000;
        }
        body { background: #F5F7FA; font-family: 'Segoe UI', sans-serif; }
        .sidebar {
            width: var(--sidebar-width);
            min-height: 100vh;
            background: linear-gradient(180deg, var(--asman-primary) 0%, #283593 100%);
            position: fixed; top: 0; left: 0; z-index: 100;
            box-shadow: 2px 0 10px rgba(0,0,0,0.2);
        }
        .sidebar .brand {
            padding: 20px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            text-align: center;
        }
        .sidebar .brand h4 { color: var(--asman-gold); font-weight: 700; margin: 0; font-size: 1.4rem; }
        .sidebar .brand small { color: rgba(255,255,255,0.6); font-size: 0.7rem; }
        .sidebar .nav-link {
            color: rgba(255,255,255,0.8) !important;
            padding: 10px 20px;
            border-radius: 8px;
            margin: 2px 10px;
            transition: all 0.2s;
            font-size: 0.9rem;
        }
        .sidebar .nav-link:hover,
        .sidebar .nav-link.active {
            background: rgba(255,215,0,0.15) !important;
            color: var(--asman-gold) !important;
        }
        .sidebar .nav-link i { width: 20px; }
        .main-content { margin-left: var(--sidebar-width); padding: 0; min-height: 100vh; }
        .topbar {
            background: white;
            padding: 12px 24px;
            border-bottom: 1px solid #e0e0e0;
            display: flex;
            justify-content: space-between;
            align-items: center;
            position: sticky; top: 0; z-index: 99;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        .content-area { padding: 24px; }
        .stat-card {
            border: none;
            border-radius: 12px;
            transition: transform 0.2s;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }
        .stat-card:hover { transform: translateY(-2px); }
        .badge-role-admin    { background: #7B1FA2; }
        .badge-role-notaire  { background: #1565C0; }
        .badge-role-huissier { background: #2E7D32; }
        .badge-role-avocat   { background: #E65100; }
        .badge-role-client   { background: #37474F; }
        .nav-section { padding: 12px 20px 4px; color: rgba(255,255,255,0.4); font-size: 0.7rem; text-transform: uppercase; letter-spacing: 1px; }
    </style>
    @stack('styles')
</head>
<body>

<!-- Sidebar -->
<div class="sidebar">
    <div class="brand">
        <h4>⚖️ ASMAN</h4>
        <small>Gestion de Patrimoine</small>
    </div>
    <nav class="mt-3">
        <div class="nav-section">Navigation</div>
        <a href="{{ route('admin.dashboard') }}" class="nav-link d-flex align-items-center gap-2 {{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
            <i class="bi bi-speedometer2"></i> Dashboard
        </a>

        @if(auth()->user()->isAdmin())
        <div class="nav-section">Gestion</div>
        <a href="{{ route('admin.users.index') }}" class="nav-link d-flex align-items-center gap-2 {{ request()->routeIs('admin.users*') ? 'active' : '' }}">
            <i class="bi bi-people"></i> Utilisateurs
        </a>
        <a href="{{ route('admin.liquidations.index') }}" class="nav-link d-flex align-items-center gap-2 {{ request()->routeIs('admin.liquidations*') ? 'active' : '' }}">
            <i class="bi bi-shuffle"></i> Liquidations
        </a>
        <a href="{{ route('admin.revenus.index') }}" class="nav-link d-flex align-items-center gap-2 {{ request()->routeIs('admin.revenus*') ? 'active' : '' }}">
            <i class="bi bi-bar-chart"></i> Revenus & Partage
        </a>
        @endif

        <div class="nav-section">Certification</div>
        <a href="{{ route('admin.certifications.index') }}" class="nav-link d-flex align-items-center gap-2 {{ request()->routeIs('admin.certifications*') ? 'active' : '' }}">
            <i class="bi bi-patch-check"></i> Certifications
            @php $pending = \App\Models\Certification::where('statut','en_attente')->when(!auth()->user()->isAdmin(), fn($q) => $q->where('assigne_a', auth()->id()))->count(); @endphp
            @if($pending > 0)
                <span class="badge bg-warning text-dark ms-auto">{{ $pending }}</span>
            @endif
        </a>
        <a href="{{ route('admin.testaments.index') }}" class="nav-link d-flex align-items-center gap-2 {{ request()->routeIs('admin.testaments*') ? 'active' : '' }}">
            <i class="bi bi-journal-text"></i> Testaments
        </a>
    </nav>
    <div class="position-absolute bottom-0 w-100 p-3 border-top" style="border-color: rgba(255,255,255,0.1)!important;">
        <div class="d-flex align-items-center gap-2 text-white mb-2">
            <div style="width:32px;height:32px;border-radius:50%;background:var(--asman-gold);display:flex;align-items:center;justify-content:center;color:var(--asman-primary);font-weight:700;font-size:0.8rem;">
                {{ strtoupper(substr(auth()->user()->prenom, 0, 1)) }}{{ strtoupper(substr(auth()->user()->nom, 0, 1)) }}
            </div>
            <div>
                <div style="font-size:0.8rem;font-weight:600;">{{ auth()->user()->prenom }} {{ auth()->user()->nom }}</div>
                <div style="font-size:0.65rem;color:rgba(255,255,255,0.5);">{{ ucfirst(auth()->user()->role) }}</div>
            </div>
        </div>
        <form method="POST" action="{{ route('logout') }}">
            @csrf
            <button class="btn btn-sm btn-outline-light w-100"><i class="bi bi-box-arrow-left me-1"></i>Déconnexion</button>
        </form>
    </div>
</div>

<!-- Main -->
<div class="main-content">
    <div class="topbar">
        <h6 class="mb-0 fw-semibold text-muted">@yield('title', 'Tableau de bord')</h6>
        <div class="d-flex align-items-center gap-3">
            <span class="badge bg-primary">{{ ucfirst(auth()->user()->role) }}</span>
            <small class="text-muted">{{ now()->format('d/m/Y H:i') }}</small>
        </div>
    </div>
    <div class="content-area">
        @if(session('success'))
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="bi bi-check-circle me-2"></i>{{ session('success') }}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        @endif
        @if(session('error'))
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="bi bi-exclamation-triangle me-2"></i>{{ session('error') }}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        @endif
        @yield('content')
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
@stack('scripts')
</body>
</html>
