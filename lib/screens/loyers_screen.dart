import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';
import '../widgets/pin_dialog.dart';

class LoyersScreen extends StatefulWidget {
  final String? filterAssetId;
  const LoyersScreen({super.key, this.filterAssetId});
  @override
  State<LoyersScreen> createState() => _LoyersScreenState();
}

class _LoyersScreenState extends State<LoyersScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Plage de date pour le rapport
  DateTime _rapportDebut = DateTime(DateTime.now().year, 1);
  DateTime _rapportFin = DateTime(DateTime.now().year, DateTime.now().month);
  String? _rapportAssetId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  static const List<String> _moisLabels = [
    '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jui',
    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
  ];

  String _formatMois(DateTime d) => '${_moisLabels[d.month]} ${d.year}';

  StatutPeriodeLoyer _statutPeriode(Loyer loyer, int mois, int annee) {
    try {
      return loyer.periodes.firstWhere((p) => p.mois == mois && p.annee == annee).statut;
    } catch (_) {
      return StatutPeriodeLoyer.enAttente;
    }
  }

  EncaissementPeriode? _getPeriode(Loyer loyer, int mois, int annee) {
    try {
      return loyer.periodes.firstWhere((p) => p.mois == mois && p.annee == annee);
    } catch (_) {
      return null;
    }
  }

  // ─── UI principal ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer2<AssetProvider, AuthProvider>(
      builder: (ctx, prov, auth, _) {
        final devise = auth.user?.devise ?? 'XOF';
        final visible = auth.balancesVisible;
        final biens = widget.filterAssetId != null
            ? prov.assets.where((a) => a.id == widget.filterAssetId && a.estLoue).toList()
            : prov.assets.where((a) => a.estLoue).toList();
        final loyers = widget.filterAssetId != null
            ? prov.loyers.where((l) => l.assetId == widget.filterAssetId).toList()
            : prov.loyers;

        // Total attendu ce mois
        final totalAttendu = loyers.fold(0.0, (s, l) => s + l.montant);
        final totalPercuMois = loyers.fold(0.0, (s, l) {
          final p = _getPeriode(l, _currentMonth.month, _currentMonth.year);
          return s + (p?.statut == StatutPeriodeLoyer.paye ? (p!.montantPaye ?? l.montant) : 0);
        });
        final totalImpayeMois = loyers.fold(0.0, (s, l) {
          final p = _getPeriode(l, _currentMonth.month, _currentMonth.year);
          return s + (p?.statut == StatutPeriodeLoyer.impaye ? l.montant : 0);
        });

        return Scaffold(
          backgroundColor: AppTheme.navyDark,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, biens.length, totalAttendu, totalPercuMois, devise, visible, prov, auth),
                // Onglets
                Container(
                  color: AppTheme.navyMedium,
                  child: TabBar(
                    controller: _tab,
                    indicatorColor: AppTheme.gold,
                    labelColor: AppTheme.gold,
                    unselectedLabelColor: AppTheme.textMuted,
                    tabs: const [
                      Tab(text: 'Encaissement mensuel'),
                      Tab(text: 'Rapport & Historique'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _buildMensuelTab(context, prov, auth, biens, loyers, totalAttendu, totalPercuMois, totalImpayeMois, devise, visible),
                      _buildRapportTab(context, prov, auth, devise, visible),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, int nbBiens, double totalAttendu, double totalPercu,
      String devise, bool visible, AssetProvider prov, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: AppTheme.navyMedium,
      child: Row(
        children: [
          if (widget.filterAssetId != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Loyers', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('$nbBiens bien${nbBiens > 1 ? 's' : ''} en location',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  visible ? AppUtils.formatMontant(totalPercu, devise: devise) : '••••••',
                  style: const TextStyle(color: AppTheme.success, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text('/mois perçu', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: ENCAISSEMENT MENSUEL ───────────────────────────────────────────
  Widget _buildMensuelTab(BuildContext context, AssetProvider prov, AuthProvider auth,
      List<Asset> biens, List<Loyer> loyers, double totalAttendu, double totalPercu,
      double totalImpaye, String devise, bool visible) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Sélecteur de mois
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.gold),
                onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
              ),
              Text(
                _formatMois(_currentMonth),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.gold),
                onPressed: () {
                  final next = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  if (!next.isAfter(DateTime.now())) setState(() => _currentMonth = next);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Résumé mensuel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                _summaryCell('Attendu', totalAttendu, AppTheme.textMuted, devise, visible),
                _summaryCell('Perçu', totalPercu, AppTheme.success, devise, visible),
                _summaryCell('Impayé', totalImpaye, AppTheme.danger, devise, visible),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (biens.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(children: [
                  const Icon(Icons.vpn_key_outlined, color: AppTheme.textMuted, size: 52),
                  const SizedBox(height: 12),
                  const Text('Aucun bien en location', style: TextStyle(color: AppTheme.textSecondary)),
                ]),
              ),
            )
          else ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Biens loués', style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 10),
            ...biens.map((asset) {
              final loyer = loyers.where((l) => l.assetId == asset.id).toList();
              if (loyer.isEmpty) return const SizedBox();
              final l = loyer.first;
              final statut = _statutPeriode(l, _currentMonth.month, _currentMonth.year);
              return _buildBienMensuelCard(context, asset, l, statut, devise, visible, prov, auth);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildBienMensuelCard(BuildContext context, Asset asset, Loyer loyer,
      StatutPeriodeLoyer statut, String devise, bool visible, AssetProvider prov, AuthProvider auth) {
    final color = statut == StatutPeriodeLoyer.paye
        ? AppTheme.success
        : statut == StatutPeriodeLoyer.impaye
            ? AppTheme.danger
            : AppTheme.textMuted;
    final statutLabel = statut == StatutPeriodeLoyer.paye
        ? 'Encaissé'
        : statut == StatutPeriodeLoyer.impaye
            ? 'Impayé'
            : 'En attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppUtils.getColorForType(asset.type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(AppUtils.getIconForType(asset.type), color: AppUtils.getColorForType(asset.type), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(asset.nom, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  if (asset.locataire != null)
                    Text(asset.locataire!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  visible ? AppUtils.formatMontant(loyer.montant, devise: devise) : '••••',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(statutLabel, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
          if (statut == StatutPeriodeLoyer.enAttente) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmerEncaissement(context, prov, auth, loyer),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Confirmer', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _marquerImpaye(context, prov, auth, loyer),
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: AppTheme.danger),
                  label: const Text('Impayé', style: TextStyle(fontSize: 12, color: AppTheme.danger)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.danger),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ]),
          ],
          // Bouton résilier toujours présent
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _resilierLocation(context, prov, auth, asset),
              icon: const Icon(Icons.no_encryption_rounded, size: 14, color: AppTheme.danger),
              label: const Text('Résilier la location', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: RAPPORT & HISTORIQUE ───────────────────────────────────────────
  Widget _buildRapportTab(BuildContext context, AssetProvider prov, AuthProvider auth,
      String devise, bool visible) {
    final biens = prov.assets.where((a) => a.estLoue).toList();
    final loyers = prov.loyers;
    _rapportAssetId ??= (loyers.isNotEmpty ? loyers.first.assetId : null);

    // Filtre par plage de date
    List<_PeriodeRow> rows = [];
    if (_rapportAssetId != null) {
      final loyer = loyers.where((l) => l.assetId == _rapportAssetId).toList();
      if (loyer.isNotEmpty) {
        final l = loyer.first;
        // Générer toutes les périodes dans la plage
        DateTime cursor = DateTime(_rapportDebut.year, _rapportDebut.month);
        while (!cursor.isAfter(_rapportFin)) {
          final p = _getPeriode(l, cursor.month, cursor.year);
          rows.add(_PeriodeRow(
            label: _formatMois(cursor),
            montant: l.montant,
            periode: p,
          ));
          cursor = DateTime(cursor.year, cursor.month + 1);
        }
      }
    }

    final totalPercu = rows.where((r) => r.periode?.statut == StatutPeriodeLoyer.paye)
        .fold(0.0, (s, r) => s + (r.periode!.montantPaye ?? r.montant));
    final totalImpaye = rows.where((r) => r.periode?.statut == StatutPeriodeLoyer.impaye)
        .fold(0.0, (s, r) => s + r.montant);
    final totalAttendu = rows.fold(0.0, (s, r) => s + r.montant);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RAPPORT D\'ENCAISSEMENT', style: TextStyle(color: AppTheme.gold, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // Sélecteur bien
          if (biens.length > 1) ...[
            DropdownButtonFormField<String>(
              value: _rapportAssetId,
              dropdownColor: AppTheme.navyMedium,
              decoration: const InputDecoration(
                labelText: 'Bien en location',
                prefixIcon: Icon(Icons.home_rounded, color: AppTheme.gold, size: 18),
              ),
              items: biens.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nom, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
              onChanged: (v) => setState(() => _rapportAssetId = v),
            ),
            const SizedBox(height: 12),
          ],

          // Plage de dates
          Row(children: [
            Expanded(child: _datePicker('Du', _rapportDebut, (d) => setState(() => _rapportDebut = d))),
            const SizedBox(width: 10),
            Expanded(child: _datePicker('Au', _rapportFin, (d) => setState(() => _rapportFin = d))),
          ]),
          const SizedBox(height: 16),

          // Résumé
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _summaryCell('Total attendu', totalAttendu, AppTheme.textMuted, devise, visible),
                _summaryCell('Perçu', totalPercu, AppTheme.success, devise, visible),
                _summaryCell('Impayé', totalImpaye, AppTheme.danger, devise, visible),
              ]),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: totalAttendu > 0 ? (totalPercu / totalAttendu).clamp(0, 1) : 0,
                backgroundColor: AppTheme.navyLight,
                valueColor: const AlwaysStoppedAnimation(AppTheme.success),
                borderRadius: BorderRadius.circular(8),
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${totalAttendu > 0 ? ((totalPercu / totalAttendu) * 100).toStringAsFixed(0) : 0}% collecté',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Liste des périodes
          if (rows.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Aucune donnée pour cette période', style: TextStyle(color: AppTheme.textMuted)),
            ))
          else
            ...rows.reversed.map((r) => _buildPeriodeRow(r, devise, visible)),
        ],
      ),
    );
  }

  Widget _buildPeriodeRow(_PeriodeRow r, String devise, bool visible) {
    final statut = r.periode?.statut ?? StatutPeriodeLoyer.enAttente;
    final color = statut == StatutPeriodeLoyer.paye
        ? AppTheme.success
        : statut == StatutPeriodeLoyer.impaye
            ? AppTheme.danger
            : AppTheme.textMuted;
    final label = statut == StatutPeriodeLoyer.paye ? 'Payé' : statut == StatutPeriodeLoyer.impaye ? 'Impayé' : 'En attente';
    final icon = statut == StatutPeriodeLoyer.paye ? Icons.check_circle_rounded : statut == StatutPeriodeLoyer.impaye ? Icons.cancel_rounded : Icons.hourglass_empty_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
              if (r.periode?.datePaiement != null)
                Text('Payé le ${AppUtils.formatDate(r.periode!.datePaiement!)}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              visible ? AppUtils.formatMontant(r.periode?.montantPaye ?? r.montant, devise: devise) : '••••',
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ]),
        ],
      ),
    );
  }

  Widget _datePicker(String label, DateTime current, ValueChanged<DateTime> onChange) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: current,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDatePickerMode: DatePickerMode.year,
          builder: (c, child) => Theme(
            data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.gold, surface: AppTheme.navyMedium)),
            child: child!,
          ),
        );
        if (d != null) onChange(DateTime(d.year, d.month));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.navyCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.navyLight),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, color: AppTheme.gold, size: 14),
          const SizedBox(width: 8),
          Text('$label: ${_formatMois(current)}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _summaryCell(String label, double value, Color color, String devise, bool visible) {
    return Expanded(
      child: Column(children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          visible ? AppUtils.formatMontant(value, devise: devise) : '••••',
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ]),
    );
  }

  // ─── ACTIONS PIN-GATÉES ────────────────────────────────────────────────────
  Future<void> _confirmerEncaissement(BuildContext context, AssetProvider prov, AuthProvider auth, Loyer loyer) async {
    if (auth.user?.hasPinConfigured == true) {
      final ok = await PinDialog.show(context);
      if (!ok) return;
    }
    if (!context.mounted) return;
    await prov.marquerPeriodePaye(loyer.id, _currentMonth.month, _currentMonth.year);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Loyer encaissé avec succès ✓'),
        backgroundColor: AppTheme.success,
      ));
    }
  }

  Future<void> _marquerImpaye(BuildContext context, AssetProvider prov, AuthProvider auth, Loyer loyer) async {
    if (auth.user?.hasPinConfigured == true) {
      final ok = await PinDialog.show(context);
      if (!ok) return;
    }
    if (!context.mounted) return;
    await prov.marquerPeriodeImpaye(loyer.id, _currentMonth.month, _currentMonth.year);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Période marquée comme impayée'),
        backgroundColor: AppTheme.warning,
      ));
    }
  }

  Future<void> _resilierLocation(BuildContext context, AssetProvider prov, AuthProvider auth, Asset asset) async {
    // PIN
    if (auth.user?.hasPinConfigured == true) {
      final ok = await PinDialog.show(context);
      if (!ok) return;
    }
    if (!context.mounted) return;
    // Confirmation
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Résilier la location', style: TextStyle(color: AppTheme.danger)),
        content: Text(
          'Voulez-vous résilier la location de "${asset.nom}" ?\nL\'historique des encaissements sera conservé.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Résilier'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await prov.resilierLocation(asset.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location résiliée'),
          backgroundColor: AppTheme.info,
        ));
        Navigator.pop(context);
      }
    }
  }
}

// Helper DTO
class _PeriodeRow {
  final String label;
  final double montant;
  final EncaissementPeriode? periode;
  _PeriodeRow({required this.label, required this.montant, this.periode});
}
