import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../models/asset_model.dart';
import '../utils/app_utils.dart';
import '../widgets/pin_dialog.dart';

class TestamentScreen extends StatefulWidget {
  const TestamentScreen({super.key});
  @override
  State<TestamentScreen> createState() => _TestamentScreenState();
}

class _TestamentScreenState extends State<TestamentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetProvider>().loadData();
    });
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
        title: const Text('Testament & Succession', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppTheme.gold),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.description_rounded), text: 'Testament'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Ayants droits'),
            Tab(icon: Icon(Icons.support_agent_rounded), text: 'Ressources'),
            Tab(icon: Icon(Icons.pie_chart_rounded), text: 'Répartition'),
          ],
        ),
      ),
      body: Consumer2<AssetProvider, AuthProvider>(
        builder: (context, assets, auth, _) {
          final testament = assets.testament;
          final userId = auth.user?.id ?? '';
          return TabBarView(
            controller: _tabCtrl,
            children: [
              _TestamentTab(testament: testament, userId: userId),
              _AyantsDroitsTab(testament: testament, userId: userId),
              _PersonnesRessourcesTab(testament: testament, userId: userId),
              _RepartitionTab(testament: testament, assets: assets),
            ],
          );
        },
      ),
    );
  }
}

// ─── TAB 1 : TESTAMENT ────────────────────────────────────────────────────────
class _TestamentTab extends StatelessWidget {
  final Testament? testament;
  final String userId;
  const _TestamentTab({this.testament, required this.userId});

  Color _statutColor(TestamentStatus s) {
    switch (s) {
      case TestamentStatus.brouillon: return AppTheme.textMuted;
      case TestamentStatus.finalise: return AppTheme.colorInvestissement;
      case TestamentStatus.certifie: return AppTheme.success;
    }
  }

