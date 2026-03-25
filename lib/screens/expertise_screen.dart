import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_model.dart';
import '../models/asset_model.dart';
import '../providers/subscription_provider.dart';
import '../providers/asset_provider.dart';

class ExpertiseScreen extends StatefulWidget {
  const ExpertiseScreen({super.key});

  @override
  State<ExpertiseScreen> createState() => _ExpertiseScreenState();
}

class _ExpertiseScreenState extends State<ExpertiseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _filtreType;

  static const Color _navy = Color(0xFF0D1B2A);
  static const Color _gold = Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadCabinets();
      context.read<SubscriptionProvider>().loadExpertises();
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
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Expertise & Cabinets', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _gold,
          unselectedLabelColor: Colors.white54,
          indicatorColor: _gold,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'Cabinets'),
            Tab(icon: Icon(Icons.assignment), text: 'Mes demandes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _CabinetsTab(filtreType: _filtreType, onFiltreChange: (t) => setState(() => _filtreType = t)),
          const _MesDemandesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNouvelleDemandeDialog(context),
        backgroundColor: _gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle demande', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showNouvelleDemandeDialog(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF1A2C3D),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => const _NouvelleDemandeSheet(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ONGLET CABINETS
// ══════════════════════════════════════════════════════════════════════════════

class _CabinetsTab extends StatelessWidget {
  final String? filtreType;
  final ValueChanged<String?> onFiltreChange;

  const _CabinetsTab({this.filtreType, required this.onFiltreChange});

  static const List<Map<String, dynamic>> _types = [
    {'type': null,                'label': 'Tous',        'icon': Icons.all_inclusive},
    {'type': 'notaire',           'label': 'Notaires',    'icon': Icons.gavel},
    {'type': 'huissier',          'label': 'Huissiers',   'icon': Icons.balance},
    {'type': 'avocat',            'label': 'Avocats',     'icon': Icons.account_balance},
    {'type': 'expert_immobilier', 'label': 'Immobilier',  'icon': Icons.home_work},
    {'type': 'expert_vehicule',   'label': 'Auto',        'icon': Icons.directions_car},
    {'type': 'expert_financier',  'label': 'Finance',     'icon': Icons.trending_up},
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (ctx, prov, _) {
        final cabinets = filtreType == null
            ? prov.cabinets
            : prov.cabinets.where((c) => c.type == filtreType).toList();

        return Column(
          children: [
            // ─── Filtres ────────────────────────────────────────────
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _types.length,
                itemBuilder: (_, i) {
                  final t = _types[i];
                  final selected = filtreType == t['type'];
                  return GestureDetector(
                    onTap: () {
                      onFiltreChange(t['type'] as String?);
                      ctx.read<SubscriptionProvider>().loadCabinets(type: t['type'] as String?);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFFFB300) : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(t['icon'] as IconData, size: 14,
                              color: selected ? Colors.black : Colors.white70),
                          const SizedBox(width: 6),
                          Text(t['label'] as String,
                              style: TextStyle(
                                  color: selected ? Colors.black : Colors.white,
                                  fontSize: 12,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ─── Liste cabinets ───────────────────────────────────
            Expanded(
              child: prov.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB300)))
                  : cabinets.isEmpty
                      ? const Center(child: Text('Aucun cabinet disponible', style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: cabinets.length,
                          itemBuilder: (_, i) => _CabinetCard(cabinet: cabinets[i]),
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _CabinetCard extends StatelessWidget {
  final CabinetProfessionnel cabinet;
  const _CabinetCard({required this.cabinet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: cabinet.typeColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(cabinet.icon, color: cabinet.typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cabinet.nomCabinet,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: cabinet.typeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(cabinet.libelleType,
                              style: TextStyle(color: cabinet.typeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.location_on, size: 12, color: Colors.white54),
                        Text(cabinet.ville, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFB300), size: 14),
                      const SizedBox(width: 4),
                      Text(cabinet.noteMoyenne.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text('${cabinet.nbExpertises} expertises',
                      style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ],
          ),
          if (cabinet.specialites.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: cabinet.specialites
                  .take(3)
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(s.replaceAll('_', ' '),
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone, size: 14),
                  label: const Text('Appeler'),
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.assignment_add, size: 14),
                  label: const Text('Demander'),
                  onPressed: () => _showDemandeRapide(context, cabinet),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: cabinet.typeColor,
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDemandeRapide(BuildContext ctx, CabinetProfessionnel cab) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF1A2C3D),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _NouvelleDemandeSheet(cabinetPreselectionne: cab),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ONGLET MES DEMANDES
// ══════════════════════════════════════════════════════════════════════════════

class _MesDemandesTab extends StatelessWidget {
  const _MesDemandesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (ctx, prov, _) {
        if (prov.expertises.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_outlined, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('Aucune demande d\'expertise',
                    style: TextStyle(color: Colors.white54, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Faites évaluer vos actifs par des experts certifiés',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: prov.expertises.length,
          itemBuilder: (_, i) => _DemandeCard(demande: prov.expertises[i]),
        );
      },
    );
  }
}

class _DemandeCard extends StatelessWidget {
  final ExpertiseRequest demande;
  const _DemandeCard({required this.demande});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(demande.reference,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: demande.statutColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: demande.statutColor.withValues(alpha: 0.5))),
                child: Text(demande.statutLabel,
                    style: TextStyle(color: demande.statutColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.assignment, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(demande.typeExpertise.replaceAll('_', ' '),
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              if (demande.urgence) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                  child: const Text('URGENT', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text('${demande.montantTotal} XOF',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              if (demande.valeurEstimee != null) ...[
                const Text(' → ', style: TextStyle(color: Colors.white38)),
                Text('${demande.valeurEstimee!.toStringAsFixed(0)} XOF estimés',
                    style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
          if (demande.cabinet != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(demande.cabinet!.icon, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Text(demande.cabinet!.nomCabinet,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHEET NOUVELLE DEMANDE
// ══════════════════════════════════════════════════════════════════════════════

class _NouvelleDemandeSheet extends StatefulWidget {
  final CabinetProfessionnel? cabinetPreselectionne;
  const _NouvelleDemandeSheet({this.cabinetPreselectionne});

  @override
  State<_NouvelleDemandeSheet> createState() => _NouvelleDemandeSheetState();
}

class _NouvelleDemandeSheetState extends State<_NouvelleDemandeSheet> {
  String _typeExpertise = 'immobilier';
  Asset? _selectedAsset;
  CabinetProfessionnel? _selectedCabinet;
  bool _urgence = false;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCabinet = widget.cabinetPreselectionne;
  }

  static const List<Map<String, dynamic>> _types = [
    {'value': 'immobilier',    'label': 'Immobilier'},
    {'value': 'vehicule',      'label': 'Véhicule'},
    {'value': 'investissement', 'label': 'Investissement'},
    {'value': 'judiciaire',    'label': 'Judiciaire'},
    {'value': 'succession',    'label': 'Succession'},
  ];

  @override
  Widget build(BuildContext context) {
    final assets = context.read<AssetProvider>().assets;
    final prov   = context.read<SubscriptionProvider>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('Nouvelle demande d\'expertise',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),

            // ─── Type d'expertise ────────────────────────────────
            const Text('Type d\'expertise', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final selected = _typeExpertise == t['value'];
                return GestureDetector(
                  onTap: () => setState(() => _typeExpertise = t['value'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFFFB300) : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(t['label'] as String,
                        style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ─── Actif concerné ──────────────────────────────────
            const Text('Actif concerné', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Asset>(
              value: _selectedAsset,
              dropdownColor: const Color(0xFF1A2C3D),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                hintText: 'Sélectionner un actif',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
              onChanged: (a) => setState(() => _selectedAsset = a),
              items: assets.map((a) => DropdownMenuItem(
                value: a,
                child: Text('${a.nom} · ${a.type}', style: const TextStyle(color: Colors.white)),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // ─── Cabinet ─────────────────────────────────────────
            const Text('Cabinet (optionnel)', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<CabinetProfessionnel>(
              value: _selectedCabinet,
              dropdownColor: const Color(0xFF1A2C3D),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                hintText: 'Attribution automatique',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
              onChanged: (c) => setState(() => _selectedCabinet = c),
              items: prov.cabinets.map((c) => DropdownMenuItem(
                value: c,
                child: Text('${c.nomCabinet} · ${c.ville}', style: const TextStyle(color: Colors.white, fontSize: 13)),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // ─── Urgence ─────────────────────────────────────────
            SwitchListTile(
              title: const Text('Traitement urgent (+50%)', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Réponse sous 48h garantie', style: TextStyle(color: Colors.white54, fontSize: 12)),
              value: _urgence,
              onChanged: (v) => setState(() => _urgence = v),
              activeColor: const Color(0xFFFFB300),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // ─── Notes ───────────────────────────────────────────
            TextField(
              controller: _notesCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Notes ou informations complémentaires...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _selectedAsset == null ? null : () async {
                  Navigator.pop(context);
                  final ok = await prov.createExpertise(
                    assetId:       _selectedAsset!.id.hashCode,
                    typeExpertise: _typeExpertise,
                    cabinetId:     _selectedCabinet?.id,
                    notesClient:   _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
                    urgence:       _urgence,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'Demande créée avec succès !' : prov.error ?? 'Erreur'),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ));
                  }
                },
                child: const Text('Soumettre la demande',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
