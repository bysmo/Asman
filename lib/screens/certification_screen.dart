import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';

class CertificationScreen extends StatelessWidget {
  const CertificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AssetProvider, AuthProvider>(
      builder: (context, prov, auth, _) {
        final certifs = prov.certifications;
        final certifiesCount = prov.assetsCertifies.length;
        return SafeArea(
          child: Column(
            children: [
              _buildHeader(context, certifiesCount, prov.assets.length),
              Expanded(
                child: certifs.isEmpty
                    ? _buildEmpty(context, prov)
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildInfoBanner(),
                          const SizedBox(height: 12),
                          ...certifs.map((c) => _buildCertifTile(context, c, prov)),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int certifies, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: AppTheme.navyMedium,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Certifications', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('$certifies / $total actifs certifiés',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ]),
          ElevatedButton.icon(
            onPressed: () => _showDemandeCertif(context, context.read<AssetProvider>()),
            icon: const Icon(Icons.verified_rounded, size: 18),
            label: const Text('Demander'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, color: AppTheme.gold, size: 18),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'La certification par une autorité compétente (notaire, huissier, cadastre) garantit l\'authenticité de vos actifs. Un actif certifié ne peut être revendiqué par un autre utilisateur.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
        ),
      ]),
    );
  }

  Widget _buildCertifTile(BuildContext context, CertificationDemande c, AssetProvider prov) {
    final statusColor = _statusColor(c.statut);
    final statusLabel = _statusLabel(c.statut);
    final statusIcon = _statusIcon(c.statut);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(AppUtils.getIconForType(c.assetType), color: statusColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.assetNom, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(AppUtils.getLabelForType(c.assetType), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(statusIcon, color: statusColor, size: 14),
              const SizedBox(width: 4),
              Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Container(height: 1, color: AppTheme.navyLight),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _infoChip(Icons.business_rounded, c.autoriteType == 'notaire' ? 'Notaire' : c.autoriteType == 'huissier' ? 'Huissier' : 'Cadastre')),
          Expanded(child: _infoChip(Icons.calendar_today_rounded, AppUtils.formatDate(c.dateDemande))),
          Expanded(child: _infoChip(Icons.payments_rounded, c.frais > 0 ? AppUtils.formatMontant(c.frais, devise: c.devise) : 'N/A')),
        ]),
        if (c.autoriteNom.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.person_rounded, color: AppTheme.textMuted, size: 14),
            const SizedBox(width: 6),
            Text(c.autoriteNom, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ]),
        ],
        if (c.statut == CertificationStatus.enAttente) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => prov.approuverCertification(c.id),
              icon: const Icon(Icons.check_rounded, size: 16, color: AppTheme.success),
              label: const Text('Simuler approbation', style: TextStyle(color: AppTheme.success, fontSize: 12)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.success), padding: const EdgeInsets.symmetric(vertical: 8)),
            )),
          ]),
        ],
        if (c.statut == CertificationStatus.certifie && c.dateTraitement != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.verified_rounded, color: AppTheme.success, size: 14),
            const SizedBox(width: 6),
            Text('Certifié le ${AppUtils.formatDate(c.dateTraitement!)}',
                style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ],
      ]),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppTheme.textMuted, size: 12),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
    ]);
  }

  Widget _buildEmpty(BuildContext context, AssetProvider prov) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.verified_outlined, color: AppTheme.textMuted, size: 60),
      const SizedBox(height: 16),
      const Text('Aucune demande de certification', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
      const SizedBox(height: 8),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text('Certifiez vos actifs pour les protéger et accéder à la marketplace',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
      ),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: () => _showDemandeCertif(context, prov),
        icon: const Icon(Icons.verified_rounded),
        label: const Text('Demander une certification'),
      ),
    ]));
  }

  Color _statusColor(CertificationStatus s) {
    switch (s) {
      case CertificationStatus.certifie: return AppTheme.success;
      case CertificationStatus.enAttente: return AppTheme.warning;
      case CertificationStatus.enCours: return AppTheme.info;
      case CertificationStatus.refuse: return AppTheme.danger;
      default: return AppTheme.textMuted;
    }
  }
  String _statusLabel(CertificationStatus s) {
    switch (s) {
      case CertificationStatus.certifie: return 'Certifié';
      case CertificationStatus.enAttente: return 'En attente';
      case CertificationStatus.enCours: return 'En cours';
      case CertificationStatus.refuse: return 'Refusé';
      default: return 'Non demandé';
    }
  }
  IconData _statusIcon(CertificationStatus s) {
    switch (s) {
      case CertificationStatus.certifie: return Icons.verified_rounded;
      case CertificationStatus.enAttente: return Icons.hourglass_empty_rounded;
      case CertificationStatus.enCours: return Icons.search_rounded;
      case CertificationStatus.refuse: return Icons.cancel_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  Future<void> _showDemandeCertif(BuildContext context, AssetProvider prov) async {
    if (prov.assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ajoutez d\'abord un actif à certifier'), backgroundColor: AppTheme.warning));
      return;
    }
    Asset? selectedAsset = prov.assets.firstWhere(
      (a) => a.certificationStatus == CertificationStatus.nonDemande,
      orElse: () => prov.assets.first,
    );
    String autoriteType = 'notaire';
    final autoriteNomC = TextEditingController();
    final autoriteContactC = TextEditingController();
    final fraisC = TextEditingController(text: '50000');
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
                const Icon(Icons.verified_rounded, color: AppTheme.gold, size: 20),
                const SizedBox(width: 8),
                const Text('Demande de certification', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              const Text('ACTIF À CERTIFIER', style: TextStyle(color: AppTheme.gold, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Asset>(
                value: selectedAsset,
                dropdownColor: AppTheme.navyMedium,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.inventory_2_rounded, color: AppTheme.gold, size: 20)),
                items: prov.assets.map((a) => DropdownMenuItem(
                  value: a,
                  child: Text('${a.nom} (${AppUtils.getLabelForType(a.type)})', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (a) => setS(() => selectedAsset = a),
              ),
              const SizedBox(height: 14),
              const Text('TYPE D\'AUTORITÉ', style: TextStyle(color: AppTheme.gold, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['notaire', 'huissier', 'cadastre', 'tribunal'].map((t) {
                final sel = autoriteType == t;
                return GestureDetector(
                  onTap: () => setS(() => autoriteType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.gold.withValues(alpha: 0.2) : AppTheme.navyCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppTheme.gold : AppTheme.navyLight),
                    ),
                    child: Text(t[0].toUpperCase() + t.substring(1),
                        style: TextStyle(color: sel ? AppTheme.gold : AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 14),
              _tf3(autoriteNomC, 'Nom de l\'autorité', Icons.business_rounded),
              const SizedBox(height: 10),
              _tf3(autoriteContactC, 'Contact de l\'autorité', Icons.phone_rounded),
              const SizedBox(height: 10),
              _tf3(fraisC, 'Frais de certification ($devise)', Icons.payments_rounded, type: TextInputType.number),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 14),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Partage des revenus : 70% Autorité · 30% Asman Platform',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (selectedAsset == null) return;
                    await prov.demanderCertification(CertificationDemande(
                      id: prov.generateId(),
                      assetId: selectedAsset!.id,
                      assetNom: selectedAsset!.nom,
                      assetType: selectedAsset!.type,
                      autoriteType: autoriteType,
                      autoriteNom: autoriteNomC.text.trim(),
                      autoriteContact: autoriteContactC.text.trim(),
                      frais: double.tryParse(fraisC.text.replaceAll(',', '.')) ?? 0,
                      devise: devise,
                      dateDemande: DateTime.now(),
                    ));
                    if (ctx2.mounted) Navigator.pop(ctx2);
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Soumettre la demande', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tf3(TextEditingController c, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c, keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.gold, size: 20)),
    );
  }
}