  String _statutLabel(TestamentStatus s) {
    switch (s) {
      case TestamentStatus.brouillon: return 'Brouillon';
      case TestamentStatus.finalise: return 'Finalisé';
      case TestamentStatus.certifie: return 'Certifié';
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = context.watch<AssetProvider>();
    if (testament == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_outlined, color: AppTheme.gold, size: 64),
              ),
              const SizedBox(height: 24),
              const Text('Aucun testament', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Créez votre testament pour organiser la transmission de votre patrimoine à vos ayants droits.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _creerTestament(context, assets, userId),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Créer mon testament'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.navyDark,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _statutColor(testament!.statut).withValues(alpha: 0.2),
                  AppTheme.navyCard,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _statutColor(testament!.statut).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_rounded, color: _statutColor(testament!.statut), size: 20),
                    const SizedBox(width: 8),
                    Text('STATUT', style: TextStyle(color: _statutColor(testament!.statut), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statutColor(testament!.statut).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statutColor(testament!.statut).withValues(alpha: 0.5)),
                      ),
                      child: Text(_statutLabel(testament!.statut),
                          style: TextStyle(color: _statutColor(testament!.statut), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _infoRow(Icons.calendar_today_rounded, 'Créé le',
                    AppUtils.formatDate(testament!.dateCreation)),
                if (testament!.dateModification != null)
                  _infoRow(Icons.edit_rounded, 'Modifié le',
                      AppUtils.formatDate(testament!.dateModification!)),
                if (testament!.dateCertification != null)
                  _infoRow(Icons.verified_rounded, 'Certifié le',
                      AppUtils.formatDate(testament!.dateCertification!)),
                if (testament!.notaireNom?.isNotEmpty == true)
                  _infoRow(Icons.person_rounded, 'Notaire', testament!.notaireNom!),
                if (testament!.certificationRef?.isNotEmpty == true)
                  _infoRow(Icons.tag_rounded, 'Référence', testament!.certificationRef!),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats
          Row(
            children: [
              _statCard('Ayants droits', '${testament!.ayantsDroits.length}', Icons.people_rounded, AppTheme.colorImmobilier),
              const SizedBox(width: 12),
              _statCard('Biens répartis', '${testament!.repartitions.map((r) => r.assetId).toSet().length}', Icons.account_balance_wallet_rounded, AppTheme.colorVehicule),
            ],
          ),
          const SizedBox(height: 20),

          // Notes
          if (testament!.notes.isNotEmpty) ...[
            const Text('Notes', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.navyCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.navyLight),
              ),
              child: Text(testament!.notes, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ),
            const SizedBox(height: 20),
          ],

          // Actions
          const Text('Actions', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _actionButton(context, Icons.edit_rounded, 'Modifier le testament',
              AppTheme.colorVehicule, () => _editTestament(context, assets)),
          const SizedBox(height: 10),
          if (testament!.statut == TestamentStatus.brouillon)
            _actionButton(context, Icons.check_circle_rounded, 'Finaliser le testament',
                AppTheme.colorInvestissement, () => _finaliserTestament(context, assets)),
          if (testament!.statut == TestamentStatus.finalise) ...[
            const SizedBox(height: 10),
            _actionButton(context, Icons.verified_rounded, 'Demander la certification notariale',
                AppTheme.gold, () => _demanderCertification(context, assets)),
          ],
          const SizedBox(height: 10),
          _actionButton(context, Icons.delete_rounded, 'Supprimer le testament',
              AppTheme.error, () => _confirmerSuppression(context, assets)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 16),
          const SizedBox(width: 8),
          Text('$label : ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Future<void> _creerTestament(BuildContext context, AssetProvider assets, String userId) async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.hasPinConfigured == true) {
      final ok = await PinDialog.show(context);
      if (!ok || !context.mounted) return;
    }
    final notesCtrl = TextEditingController();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Créer mon testament', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Commencez à rédiger votre testament. Vous pourrez ajouter des ayants droits et répartir vos biens.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Notes préliminaires (optionnel)',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.navyLight)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.gold)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              final t = Testament(
                id: assets.generateId(),
                userId: userId,
                dateCreation: DateTime.now(),
                notes: notesCtrl.text.trim(),
              );
              assets.saveTestament(t);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: AppTheme.navyDark),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _editTestament(BuildContext context, AssetProvider assets) async {
    if (testament == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.user?.hasPinConfigured == true) {
      final ok = await PinDialog.show(context);
      if (!ok || !context.mounted) return;
    }
    final notesCtrl = TextEditingController(text: testament!.notes);
    final notaireCtrl = TextEditingController(text: testament!.notaireNom ?? '');
    final contactCtrl = TextEditingController(text: testament!.notaireContact ?? '');
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Modifier le testament', style: TextStyle(color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: notesCtrl,
                maxLines: 4,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Notes',
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.navyLight)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.gold)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notaireCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nom du notaire',
                  prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.textMuted),
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.navyLight)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.gold)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Contact du notaire',
                  prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.textMuted),
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.navyLight)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.gold)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              final updated = Testament(
                id: testament!.id,
                userId: testament!.userId,
                statut: testament!.statut,
                notes: notesCtrl.text.trim(),
                dateCreation: testament!.dateCreation,
                dateModification: DateTime.now(),
                dateCertification: testament!.dateCertification,
                notaireNom: notaireCtrl.text.trim(),
                notaireContact: contactCtrl.text.trim(),
                certificationRef: testament!.certificationRef,
                ayantsDroits: testament!.ayantsDroits,
                repartitions: testament!.repartitions,
                paiementCertifEffectue: testament!.paiementCertifEffectue,
              );
              assets.saveTestament(updated);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: AppTheme.navyDark),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _finaliserTestament(BuildContext context, AssetProvider assets) async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.hasPinConfigured == true) {
      final ok = await PinDialog.show(context);
      if (!ok || !context.mounted) return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Finaliser le testament', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'En finalisant votre testament, vous confirmez que le contenu est complet. Vous pourrez ensuite demander sa certification notariale.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              final updated = Testament(
                id: testament!.id,
                userId: testament!.userId,
                statut: TestamentStatus.finalise,
                notes: testament!.notes,
                dateCreation: testament!.dateCreation,
                dateModification: DateTime.now(),
                notaireNom: testament!.notaireNom,
                notaireContact: testament!.notaireContact,
                certificationRef: testament!.certificationRef,
                ayantsDroits: testament!.ayantsDroits,
                repartitions: testament!.repartitions,
                paiementCertifEffectue: testament!.paiementCertifEffectue,
              );
              assets.saveTestament(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Testament finalisé avec succès'), backgroundColor: AppTheme.colorInvestissement),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colorInvestissement, foregroundColor: Colors.white),
            child: const Text('Finaliser'),
          ),
        ],
      ),
    );
  }

  void _demanderCertification(BuildContext context, AssetProvider assets) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Certification notariale', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Frais de certification', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('• Notaire : 70% des frais', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  Text('• Plateforme Asman : 30% des frais', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'La certification est effectuée par un notaire agréé. Une fois certifié, le testament est légalement opposable.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              final updated = Testament(
                id: testament!.id,
                userId: testament!.userId,
                statut: TestamentStatus.certifie,
                notes: testament!.notes,
                dateCreation: testament!.dateCreation,
                dateModification: testament!.dateModification,
                dateCertification: DateTime.now(),
                notaireNom: testament!.notaireNom ?? 'Notaire Asman',
                notaireContact: testament!.notaireContact,
                certificationRef: 'CERT-${DateTime.now().millisecondsSinceEpoch}',
                ayantsDroits: testament!.ayantsDroits,
                repartitions: testament!.repartitions,
                paiementCertifEffectue: true,
              );
              assets.saveTestament(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demande de certification envoyée au notaire'), backgroundColor: AppTheme.gold),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: AppTheme.navyDark),
            child: const Text('Demander'),
          ),
        ],
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, AssetProvider assets) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Supprimer le testament', style: TextStyle(color: AppTheme.error)),
        content: const Text('Cette action est irréversible. Êtes-vous sûr ?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              final updated = Testament(
                id: assets.generateId(),
                userId: testament!.userId,
                dateCreation: DateTime.now(),
              );
              // On "supprime" en créant un brouillon vide - simplification locale
              assets.saveTestament(updated..ayantsDroits.clear());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ─── TAB 2 : AYANTS DROITS ────────────────────────────────────────────────────
