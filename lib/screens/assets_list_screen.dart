import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';
import '../widgets/asset_card_widget.dart';
import 'add_asset_screen.dart';
import 'asset_detail_screen.dart';

class AssetsListScreen extends StatefulWidget {
  const AssetsListScreen({super.key});
  @override
  State<AssetsListScreen> createState() => _AssetsListScreenState();
}

class _AssetsListScreenState extends State<AssetsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Tous', 'type': null},
    {'label': 'Immobilier', 'type': AssetType.immobilier},
    {'label': 'Véhicules', 'type': AssetType.vehicule},
    {'label': 'Investissements', 'type': AssetType.investissement},
    {'label': 'Créances', 'type': AssetType.creance},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<AssetProvider, AuthProvider>(
        builder: (context, assetProv, authProv, _) {
          final devise = authProv.user?.devise ?? 'EUR';
          return Column(
            children: [
              _buildHeader(context, assetProv, devise),
              _buildSearchBar(),
              _buildTabBar(),
              Expanded(child: _buildAssetsList(assetProv, devise)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AssetProvider assetProv, String devise) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: AppTheme.navyMedium,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mes Actifs', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
              Text('${assetProv.assets.length} actif${assetProv.assets.length > 1 ? 's' : ''} · ${AppUtils.formatMontant(assetProv.patrimoineTotal, devise: devise)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAssetScreen())),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.navyMedium,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Rechercher un actif...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
              : null,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.navyMedium,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.gold,
        labelColor: AppTheme.gold,
        unselectedLabelColor: AppTheme.textMuted,
        indicatorSize: TabBarIndicatorSize.label,
        tabAlignment: TabAlignment.start,
        tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
      ),
    );
  }

  Widget _buildAssetsList(AssetProvider assetProv, String devise) {
    return TabBarView(
      controller: _tabController,
      children: _tabs.map((t) {
        final type = t['type'] as AssetType?;
        var list = type == null ? assetProv.assets : assetProv.getAssetsByType(type);
        if (_searchQuery.isNotEmpty) {
          list = list.where((a) => a.nom.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type != null ? AppUtils.getIconForType(type) : Icons.account_balance_wallet_outlined,
                    color: AppTheme.textMuted, size: 56),
                const SizedBox(height: 16),
                Text(_searchQuery.isNotEmpty ? 'Aucun résultat' : 'Aucun actif dans cette catégorie',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => assetProv.loadData(),
          color: AppTheme.gold,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: list[i]))),
                child: AssetCardWidget(asset: list[i], devise: devise, showDetails: true),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
