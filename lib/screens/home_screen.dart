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
import 'profile_screen.dart';

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
    LoyersScreen(),
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
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Tableau de bord'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Actifs'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Loyers'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<AuthProvider, AssetProvider>(
        builder: (context, auth, assets, _) {
          final user = auth.user;
          final total = assets.patrimoineTotal;
          final devise = user?.devise ?? 'EUR';

          return RefreshIndicator(
            onRefresh: () => assets.loadData(),
            color: AppTheme.gold,
            backgroundColor: AppTheme.navyMedium,
            child: CustomScrollView(
              slivers: [
                // En-tête
                SliverToBoxAdapter(child: _buildHeader(context, user, total, devise, assets)),
                // Graphique
                SliverToBoxAdapter(child: _buildChart(assets)),
                // Catégories rapides
                SliverToBoxAdapter(child: _buildCategories(assets, devise)),
                // Actifs récents
                SliverToBoxAdapter(child: _buildRecentAssets(context, assets, devise)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user, double total, String devise, AssetProvider assets) {
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
                  Text('Bonjour,', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  Text(user?.nomComplet.isNotEmpty == true ? user!.nomComplet : 'Investisseur',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAssetScreen())),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.add_rounded, color: AppTheme.gold, size: 24),
                ),
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
                    Text('PATRIMOINE TOTAL', style: TextStyle(color: AppTheme.gold.withValues(alpha: 0.8), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(AppUtils.formatMontant(total, devise: devise),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniStat(Icons.home_rounded, '${assets.getAssetsByType(AssetType.immobilier).length}', 'Biens', AppTheme.colorImmobilier),
                    const SizedBox(width: 16),
                    _miniStat(Icons.directions_car_rounded, '${assets.getAssetsByType(AssetType.vehicule).length}', 'Véhicules', AppTheme.colorVehicule),
                    const SizedBox(width: 16),
                    _miniStat(Icons.receipt_long_rounded, '${assets.assetsLoues.length}', 'Loués', AppTheme.colorInvestissement),
                    const SizedBox(width: 16),
                    _miniStat(Icons.trending_up_rounded, '${assets.getAssetsByType(AssetType.investissement).length}', 'Invest.', AppTheme.colorCreance),
                  ],
                ),
              ],
            ),
          ),
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
                  Text('Revenus locatifs mensuels : ',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  Text(AppUtils.formatMontant(assets.loyersMensuelsTotaux, devise: devise),
                      style: const TextStyle(color: AppTheme.success, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
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

  Widget _buildCategories(AssetProvider assets, String devise) {
    final categories = [
      {'label': 'Immobilier', 'icon': Icons.home_rounded, 'color': AppTheme.colorImmobilier, 'total': assets.totalImmobilier},
      {'label': 'Véhicules', 'icon': Icons.directions_car_rounded, 'color': AppTheme.colorVehicule, 'total': assets.totalVehicules},
      {'label': 'Investissements', 'icon': Icons.trending_up_rounded, 'color': AppTheme.colorInvestissement, 'total': assets.totalInvestissements},
      {'label': 'Créances', 'icon': Icons.description_rounded, 'color': AppTheme.colorCreance, 'total': assets.totalCreances},
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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAssetScreen())),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter un actif'),
            ),
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