class _AyantsDroitsTab extends StatelessWidget {
  final Testament? testament;
  final String userId;
  const _AyantsDroitsTab({this.testament, required this.userId});

  @override
  Widget build(BuildContext context) {
    final assets = context.watch<AssetProvider>();
    final ayantsDroits = testament?.ayantsDroits ?? [];

    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      body: ayantsDroits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, color: AppTheme.textMuted, size: 64),
                  const SizedBox(height: 16),
                  const Text('Aucun ayant droit', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Ajoutez vos héritiers et légataires', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ayantsDroits.length,
              itemBuilder: (ctx, i) => _buildAyantDroitCard(ctx, ayantsDroits[i], assets),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: testament == null
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Créez d\'abord un testament'), backgroundColor: AppTheme.error))
            : () => _showAjouterAyantDroit(context, assets),
        backgroundColor: AppTheme.gold,
        foregroundColor: AppTheme.navyDark,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Color _typeColor(AyantDroitType t) {
    switch (t) {
      case AyantDroitType.heritier: return AppTheme.colorImmobilier;
      case AyantDroitType.legataire: return AppTheme.colorInvestissement;
      case AyantDroitType.ascendant: return AppTheme.gold;
      case AyantDroitType.conjoint: return AppTheme.colorVehicule;
      case AyantDroitType.autre: return AppTheme.colorCreance;
    }
  }

  String _typeLabel(AyantDroitType t) {
    switch (t) {
      case AyantDroitType.heritier: return 'Héritier';
      case AyantDroitType.legataire: return 'Légataire';
      case AyantDroitType.ascendant: return 'Ascendant';
      case AyantDroitType.conjoint: return 'Conjoint';
      case AyantDroitType.autre: return 'Autre';
    }
  }

  Widget _buildAyantDroitCard(BuildContext context, AyantDroit ad, AssetProvider assets) {
    final color = _typeColor(ad.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            ad.nomComplet.isNotEmpty ? ad.nomComplet[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(ad.nomComplet.isNotEmpty ? ad.nomComplet : 'Sans nom',
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_typeLabel(ad.type), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                if (ad.lienParente.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(ad.lienParente, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ],
            ),
            if (ad.contact.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(ad.contact, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppTheme.navyMedium,
          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
          onSelected: (val) {
            if (val == 'edit') _showEditAyantDroit(context, ad, assets);
            if (val == 'delete') _confirmerSuppression(context, ad, assets);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier', style: TextStyle(color: AppTheme.textPrimary))),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: AppTheme.error))),
          ],
        ),
      ),
    );
  }

  void _showAjouterAyantDroit(BuildContext context, AssetProvider assets) {
    _showFormAyantDroit(context, null, assets);
  }

  void _showEditAyantDroit(BuildContext context, AyantDroit ad, AssetProvider assets) {
    _showFormAyantDroit(context, ad, assets);
  }

  void _showFormAyantDroit(BuildContext context, AyantDroit? existing, AssetProvider assets) {
    final nomCtrl = TextEditingController(text: existing?.nom ?? '');
    final prenomCtrl = TextEditingController(text: existing?.prenom ?? '');
    final lienCtrl = TextEditingController(text: existing?.lienParente ?? '');
    final contactCtrl = TextEditingController(text: existing?.contact ?? '');
    final natCtrl = TextEditingController(text: existing?.nationalite ?? '');
    final pieceCtrl = TextEditingController(text: existing?.numeroPieceIdentite ?? '');
    AyantDroitType selectedType = existing?.type ?? AyantDroitType.heritier;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.navyMedium,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: StatefulBuilder(
          builder: (ctx2, setLocal) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'Ajouter un ayant droit' : 'Modifier',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: AyantDroitType.values.map((t) {
                    final labels = ['Héritier', 'Légataire', 'Ascendant', 'Conjoint', 'Autre'];
                    final isSelected = selectedType == t;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ChoiceChip(
                          label: Text(labels[t.index], style: TextStyle(fontSize: 10, color: isSelected ? AppTheme.navyDark : AppTheme.textMuted)),
                          selected: isSelected,
                          selectedColor: AppTheme.gold,
                          backgroundColor: AppTheme.navyCard,
                          onSelected: (_) => setLocal(() => selectedType = t),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _field(prenomCtrl, 'Prénom', Icons.person_rounded),
                const SizedBox(height: 12),
                _field(nomCtrl, 'Nom *', Icons.person_rounded),
                const SizedBox(height: 12),
                _field(lienCtrl, 'Lien de parenté', Icons.family_restroom_rounded),
                const SizedBox(height: 12),
                _field(contactCtrl, 'Contact (tél/email)', Icons.contact_phone_rounded),
                const SizedBox(height: 12),
                _field(natCtrl, 'Nationalité', Icons.flag_rounded),
                const SizedBox(height: 12),
                _field(pieceCtrl, 'N° pièce d\'identité', Icons.credit_card_rounded),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nomCtrl.text.trim().isEmpty) return;
                      final ad = AyantDroit(
                        id: existing?.id ?? assets.generateId(),
                        nom: nomCtrl.text.trim(),
                        prenom: prenomCtrl.text.trim(),
                        type: selectedType,
                        lienParente: lienCtrl.text.trim(),
                        contact: contactCtrl.text.trim(),
                        nationalite: natCtrl.text.trim(),
                        numeroPieceIdentite: pieceCtrl.text.trim(),
                      );
                      final t = testament!;
                      List<AyantDroit> newList;
                      if (existing != null) {
                        newList = t.ayantsDroits.map((x) => x.id == existing.id ? ad : x).toList();
                      } else {
                        newList = [...t.ayantsDroits, ad];
                      }
                      assets.saveTestament(Testament(
                        id: t.id, userId: t.userId, statut: t.statut,
                        notes: t.notes, dateCreation: t.dateCreation,
                        dateModification: DateTime.now(),
                        dateCertification: t.dateCertification,
                        notaireNom: t.notaireNom, notaireContact: t.notaireContact,
                        certificationRef: t.certificationRef,
                        ayantsDroits: newList, repartitions: t.repartitions,
                        paiementCertifEffectue: t.paiementCertifEffectue,
                      ));
                      Navigator.pop(ctx2);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold, foregroundColor: AppTheme.navyDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(existing == null ? 'Ajouter' : 'Enregistrer',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        labelStyle: const TextStyle(color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.navyCard,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.navyLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, AyantDroit ad, AssetProvider assets) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Supprimer', style: TextStyle(color: AppTheme.error)),
        content: Text('Supprimer ${ad.nomComplet} de vos ayants droits ?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              final t = testament!;
              final newList = t.ayantsDroits.where((x) => x.id != ad.id).toList();
              final newRepartitions = t.repartitions.where((r) => r.ayantDroitId != ad.id).toList();
              assets.saveTestament(Testament(
                id: t.id, userId: t.userId, statut: t.statut,
                notes: t.notes, dateCreation: t.dateCreation,
                dateModification: DateTime.now(),
                notaireNom: t.notaireNom, notaireContact: t.notaireContact,
                certificationRef: t.certificationRef,
                ayantsDroits: newList, repartitions: newRepartitions,
                paiementCertifEffectue: t.paiementCertifEffectue,
              ));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ─── TAB 3 : PERSONNES RESSOURCES ──────────────────────────────────────────────
class _PersonnesRessourcesTab extends StatelessWidget {
  final Testament? testament;
  final String userId;
  const _PersonnesRessourcesTab({this.testament, required this.userId});

  @override
  Widget build(BuildContext context) {
    final assets = context.watch<AssetProvider>();
    final ressources = testament?.personnesRessources ?? [];

    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      body: ressources.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent_rounded, color: AppTheme.textMuted, size: 64),
                  const SizedBox(height: 16),
                  const Text('Aucune personne ressource', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Ajoutez des personnes de confiance (max 3)\npour témoigner en cas de succession.',
                      style: TextStyle(color: AppTheme.textMuted), textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ressources.length,
              itemBuilder: (ctx, i) => _buildRessourceCard(ctx, ressources[i], assets),
            ),
      floatingActionButton: testament == null
          ? FloatingActionButton.extended(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Créez d\'abord un testament'), backgroundColor: AppTheme.error)),
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.navyDark,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : ressources.length >= 3
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showFormRessource(context, null, assets),
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.navyDark,
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
    );
  }

  Widget _buildRessourceCard(BuildContext context, PersonneRessource pr, AssetProvider assets) {
    const color = AppTheme.gold;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            pr.nomComplet.isNotEmpty ? pr.nomComplet[0].toUpperCase() : '?',
            style: const TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(pr.nomComplet.isNotEmpty ? pr.nomComplet : 'Sans nom',
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            if (pr.qualite.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(pr.qualite, style: const TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            if (pr.telephone.isNotEmpty) Text('Tél: ${pr.telephone}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            if (pr.email.isNotEmpty) Text('Email: ${pr.email}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppTheme.navyMedium,
          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
          onSelected: (val) {
            if (val == 'edit') _showFormRessource(context, pr, assets);
            if (val == 'delete') _confirmerSuppression(context, pr, assets);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier', style: TextStyle(color: AppTheme.textPrimary))),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: AppTheme.error))),
          ],
        ),
      ),
    );
  }

  void _showFormRessource(BuildContext context, PersonneRessource? existing, AssetProvider assets) {
    final nomCtrl = TextEditingController(text: existing?.nom ?? '');
    final prenomCtrl = TextEditingController(text: existing?.prenom ?? '');
    final qualiteCtrl = TextEditingController(text: existing?.qualite ?? '');
    final telCtrl = TextEditingController(text: existing?.telephone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.navyMedium,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'Ajouter une personne ressource' : 'Modifier',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: prenomCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textMuted, size: 20),
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true, fillColor: AppTheme.navyCard,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.navyLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nomCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.textMuted, size: 20),
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true, fillColor: AppTheme.navyCard,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.navyLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qualiteCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Qualité (ex: Ami, Médecin, ...)',
                  prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.textMuted, size: 20),
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true, fillColor: AppTheme.navyCard,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.navyLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.textMuted, size: 20),
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true, fillColor: AppTheme.navyCard,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.navyLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_rounded, color: AppTheme.textMuted, size: 20),
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true, fillColor: AppTheme.navyCard,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.navyLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nomCtrl.text.trim().isEmpty) return;
                    final pr = PersonneRessource(
                      id: existing?.id ?? assets.generateId(),
                      nom: nomCtrl.text.trim(),
                      prenom: prenomCtrl.text.trim(),
                      qualite: qualiteCtrl.text.trim(),
                      telephone: telCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      notes: notesCtrl.text.trim(),
                    );
                    final t = testament!;
                    List<PersonneRessource> newList;
                    if (existing != null) {
                      newList = t.personnesRessources.map((x) => x.id == existing.id ? pr : x).toList();
                    } else {
                      newList = [...t.personnesRessources, pr];
                    }
                    assets.saveTestament(Testament(
                      id: t.id, userId: t.userId, statut: t.statut,
                      notes: t.notes, dateCreation: t.dateCreation,
                      dateModification: DateTime.now(),
                      dateCertification: t.dateCertification,
                      notaireNom: t.notaireNom, notaireContact: t.notaireContact,
                      certificationRef: t.certificationRef,
                      ayantsDroits: t.ayantsDroits, repartitions: t.repartitions,
                      personnesRessources: newList, // Update that
                      paiementCertifEffectue: t.paiementCertifEffectue,
                    ));
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold, foregroundColor: AppTheme.navyDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(existing == null ? 'Ajouter' : 'Enregistrer',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, PersonneRessource pr, AssetProvider assets) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Supprimer', style: TextStyle(color: AppTheme.error)),
        content: Text('Supprimer ${pr.nomComplet} des personnes ressources ?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              final t = testament!;
              final newList = t.personnesRessources.where((x) => x.id != pr.id).toList();
              assets.saveTestament(Testament(
                id: t.id, userId: t.userId, statut: t.statut,
                notes: t.notes, dateCreation: t.dateCreation,
                dateModification: DateTime.now(),
                notaireNom: t.notaireNom, notaireContact: t.notaireContact,
                certificationRef: t.certificationRef,
                ayantsDroits: t.ayantsDroits, repartitions: t.repartitions,
                personnesRessources: newList, // Update that
                paiementCertifEffectue: t.paiementCertifEffectue,
              ));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ─── TAB 4 : RÉPARTITION ─────────────────────────────────────────────────────
class _RepartitionTab extends StatelessWidget {
  final Testament? testament;
  final AssetProvider assets;
  const _RepartitionTab({this.testament, required this.assets});

  @override
  Widget build(BuildContext context) {
    final repartitions = testament?.repartitions ?? [];
    final assetsActifs = assets.assets.where((a) => a.statut != AssetStatus.vendu).toList();

    // Grouper par actif
    final Map<String, List<RepartitionBien>> byAsset = {};
    for (final r in repartitions) {
      byAsset.putIfAbsent(r.assetId, () => []).add(r);
    }

    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé
            if (repartitions.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.navyCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('${byAsset.length}', 'Biens\nrépartis', AppTheme.gold),
                    _stat('${testament!.ayantsDroits.length}', 'Ayants\ndroits', AppTheme.colorImmobilier),
                    _stat('${repartitions.length}', 'Parts\ndéfinies', AppTheme.colorVehicule),
                  ],
                ),
              ),

            // Par actif
            if (byAsset.isEmpty && testament != null && testament!.ayantsDroits.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.pie_chart_outline, color: AppTheme.textMuted, size: 64),
                    const SizedBox(height: 16),
                    const Text('Aucune répartition définie', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Répartissez vos biens entre vos ayants droits', style: TextStyle(color: AppTheme.textMuted), textAlign: TextAlign.center),
                  ],
                ),
              )
            else if (testament == null || testament!.ayantsDroits.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.people_outline, color: AppTheme.textMuted, size: 64),
                    const SizedBox(height: 16),
                    const Text('Ajoutez d\'abord des ayants droits', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16), textAlign: TextAlign.center),
                  ],
                ),
              )
            else ...[
              const Text('Répartition par bien', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...assetsActifs.map((asset) {
                final parts = byAsset[asset.id] ?? [];
                final totalPct = parts.fold(0.0, (s, r) => s + r.pourcentage);
                return _assetRepartitionCard(context, asset, parts, totalPct);
              }),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: testament != null && testament!.ayantsDroits.isNotEmpty && assetsActifs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAjouterRepartition(context),
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.navyDark,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter une part', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _assetRepartitionCard(BuildContext context, Asset asset, List<RepartitionBien> parts, double totalPct) {
    final isComplete = totalPct >= 100;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isComplete ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.navyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.gold, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset.nom, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      Text('${AppUtils.formatMontant(asset.valeurActuelle, devise: asset.devise)} · ${totalPct.toStringAsFixed(0)}% réparti',
                          style: TextStyle(color: isComplete ? AppTheme.success : AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (isComplete)
                  const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
              ],
            ),
          ),
          if (parts.isNotEmpty) ...[
            const Divider(color: AppTheme.navyLight, height: 1),
            ...parts.map((r) => _partTile(context, r)),
          ],
          if (!isComplete && parts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Text('⚠️ ${(100 - totalPct).toStringAsFixed(0)}% non attribué',
                  style: const TextStyle(color: AppTheme.warning, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _partTile(BuildContext context, RepartitionBien r) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppTheme.colorImmobilier.withValues(alpha: 0.2),
        child: Text('${r.pourcentage.toStringAsFixed(0)}%',
            style: const TextStyle(color: AppTheme.colorImmobilier, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
      title: Text(r.ayantDroitNom, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      subtitle: r.conditions.isNotEmpty ? Text(r.conditions, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)) : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
        onPressed: () => _supprimerRepartition(context, r),
      ),
    );
  }

  void _supprimerRepartition(BuildContext context, RepartitionBien r) {
    if (testament == null) return;
    final t = testament!;
    final newList = t.repartitions.where((x) => x.id != r.id).toList();
    assets.saveTestament(Testament(
      id: t.id, userId: t.userId, statut: t.statut,
      notes: t.notes, dateCreation: t.dateCreation,
      dateModification: DateTime.now(),
      notaireNom: t.notaireNom, notaireContact: t.notaireContact,
      certificationRef: t.certificationRef,
      ayantsDroits: t.ayantsDroits, repartitions: newList,
      paiementCertifEffectue: t.paiementCertifEffectue,
    ));
  }

  void _showAjouterRepartition(BuildContext context) {
    if (testament == null) return;
    final assetsActifs = assets.assets.where((a) => a.statut != AssetStatus.vendu).toList();
    Asset? selectedAsset = assetsActifs.isNotEmpty ? assetsActifs.first : null;
    AyantDroit? selectedAyantDroit = testament!.ayantsDroits.isNotEmpty ? testament!.ayantsDroits.first : null;
    final pctCtrl = TextEditingController();
    final conditionsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.navyMedium,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: StatefulBuilder(
          builder: (ctx2, setLocal) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ajouter une part', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // Sélection actif
                const Text('Bien', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Asset>(
                  value: selectedAsset,
                  dropdownColor: AppTheme.navyMedium,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    filled: true, fillColor: AppTheme.navyCard,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.navyLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
                  ),
                  items: assetsActifs.map((a) => DropdownMenuItem(value: a, child: Text(a.nom, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setLocal(() => selectedAsset = v),
                ),
                const SizedBox(height: 16),
                // Sélection ayant droit
                const Text('Ayant droit', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<AyantDroit>(
                  value: selectedAyantDroit,
                  dropdownColor: AppTheme.navyMedium,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    filled: true, fillColor: AppTheme.navyCard,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.navyLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
                  ),
                  items: testament!.ayantsDroits.map((a) => DropdownMenuItem(value: a, child: Text(a.nomComplet))).toList(),
                  onChanged: (v) => setLocal(() => selectedAyantDroit = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pctCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Pourcentage *',
                    suffixText: '%',
                    suffixStyle: const TextStyle(color: AppTheme.gold),
                    labelStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true, fillColor: AppTheme.navyCard,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.navyLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: conditionsCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Conditions (optionnel)',
                    labelStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true, fillColor: AppTheme.navyCard,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.navyLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedAsset == null || selectedAyantDroit == null || pctCtrl.text.isEmpty) return;
                      final pct = double.tryParse(pctCtrl.text) ?? 0;
                      if (pct <= 0 || pct > 100) return;
                      final t = testament!;
                      final r = RepartitionBien(
                        id: assets.generateId(),
                        testamentId: t.id,
                        assetId: selectedAsset!.id,
                        assetNom: selectedAsset!.nom,
                        ayantDroitId: selectedAyantDroit!.id,
                        ayantDroitNom: selectedAyantDroit!.nomComplet,
                        pourcentage: pct,
                        conditions: conditionsCtrl.text.trim(),
                      );
                      assets.saveTestament(Testament(
                        id: t.id, userId: t.userId, statut: t.statut,
                        notes: t.notes, dateCreation: t.dateCreation,
                        dateModification: DateTime.now(),
                        notaireNom: t.notaireNom, notaireContact: t.notaireContact,
                        certificationRef: t.certificationRef,
                        ayantsDroits: t.ayantsDroits,
                        repartitions: [...t.repartitions, r],
                        paiementCertifEffectue: t.paiementCertifEffectue,
                      ));
                      Navigator.pop(ctx2);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold, foregroundColor: AppTheme.navyDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Ajouter la part', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
