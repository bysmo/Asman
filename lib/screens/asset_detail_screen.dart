import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';
import 'add_asset_screen.dart';
import 'evaluation_screen.dart';
import 'loyers_screen.dart';

class AssetDetailScreen extends StatelessWidget {
  final Asset asset;
  const AssetDetailScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AssetProvider, AuthProvider>(
      builder: (context, assetProv, authProv, _) {
        final a = assetProv.assets.firstWhere((x) => x.id == asset.id, orElse: () => asset);
        final devise = authProv.user?.devise ?? a.devise;
        final color = AppUtils.getColorForType(a.type);
        final plusValue = a.plusValue;

        return Scaffold(
          backgroundColor: AppTheme.navyDark,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, a, color, assetProv),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildValeurCard(a, devise, plusValue, color),
                      const SizedBox(height: 16),
                      if (a.estLoue) _buildLocationCard(a, devise, context),
                      if (a.estLoue) const SizedBox(height: 16),
                      _buildInfosCard(a),
                      const SizedBox(height: 16),
                      _buildActions(context, a, assetProv),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, Asset a, Color color, AssetProvider assetProv) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppTheme.navyMedium,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: AppTheme.gold),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddAssetScreen(assetToEdit: a))),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
          onPressed: () => _confirmDelete(context, a, assetProv),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.3), AppTheme.navyMedium],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Icon(AppUtils.getIconForType(a.type), color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(a.nom, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppUtils.getColorForStatus(a.statut).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(AppUtils.getLabelForStatus(a.statut),
                                  style: TextStyle(color: AppUtils.getColorForStatus(a.statut), fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            Text(a.pays, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValeurCard(Asset a, String devise, double plusValue, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Valeur actuelle', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(AppUtils.formatMontant(a.valeurActuelle, devise: devise),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Variation', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(plusValue >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: plusValue >= 0 ? AppTheme.success : AppTheme.danger, size: 16),
                      Text('${a.plusValuePourcentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: plusValue >= 0 ? AppTheme.success : AppTheme.danger,
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppTheme.navyLight),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _valItem('Coût d\'achat', AppUtils.formatMontant(a.valeurInitiale, devise: devise)),
              _valItem('Plus-value', AppUtils.formatMontant(plusValue, devise: devise),
                  color: plusValue >= 0 ? AppTheme.success : AppTheme.danger),
              if (a.dateDerniereEvaluation != null)
                _valItem('Dernière éval.', AppUtils.formatDate(a.dateDerniereEvaluation!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _valItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color ?? AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildLocationCard(Asset a, String devise, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: AppTheme.info, size: 18),
              const SizedBox(width: 8),
              const Text('Bien loué', style: TextStyle(color: AppTheme.info, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoyersScreen(filterAssetId: a.id))),
                icon: const Icon(Icons.receipt_long_rounded, size: 14, color: AppTheme.gold),
                label: const Text('Loyers', style: TextStyle(color: AppTheme.gold, fontSize: 12)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              ),
            ],
          ),
          if (a.loyerMensuel != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.payments_rounded, color: AppTheme.textMuted, size: 16),
              const SizedBox(width: 8),
              Text('${AppUtils.formatMontant(a.loyerMensuel!, devise: devise)} / mois',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
          ],
          if (a.locataire != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.person_rounded, color: AppTheme.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(a.locataire!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            ]),
          ],
          if (a.dateFinBail != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today_rounded, color: AppTheme.textMuted, size: 16),
              const SizedBox(width: 8),
              Text('Fin de bail : ${AppUtils.formatDate(a.dateFinBail!)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildInfosCard(Asset a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informations', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _infoRow(Icons.category_rounded, 'Type', AppUtils.getLabelForType(a.type)),
          _infoRow(Icons.public_rounded, 'Pays', a.pays),
          _infoRow(Icons.monetization_on_rounded, 'Devise', a.devise),
          _infoRow(Icons.calendar_month_rounded, 'Acquisition', AppUtils.formatDate(a.dateAcquisition)),
          if (a.description.isNotEmpty) _infoRow(Icons.notes_rounded, 'Notes', a.description),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 16),
          const SizedBox(width: 10),
          Text('$label : ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Asset a, AssetProvider assetProv) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _actionBtn(
            context, Icons.edit_rounded, 'Modifier', AppTheme.gold,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddAssetScreen(assetToEdit: a))),
          )),
          const SizedBox(width: 12),
          Expanded(child: _actionBtn(
            context, Icons.update_rounded, 'Évaluer', AppTheme.info,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => EvaluationScreen(asset: a))),
          )),
        ]),
        if (a.estLoue) ...[
          const SizedBox(height: 12),
          _actionBtn(
            context, Icons.add_card_rounded, 'Enregistrer un loyer', AppTheme.success,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoyersScreen(filterAssetId: a.id))),
            fullWidth: true,
          ),
        ],
      ],
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap, {bool fullWidth = false}) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }

  Future<void> _confirmDelete(BuildContext context, Asset a, AssetProvider assetProv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Supprimer l\'actif', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Voulez-vous supprimer "${a.nom}" ? Cette action est irréversible.',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!context.mounted) return;
      await assetProv.deleteAsset(a.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
