import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../theme/app_theme.dart';
import '../models/asset_model.dart';
import '../utils/app_utils.dart';

/// Écran Autorités — Vue consolidée des certifications, revenus partagés
/// et tableau de bord pour les autorités habilitées (notaires, huissiers, etc.)
class AutoritesScreen extends StatefulWidget {
  const AutoritesScreen({super.key});
  @override
  State<AutoritesScreen> createState() => _AutoritesScreenState();
}

class _AutoritesScreenState extends State<AutoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Autorités & Certifications', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppTheme.gold),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
            Tab(icon: Icon(Icons.verified_rounded), text: 'Certifications'),
            Tab(icon: Icon(Icons.payments_rounded), text: 'Revenus'),
          ],
        ),
      ),
      body: Consumer<AssetProvider>(
        builder: (context, assets, _) => TabBarView(
          controller: _tabCtrl,
          children: [
            _DashboardAutorite(assets: assets),
            _CertificationsTab(assets: assets),
            _RevenusPartagesTab(assets: assets),
          ],
        ),
      ),
    );
  }
}

// ─── TAB 1 : DASHBOARD AUTORITÉ ──────────────────────────────────────────────
class _DashboardAutorite extends StatelessWidget {
  final AssetProvider assets;
  const _DashboardAutorite({required this.assets});

  @override
  Widget build(BuildContext context) {
    final certs = assets.certifications;
    final pending = certs.where((c) => c.statut == CertificationStatus.enAttente || c.statut == CertificationStatus.enCours).length;
    final certifiees = certs.where((c) => c.statut == CertificationStatus.certifie).length;
    final refused = certs.where((c) => c.statut == CertificationStatus.refuse).length;

    // Calculs revenus
    final totalFrais = certs.where((c) => c.paiementEffectue).fold(0.0, (s, c) => s + c.frais);
    final partAutorites = certs.where((c) => c.paiementEffectue).fold(0.0, (s, c) => s + (c.frais * (c.partAutorite ?? 70) / 100));
    final partPlateforme = certs.where((c) => c.paiementEffectue).fold(0.0, (s, c) => s + (c.frais * (c.partPlateforme ?? 30) / 100));

    // Actifs certifiés
    final assetsCertifies = assets.assetsCertifies;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bannière
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.gold.withValues(alpha: 0.2), AppTheme.navyCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gavel_rounded, color: AppTheme.gold, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Espace Autorités', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Suivi des certifications et partage de revenus', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats de certification
          const Text('Vue d\'ensemble', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _statCard('En attente', '$pending', Icons.hourglass_empty_rounded, AppTheme.warning),
              _statCard('Certifiées', '$certifiees', Icons.verified_rounded, AppTheme.success),
              _statCard('Refusées', '$refused', Icons.cancel_rounded, AppTheme.error),
              _statCard('Total actifs\ncertifiés', '${assetsCertifies.length}', Icons.shield_rounded, AppTheme.gold),
            ],
          ),
          const SizedBox(height: 20),

