import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';

class ComptesScreen extends StatelessWidget {
  const ComptesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AssetProvider, AuthProvider>(
      builder: (context, prov, auth, _) {
        final devise = auth.user?.devise ?? 'EUR';
        final comptes = prov.comptes;
        final total = prov.totalComptesBancaires;

        return SafeArea(
          child: Column(
            children: [
              _buildHeader(context, total, devise),
              Expanded(
                child: comptes.isEmpty
                    ? _buildEmpty(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: comptes.length,
                        itemBuilder: (_, i) => _buildCompteTile(context, comptes[i], devise, prov),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, double total, String devise) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: AppTheme.navyMedium,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Comptes Bancaires', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Solde total : ${AppUtils.formatMontant(total, devise: devise)}',
                style: const TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          ElevatedButton.icon(
            onPressed: () => _showAddCompteDialog(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompteTile(BuildContext context, CompteBancaire c, String devise, AssetProvider prov) {
    final typeIcon = _getTypeIcon(c.typeCompte);
    final typeColor = _getTypeColor(c.typeCompte);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(typeIcon, color: typeColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(c.nomBanque, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold))),
                if (!c.estActif)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.textMuted.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Inactif', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  ),
              ]),
              const SizedBox(height: 2),
              Text('${_getTypeLabel(c.typeCompte)} · ${c.numeroCompte}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              if (c.iban != null && c.iban!.isNotEmpty)
                Text('IBAN: ${c.iban}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(AppUtils.formatMontant(c.solde, devise: devise),
                style: TextStyle(
                    color: c.solde >= 0 ? AppTheme.textPrimary : AppTheme.danger,
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.gold),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: () => _showAddCompteDialog(context, compte: c),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.danger),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: () => _confirmDelete(context, c, prov),
              ),
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.account_balance_rounded, color: AppTheme.textMuted, size: 60),
        const SizedBox(height: 16),
        const Text('Aucun compte bancaire', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Ajoutez vos comptes pour centraliser\nvotre trésorerie',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _showAddCompteDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ajouter un compte'),
        ),
      ]),
    );
  }

  IconData _getTypeIcon(String t) {
    switch (t) {
      case 'epargne': return Icons.savings_rounded;
      case 'investissement': return Icons.trending_up_rounded;
      case 'crypto': return Icons.currency_bitcoin_rounded;
      default: return Icons.account_balance_rounded;
    }
  }
  Color _getTypeColor(String t) {
    switch (t) {
      case 'epargne': return AppTheme.success;
      case 'investissement': return AppTheme.colorInvestissement;
      case 'crypto': return AppTheme.colorCreance;
      default: return AppTheme.colorImmobilier;
    }
  }
  String _getTypeLabel(String t) {
    switch (t) {
      case 'epargne': return 'Épargne';
      case 'investissement': return 'Investissement';
      case 'crypto': return 'Crypto';
      default: return 'Courant';
    }
  }

  Future<void> _showAddCompteDialog(BuildContext context, {CompteBancaire? compte}) async {
    final nomC = TextEditingController(text: compte?.nomBanque ?? '');
    final numC = TextEditingController(text: compte?.numeroCompte ?? '');
    final ibanC = TextEditingController(text: compte?.iban ?? '');
    final soldeC = TextEditingController(text: compte?.solde.toStringAsFixed(0) ?? '');
    final descC = TextEditingController(text: compte?.description ?? '');
    String type = compte?.typeCompte ?? 'courant';
    final prov = context.read<AssetProvider>();
    final devise = context.read<AuthProvider>().user?.devise ?? 'EUR';

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyMedium,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx2).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.account_balance_rounded, color: AppTheme.gold, size: 20),
                const SizedBox(width: 8),
                Text(compte == null ? 'Nouveau compte' : 'Modifier le compte',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              const Text('TYPE DE COMPTE', style: TextStyle(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['courant', 'epargne', 'investissement', 'crypto'].map((t) {
                final selected = type == t;
                return GestureDetector(
                  onTap: () => setS(() => type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _getTypeColor2(t).withValues(alpha: 0.2) : AppTheme.navyCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? _getTypeColor2(t) : AppTheme.navyLight),
                    ),
                    child: Text(_getTypeLabel2(t), style: TextStyle(color: selected ? _getTypeColor2(t) : AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 14),
              _tf(nomC, 'Nom de la banque', Icons.business_rounded),
              const SizedBox(height: 10),
              _tf(numC, 'Numéro de compte', Icons.numbers_rounded),
              const SizedBox(height: 10),
              _tf(ibanC, 'IBAN (optionnel)', Icons.credit_card_rounded),
              const SizedBox(height: 10),
              _tf(soldeC, 'Solde actuel ($devise)', Icons.payments_rounded, type: TextInputType.number),
              const SizedBox(height: 10),
              _tf(descC, 'Notes (optionnel)', Icons.notes_rounded),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nomC.text.isEmpty || soldeC.text.isEmpty) return;
                    final c = CompteBancaire(
                      id: compte?.id ?? prov.generateId(),
                      nomBanque: nomC.text.trim(),
                      numeroCompte: numC.text.trim(),
                      typeCompte: type,
                      solde: double.tryParse(soldeC.text.replaceAll(',', '.')) ?? 0,
                      devise: devise,
                      pays: context.read<AuthProvider>().user?.pays ?? 'France',
                      iban: ibanC.text.isNotEmpty ? ibanC.text.trim() : null,
                      description: descC.text.trim(),
                      dateOuverture: compte?.dateOuverture ?? DateTime.now(),
                    );
                    if (compte == null) await prov.addCompte(c); else await prov.updateCompte(c);
                    if (ctx2.mounted) Navigator.pop(ctx2);
                  },
                  child: Text(compte == null ? 'Enregistrer' : 'Mettre à jour',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor2(String t) {
    switch (t) {
      case 'epargne': return AppTheme.success;
      case 'investissement': return AppTheme.colorInvestissement;
      case 'crypto': return AppTheme.colorCreance;
      default: return AppTheme.colorImmobilier;
    }
  }
  String _getTypeLabel2(String t) {
    switch (t) {
      case 'epargne': return 'Épargne';
      case 'investissement': return 'Investissement';
      case 'crypto': return 'Crypto';
      default: return 'Courant';
    }
  }

  Widget _tf(TextEditingController c, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c, keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.gold, size: 20)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CompteBancaire c, AssetProvider prov) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Supprimer le compte', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Supprimer "${c.nomBanque}" ?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) await prov.deleteCompte(c.id);
  }
}
