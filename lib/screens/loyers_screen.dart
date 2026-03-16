import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';

class LoyersScreen extends StatefulWidget {
  final String? filterAssetId;
  const LoyersScreen({super.key, this.filterAssetId});
  @override
  State<LoyersScreen> createState() => _LoyersScreenState();
}

class _LoyersScreenState extends State<LoyersScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<AssetProvider, AuthProvider>(
        builder: (context, assetProv, authProv, _) {
          final devise = authProv.user?.devise ?? 'EUR';
          final assetsLoues = widget.filterAssetId != null
              ? assetProv.assets.where((a) => a.id == widget.filterAssetId).toList()
              : assetProv.assetsLoues;

          final loyersMois = assetProv.loyers.where((l) =>
              l.mois == _selectedMonth && l.annee == _selectedYear &&
              (widget.filterAssetId == null || l.assetId == widget.filterAssetId)).toList();

          final totalPaye = loyersMois.where((l) => l.estPaye).fold(0.0, (s, l) => s + l.montant);
          final totalAttendu = loyersMois.fold(0.0, (s, l) => s + l.montant);

          return Column(
            children: [
              _buildHeader(assetProv, devise),
              _buildMonthSelector(),
              _buildSummary(totalPaye, totalAttendu, devise),
              Expanded(
                child: assetsLoues.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (loyersMois.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text('Paiements ce mois', style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
                            ),
                            ...loyersMois.map((l) => _buildLoyerTile(l, assetProv, devise)),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Biens loués', style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
                          ),
                          ...assetsLoues.map((a) => _buildAssetLoyerCard(context, a, assetProv, devise)),
                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(AssetProvider assetProv, String devise) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: AppTheme.navyMedium,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Loyers', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
              Text('${assetProv.assetsLoues.length} bien${assetProv.assetsLoues.length > 1 ? 's' : ''} en location',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(AppUtils.formatMontant(assetProv.loyersMensuelsTotaux, devise: devise),
                    style: const TextStyle(color: AppTheme.success, fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('/mois', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final mois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return Container(
      color: AppTheme.navyMedium,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.gold),
            onPressed: () => setState(() {
              if (_selectedMonth == 1) {
                _selectedMonth = 12;
                _selectedYear--;
              } else {
                _selectedMonth--;
              }
            }),
          ),
          Expanded(
            child: Center(
              child: Text('${mois[_selectedMonth - 1]} $_selectedYear',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.gold),
            onPressed: () => setState(() {
              if (_selectedMonth == 12) {
                _selectedMonth = 1;
                _selectedYear++;
              } else {
                _selectedMonth++;
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(double totalPaye, double totalAttendu, String devise) {
    final taux = totalAttendu > 0 ? (totalPaye / totalAttendu) : 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.navyLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('Attendu', AppUtils.formatMontant(totalAttendu, devise: devise), AppTheme.textSecondary),
              _summaryItem('Perçu', AppUtils.formatMontant(totalPaye, devise: devise), AppTheme.success),
              _summaryItem('Restant', AppUtils.formatMontant(totalAttendu - totalPaye, devise: devise), AppTheme.warning),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: taux,
              backgroundColor: AppTheme.navyLight,
              valueColor: AlwaysStoppedAnimation<Color>(taux >= 1.0 ? AppTheme.success : AppTheme.gold),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(taux * 100).toStringAsFixed(0)}% collecté',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAssetLoyerCard(BuildContext context, Asset a, AssetProvider assetProv, String devise) {
    final loyerExists = assetProv.loyers.any((l) =>
        l.assetId == a.id && l.mois == _selectedMonth && l.annee == _selectedYear);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.navyLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppUtils.getColorForType(a.type).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(AppUtils.getIconForType(a.type), color: AppUtils.getColorForType(a.type), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.nom, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                if (a.locataire != null)
                  Text(a.locataire!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppUtils.formatMontant(a.loyerMensuel ?? 0, devise: devise),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (!loyerExists)
                GestureDetector(
                  onTap: () => _addLoyer(context, a, assetProv),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
                    ),
                    child: const Text('Enregistrer', style: TextStyle(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                )
              else
                const Text('✓ Enregistré', style: TextStyle(color: AppTheme.success, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoyerTile(Loyer l, AssetProvider assetProv, String devise) {
    final asset = assetProv.assets.firstWhere((a) => a.id == l.assetId, orElse: () => Asset(
      id: '', nom: 'Inconnu', type: AssetType.immobilier, valeurActuelle: 0,
      valeurInitiale: 0, dateAcquisition: DateTime.now(),
    ));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: l.estPaye ? AppTheme.success.withValues(alpha: 0.06) : AppTheme.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: l.estPaye ? AppTheme.success.withValues(alpha: 0.25) : AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(l.estPaye ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: l.estPaye ? AppTheme.success : AppTheme.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.nom, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(AppUtils.formatDate(l.datePaiement), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(AppUtils.formatMontant(l.montant, devise: devise),
              style: TextStyle(color: l.estPaye ? AppTheme.success : AppTheme.warning, fontSize: 14, fontWeight: FontWeight.bold)),
          if (!l.estPaye) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => assetProv.marquerLoyerPaye(l.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                ),
                child: const Text('Payé', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, color: AppTheme.textMuted, size: 60),
          const SizedBox(height: 16),
          const Text('Aucun bien en location', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Ajoutez un actif et activez la location pour gérer les loyers.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _addLoyer(BuildContext context, Asset asset, AssetProvider assetProv) async {
    final montantC = TextEditingController(text: asset.loyerMensuel?.toStringAsFixed(0) ?? '');
    final notesC = TextEditingController();
    bool estPaye = true;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyMedium,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx2).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_card_rounded, color: AppTheme.gold, size: 20),
                  const SizedBox(width: 8),
                  Text('Loyer - ${asset.nom}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: montantC,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Montant', prefixIcon: Icon(Icons.payments_rounded, color: AppTheme.gold, size: 20)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesC,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Notes (optionnel)', prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.gold, size: 20)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Text('Déjà payé', style: TextStyle(color: AppTheme.textPrimary))),
                  Switch(value: estPaye, onChanged: (v) => setS(() => estPaye = v), activeThumbColor: AppTheme.success),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final loyer = Loyer(
                      id: assetProv.generateId(),
                      assetId: asset.id,
                      montant: double.tryParse(montantC.text.replaceAll(',', '.')) ?? (asset.loyerMensuel ?? 0),
                      datePaiement: DateTime.now(),
                      estPaye: estPaye,
                      notes: notesC.text.isNotEmpty ? notesC.text : null,
                      mois: _selectedMonth,
                      annee: _selectedYear,
                    );
                    await assetProv.addLoyer(loyer);
                    if (ctx2.mounted) Navigator.pop(ctx2);
                  },
                  child: const Text('Enregistrer le loyer', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
