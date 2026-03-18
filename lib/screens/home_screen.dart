import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/asset_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';
import '../widgets/patrimoine_chart.dart';
import '../widgets/asset_card_widget.dart';
import 'assets_list_screen.dart';
import 'add_asset_screen.dart';
import 'loyers_screen.dart';
import 'comptes_screen.dart';
import 'testament_screen.dart';
import 'profile_screen.dart';
import 'marketplace_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DashboardTab(),
    AssetsListScreen(),
    ComptesScreen(),
    LoyersScreen(),
    TestamentScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.navyMedium,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.gold,
          unselectedItemColor: AppTheme.textMuted,
          selectedFontSize: 10,
          unselectedFontSize: 9,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Tableau de bord',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Actifs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_rounded),
              label: 'Comptes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Loyers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_rounded),
              label: 'Testament',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAssetScreen())),
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.navyDark,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<AuthProvider, AssetProvider>(
        builder: (context, auth, assets, _) {
          final user = auth.user;
          final total = assets.patrimoineTotal;
          final devise = user?.devise ?? 'EUR';
          final visible = auth.balancesVisible;

          return RefreshIndicator(
            onRefresh: () => assets.loadData(),
            color: AppTheme.gold,
            backgroundColor: AppTheme.navyMedium,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, auth, user, total, devise, assets, visible)),
                SliverToBoxAdapter(child: _buildChart(assets)),
                SliverToBoxAdapter(child: _buildQuickActions(context, assets)),
                SliverToBoxAdapter(child: _buildCategories(assets, devise)),
                SliverToBoxAdapter(child: _buildRecentAssets(context, assets, devise)),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth, user, double total, String devise, AssetProvider assets, bool visible) {
    final maskedAmount = '••••••';
    
    Future<void> toggleVisibility() async {
      if (visible) {
        auth.hideBalances();
        return;
      }
      // Ask PIN
      if (!context.mounted) return;
      if (auth.user?.hasPinConfigured == true) {
        final List<String> digits = [];
        String? error;
        bool loading = false;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx2, setLocal) => Dialog(
              backgroundColor: AppTheme.navyMedium,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility_rounded, color: AppTheme.gold, size: 32),
                    const SizedBox(height: 10),
                    const Text('Afficher les soldes', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < digits.length ? AppTheme.gold : AppTheme.navyLight,
                          border: Border.all(color: AppTheme.gold, width: 1.5),
                        ),
                      )),
                    ),
                    if (error != null) ...[const SizedBox(height: 8), Text(error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12))],
                    const SizedBox(height: 16),
                    if (loading) const CircularProgressIndicator(color: AppTheme.gold)
                    else GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      childAspectRatio: 1.8,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      children: ['1','2','3','4','5','6','7','8','9','','0','⌫'].map((k) {
                        if (k.isEmpty) return const SizedBox();
                        if (k == '⌫') {
                          return InkWell(
                            onTap: () { if (digits.isNotEmpty) setLocal(() => digits.removeLast()); },
                            child: Container(decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(8)), child: const Center(child: Icon(Icons.backspace_outlined, color: AppTheme.textMuted, size: 18))),
                          );
                        }
                        return InkWell(
                          onTap: () async {
                            if (digits.length >= 4) return;
                            setLocal(() { digits.add(k); error = null; });
                            if (digits.length == 4) {
                              setLocal(() => loading = true);
                              final ok = await auth.showBalances(digits.join());
                              if (ok && ctx2.mounted) { Navigator.pop(ctx2); }
                              else { setLocal(() { digits.clear(); error = 'Code PIN incorrect.'; loading = false; }); }
                            }
                          },
                          child: Container(decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(k, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)))),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        auth.hideBalances();
        auth.balancesVisible; // already visible without PIN
        await auth.showBalances('');
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.navyMedium, AppTheme.navyDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bonjour,', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  Text(user?.nomComplet.isNotEmpty == true ? user!.nomComplet : 'Investisseur',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3260), Color(0xFF0D2045)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.08), blurRadius: 20)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, color: AppTheme.gold, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text('PATRIMOINE NET', style: TextStyle(color: AppTheme.gold.withValues(alpha: 0.8), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600))),
                    GestureDetector(
                      onTap: toggleVisibility,
                      child: Icon(visible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppTheme.gold, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(visible ? AppUtils.formatMontant(total, devise: devise) : maskedAmount,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniStat(Icons.home_rounded, '${assets.getAssetsByType(AssetType.immobilier).length}', 'Biens', AppTheme.colorImmobilier),
                    const SizedBox(width: 12),
                    _miniStat(Icons.directions_car_rounded, '${assets.getAssetsByType(AssetType.vehicule).length}', 'Véhicules', AppTheme.colorVehicule),
                    const SizedBox(width: 12),
                    _miniStat(Icons.account_balance_rounded, '${assets.comptes.length}', 'Comptes', AppTheme.gold),
                    const SizedBox(width: 12),
                    _miniStat(Icons.trending_up_rounded, '${assets.getAssetsByType(AssetType.investissement).length}', 'Invest.', AppTheme.colorInvestissement),
                  ],
                ),
              ],
            ),
          ),
          // Revenus locatifs
          if (assets.loyersMensuelsTotaux > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded, color: AppTheme.success, size: 18),
                  const SizedBox(width: 10),
                  const Text('Revenus locatifs : ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  Text(visible ? AppUtils.formatMontant(assets.loyersMensuelsTotaux, devise: devise) : '••••',
                      style: const TextStyle(color: AppTheme.success, fontSize: 14, fontWeight: FontWeight.bold)),
                  const Text('/mois', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
          // Dettes / Créances
          if (assets.totalDettesEnCours > 0 || assets.totalCreancesEnCours > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (assets.totalCreancesEnCours > 0)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.colorCreance.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.colorCreance.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, color: AppTheme.colorCreance, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Créances', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                Text(AppUtils.formatMontant(assets.totalCreancesEnCours, devise: devise),
                                    style: const TextStyle(color: AppTheme.colorCreance, fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (assets.totalCreancesEnCours > 0 && assets.totalDettesEnCours > 0)
                  const SizedBox(width: 8),
                if (assets.totalDettesEnCours > 0)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, color: AppTheme.error, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Dettes', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                Text(AppUtils.formatMontant(assets.totalDettesEnCours, devise: devise),
                                    style: const TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildChart(AssetProvider assets) {
    if (assets.assets.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: PatrimoineChart(assetProvider: assets),
    );
  }

  Widget _buildQuickActions(BuildContext context, AssetProvider assets) {
    final certsPending = assets.certifications.where((c) =>
        c.statut == CertificationStatus.enAttente || c.statut == CertificationStatus.enCours).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          // Bouton Marketplace
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.colorInvestissement.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.colorInvestissement.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: AppTheme.colorInvestissement, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Marketplace : Acheter ou Louer des actifs',
                      style: TextStyle(color: AppTheme.colorInvestissement, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppTheme.colorInvestissement),
                ],
              ),
            ),
          ),
          
          if (certsPending > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_empty_rounded, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$certsPending certification${certsPending > 1 ? "s" : ""} en attente de traitement',
                      style: const TextStyle(color: AppTheme.warning, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.warning),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategories(AssetProvider assets, String devise) {
    final categories = [
      {'label': 'Immobilier', 'icon': Icons.home_rounded, 'color': AppTheme.colorImmobilier, 'total': assets.totalImmobilier},
      {'label': 'Véhicules', 'icon': Icons.directions_car_rounded, 'color': AppTheme.colorVehicule, 'total': assets.totalVehicules},
      {'label': 'Investissements', 'icon': Icons.trending_up_rounded, 'color': AppTheme.colorInvestissement, 'total': assets.totalInvestissements},
      {'label': 'Comptes banc.', 'icon': Icons.account_balance_rounded, 'color': AppTheme.gold, 'total': assets.totalComptesBancaires},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Répartition du patrimoine',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 2.0, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              final total = cat['total'] as double;
              final pct = assets.patrimoineTotal > 0 ? (total / assets.patrimoineTotal * 100) : 0.0;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.navyCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: (cat['color'] as Color).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (cat['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat['label'] as String,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          Text(AppUtils.formatMontant(total, devise: devise),
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                          Text('${pct.toStringAsFixed(1)}%',
                              style: TextStyle(color: cat['color'] as Color, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAssets(BuildContext context, AssetProvider assets, String devise) {
    final recent = assets.assets.take(3).toList();
    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(Icons.account_balance_wallet_outlined, color: AppTheme.textMuted, size: 60),
            const SizedBox(height: 16),
            const Text('Aucun actif enregistré', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Appuyez sur + pour ajouter votre premier actif',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Actifs récents', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () {},
                child: const Text('Voir tout', style: TextStyle(color: AppTheme.gold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recent.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AssetCardWidget(asset: a, devise: devise),
              )),
        ],
      ),
    );
  }
}