          // Modèle de revenus
          const Text('Modèle de partage de revenus', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.navyCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.navyLight),
            ),
            child: Column(
              children: [
                _revenueRow('Autorité habilitée', '70%', AppTheme.colorInvestissement),
                const SizedBox(height: 8),
                _revenueRow('Plateforme Asman', '30%', AppTheme.gold),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppTheme.navyLight),
                ),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.textMuted, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Les frais de certification sont répartis automatiquement entre l\'autorité habilitée et Asman.',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Revenus totaux
          if (totalFrais > 0) ...[
            const Text('Revenus encaissés', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.success.withValues(alpha: 0.15), AppTheme.navyCard],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _montantRow('Total frais encaissés', totalFrais, AppTheme.textSecondary),
                  const Divider(color: AppTheme.navyLight),
                  _montantRow('Revenus autorités (70%)', partAutorites, AppTheme.colorInvestissement),
                  _montantRow('Revenus Asman (30%)', partPlateforme, AppTheme.gold),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Types d'autorités
          const Text('Types d\'autorités habilitées', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _autoriteTypeCard(Icons.gavel_rounded, 'Notaire', 'Certification des actes authentiques, testaments et successions', AppTheme.gold),
          const SizedBox(height: 10),
          _autoriteTypeCard(Icons.badge_rounded, 'Huissier de justice', 'Constats, saisies et actes d\'exécution', AppTheme.colorVehicule),
          const SizedBox(height: 10),
          _autoriteTypeCard(Icons.account_balance_rounded, 'Tribunal', 'Décisions judiciaires et homologations', AppTheme.colorImmobilier),
          const SizedBox(height: 10),
          _autoriteTypeCard(Icons.map_rounded, 'Cadastre', 'Certification des biens immobiliers et terrains', AppTheme.colorCreance),
          const SizedBox(height: 20),

          // Processus de certification
          const Text('Processus de certification', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _processStep('1', 'Demande', 'L\'utilisateur soumet une demande de certification pour son actif', AppTheme.colorImmobilier),
          _processStep('2', 'Vérification', 'L\'autorité habilitée vérifie les documents et l\'actif', AppTheme.colorVehicule),
          _processStep('3', 'Paiement', 'Les frais sont réglés et répartis (70% autorité / 30% Asman)', AppTheme.gold),
          _processStep('4', 'Certification', 'L\'actif est certifié, ce qui prévient les doublons', AppTheme.success),
          _processStep('5', 'Marketplace', 'Les actifs certifiés peuvent être mis en vente ou en location', AppTheme.colorCreance),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _revenueRow(String label, String pct, Color color) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(pct, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _montantRow(String label, double montant, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(AppUtils.formatMontant(montant, devise: 'EUR'),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _autoriteTypeCard(IconData icon, String nom, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _processStep(String num, String title, String desc, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
            Container(width: 2, height: 36, color: color.withValues(alpha: 0.3)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── TAB 2 : CERTIFICATIONS ──────────────────────────────────────────────────
class _CertificationsTab extends StatelessWidget {
  final AssetProvider assets;
  const _CertificationsTab({required this.assets});

  @override
  Widget build(BuildContext context) {
    final certs = assets.certifications;
    if (certs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, color: AppTheme.textMuted, size: 64),
            const SizedBox(height: 16),
            const Text('Aucune demande de certification', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Les demandes apparaîtront ici', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: certs.length,
      itemBuilder: (ctx, i) => _certCard(ctx, certs[i], assets),
    );
  }

  Color _certColor(CertificationStatus s) {
    switch (s) {
      case CertificationStatus.nonDemande: return AppTheme.textMuted;
      case CertificationStatus.enAttente: return AppTheme.warning;
      case CertificationStatus.enCours: return AppTheme.colorInvestissement;
      case CertificationStatus.certifie: return AppTheme.success;
      case CertificationStatus.refuse: return AppTheme.error;
    }
  }

  String _certLabel(CertificationStatus s) {
    switch (s) {
      case CertificationStatus.nonDemande: return 'Non demandé';
      case CertificationStatus.enAttente: return 'En attente';
      case CertificationStatus.enCours: return 'En cours';
      case CertificationStatus.certifie: return 'Certifié';
      case CertificationStatus.refuse: return 'Refusé';
    }
  }

  String _typeLabel(AssetType t) {
    switch (t) {
      case AssetType.immobilier: return 'Immobilier';
      case AssetType.vehicule: return 'Véhicule';
      case AssetType.investissement: return 'Investissement';
      case AssetType.creance: return 'Créance';
      case AssetType.dette: return 'Dette';
      case AssetType.compteBancaire: return 'Compte Bancaire';
      case AssetType.autre: return 'Autre';
    }
  }

  Widget _certCard(BuildContext context, CertificationDemande cert, AssetProvider assets) {
    final color = _certColor(cert.statut);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(cert.assetNom, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(_certLabel(cert.statut), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.category_rounded, _typeLabel(cert.assetType)),
          _infoRow(Icons.gavel_rounded, '${cert.autoriteType.toUpperCase()} · ${cert.autoriteNom.isNotEmpty ? cert.autoriteNom : "Non assigné"}'),
          _infoRow(Icons.calendar_today_rounded, 'Demande : ${AppUtils.formatDate(cert.dateDemande)}'),
          if (cert.dateTraitement != null)
            _infoRow(Icons.check_circle_rounded, 'Traitement : ${AppUtils.formatDate(cert.dateTraitement!)}'),
          if (cert.frais > 0) ...[
            const Divider(color: AppTheme.navyLight, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Frais : ${AppUtils.formatMontant(cert.frais, devise: cert.devise)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text('Payé : ${cert.paiementEffectue ? "✓" : "✗"}',
                    style: TextStyle(color: cert.paiementEffectue ? AppTheme.success : AppTheme.error, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            if (cert.paiementEffectue && cert.frais > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _partBadge('Autorité (${cert.partAutorite?.toStringAsFixed(0) ?? "70"}%)',
                        cert.frais * (cert.partAutorite ?? 70) / 100, AppTheme.colorInvestissement, cert.devise),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _partBadge('Asman (${cert.partPlateforme?.toStringAsFixed(0) ?? "30"}%)',
                        cert.frais * (cert.partPlateforme ?? 30) / 100, AppTheme.gold, cert.devise),
                  ),
                ],
              ),
            ],
          ],
          if (cert.notes.isNotEmpty) ...[
            const Divider(color: AppTheme.navyLight, height: 16),
            Text(cert.notes, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
          if (cert.refus?.isNotEmpty == true) ...[
            const Divider(color: AppTheme.navyLight, height: 16),
            Row(
              children: [
                const Icon(Icons.warning_rounded, color: AppTheme.error, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text('Refus : ${cert.refus}', style: const TextStyle(color: AppTheme.error, fontSize: 12))),
              ],
            ),
          ],
          // Actions admin
          if (cert.statut == CertificationStatus.enAttente) ...[
            const Divider(color: AppTheme.navyLight, height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => assets.approuverCertification(cert.id),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approuver', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.success,
                      side: const BorderSide(color: AppTheme.success),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRefuser(context, cert, assets),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Refuser', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
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

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _partBadge(String label, double montant, Color color, String devise) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          Text(AppUtils.formatMontant(montant, devise: devise), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showRefuser(BuildContext context, CertificationDemande cert, AssetProvider assets) {
    final motifCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Refuser la certification', style: TextStyle(color: AppTheme.error)),
        content: TextField(
          controller: motifCtrl,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Motif du refus',
            labelStyle: const TextStyle(color: AppTheme.textMuted),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.navyLight)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.error)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              // Mise à jour locale du statut refus
              final idx = assets.certifications.indexWhere((c) => c.id == cert.id);
              if (idx != -1) {
                assets.certifications[idx].statut = CertificationStatus.refuse;
                assets.certifications[idx].refus = motifCtrl.text.trim();
                assets.certifications[idx].dateTraitement = DateTime.now();
                final assetIdx = assets.assets.indexWhere((a) => a.id == cert.assetId);
                if (assetIdx != -1) {
                  assets.assets[assetIdx].certificationStatus = CertificationStatus.refuse;
                }
                assets.updateAsset(assets.assets.firstWhere((a) => a.id == cert.assetId,
                    orElse: () => assets.assets.first));
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Certification refusée'), backgroundColor: AppTheme.error),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Confirmer le refus'),
          ),
        ],
      ),
    );
  }
}

// ─── TAB 3 : REVENUS PARTAGÉS ─────────────────────────────────────────────────
class _RevenusPartagesTab extends StatelessWidget {
  final AssetProvider assets;
  const _RevenusPartagesTab({required this.assets});

  @override
  Widget build(BuildContext context) {
    final certsPaye = assets.certifications.where((c) => c.paiementEffectue).toList();

    // Grouper par type d'autorité
    final Map<String, List<CertificationDemande>> byAutorite = {};
    for (final c in certsPaye) {
      byAutorite.putIfAbsent(c.autoriteType, () => []).add(c);
    }

    // Totaux globaux
    final totalGlobal = certsPaye.fold(0.0, (s, c) => s + c.frais);
    final totalAutorites = certsPaye.fold(0.0, (s, c) => s + c.frais * (c.partAutorite ?? 70) / 100);
    final totalAsman = certsPaye.fold(0.0, (s, c) => s + c.frais * (c.partPlateforme ?? 30) / 100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé global
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.success.withValues(alpha: 0.15), AppTheme.navyCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_rounded, color: AppTheme.success, size: 18),
                    const SizedBox(width: 8),
                    const Text('REVENUS TOTAUX', style: TextStyle(color: AppTheme.success, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(AppUtils.formatMontant(totalGlobal, devise: 'EUR'),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _miniRevenu('Autorités', totalAutorites, AppTheme.colorInvestissement)),
                    const SizedBox(width: 12),
                    Expanded(child: _miniRevenu('Asman (30%)', totalAsman, AppTheme.gold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (certsPaye.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.receipt_long_outlined, color: AppTheme.textMuted, size: 64),
                  const SizedBox(height: 16),
                  const Text('Aucun revenu enregistré', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Les revenus apparaîtront après paiement des certifications', style: TextStyle(color: AppTheme.textMuted), textAlign: TextAlign.center),
                ],
              ),
            )
          else ...[
            const Text('Par type d\'autorité', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...byAutorite.entries.map((entry) => _autoriteRevenusCard(entry.key, entry.value)),
            const SizedBox(height: 20),

            const Text('Historique des paiements', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...certsPaye.map((c) => _paiementTile(c)),
          ],
          const SizedBox(height: 20),

          // Explication modèle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_rounded, color: AppTheme.gold, size: 16),
                    SizedBox(width: 8),
                    Text('Modèle économique Asman', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Asman facilite la certification des actifs en connectant les propriétaires aux autorités habilitées. '
                  'Les frais de certification sont automatiquement répartis : 70% à l\'autorité pour son travail, '
                  '30% à Asman pour la plateforme et les services digitaux.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                _modeItem(Icons.shield_rounded, 'Prévention des doublons', 'Un actif certifié ne peut être certifié deux fois'),
                _modeItem(Icons.lock_rounded, 'Vente/location sécurisée', 'Seuls les actifs certifiés accèdent à la Marketplace'),
                _modeItem(Icons.verified_rounded, 'Testament certifié', 'Les testaments peuvent être certifiés par un notaire'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _miniRevenu(String label, double montant, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(AppUtils.formatMontant(montant, devise: 'EUR'),
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _autoriteRevenusCard(String type, List<CertificationDemande> certs) {
    final total = certs.fold(0.0, (s, c) => s + c.frais);
    final partAutorite = certs.fold(0.0, (s, c) => s + c.frais * (c.partAutorite ?? 70) / 100);

    final icons = {
      'notaire': Icons.gavel_rounded,
      'huissier': Icons.badge_rounded,
      'tribunal': Icons.account_balance_rounded,
      'cadastre': Icons.map_rounded,
    };
    final color = AppTheme.colorInvestissement;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icons[type] ?? Icons.gavel_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.toUpperCase(), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${certs.length} certification(s)', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppUtils.formatMontant(partAutorite, devise: 'EUR'), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('sur ${AppUtils.formatMontant(total, devise: "EUR")}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paiementTile(CertificationDemande cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.navyLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_rounded, color: AppTheme.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cert.assetNom, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${cert.autoriteType} · ${AppUtils.formatDate(cert.dateDemande)}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppUtils.formatMontant(cert.frais, devise: cert.devise),
                  style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 13)),
              Text('70/30', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.gold, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12),
                children: [
                  TextSpan(text: '$title : ', style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  TextSpan(text: desc, style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
