import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';

class CreancesDettesScreen extends StatefulWidget {
  const CreancesDettesScreen({super.key});
  @override
  State<CreancesDettesScreen> createState() => _CreancesDettesScreenState();
}

class _CreancesDettesScreenState extends State<CreancesDettesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

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

  @override
  Widget build(BuildContext context) {
    return Consumer2<AssetProvider, AuthProvider>(
      builder: (context, prov, auth, _) {
        final devise = auth.user?.devise ?? 'EUR';
        return SafeArea(
          child: Column(
            children: [
              _buildHeader(prov, devise),
              Container(
                color: AppTheme.navyMedium,
                child: TabBar(
                  controller: _tab,
                  indicatorColor: AppTheme.gold,
                  labelColor: AppTheme.gold,
                  unselectedLabelColor: AppTheme.textMuted,
                  tabs: [
                    Tab(icon: const Icon(Icons.arrow_circle_down_rounded, size: 18),
                        child: const Text('Créances', style: TextStyle(fontSize: 13))),
                    Tab(icon: const Icon(Icons.arrow_circle_up_rounded, size: 18),
                        child: const Text('Dettes', style: TextStyle(fontSize: 13))),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _buildCreancesList(context, prov, devise),
                    _buildDettesList(context, prov, devise),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AssetProvider prov, String devise) {
    final totalCreances = prov.totalCreancesEnCours;
    final totalDettes = prov.totalDettesEnCours;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: AppTheme.navyMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Créances & Dettes', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _summaryCard('À recevoir', totalCreances, devise, AppTheme.success, Icons.arrow_circle_down_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard('À rembourser', totalDettes, devise, AppTheme.danger, Icons.arrow_circle_up_rounded)),
          ]),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double amount, String devise, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          Text(AppUtils.formatMontant(amount, devise: devise),
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ])),
      ]),
    );
  }

  Widget _buildCreancesList(BuildContext context, AssetProvider prov, String devise) {
    final list = prov.creances;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ElevatedButton.icon(
              onPressed: () => _showAddCreanceDialog(context, prov, devise),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Nouvelle créance', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
            ),
          ]),
        ),
        Expanded(
          child: list.isEmpty
              ? _emptyState('Aucune créance enregistrée', 'Enregistrez les sommes que les autres vous doivent', Icons.arrow_circle_down_rounded, AppTheme.success)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _creanceTile(context, list[i], devise, prov),
                ),
        ),
      ],
    );
  }

  Widget _buildDettesList(BuildContext context, AssetProvider prov, String devise) {
    final list = prov.dettes;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ElevatedButton.icon(
              onPressed: () => _showAddDetteDialog(context, prov, devise),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Nouvelle dette', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                backgroundColor: AppTheme.danger,
              ),
            ),
          ]),
        ),
        Expanded(
          child: list.isEmpty
              ? _emptyState('Aucune dette enregistrée', 'Enregistrez les sommes que vous devez', Icons.arrow_circle_up_rounded, AppTheme.danger)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _detteTile(context, list[i], devise, prov),
                ),
        ),
      ],
    );
  }

  Widget _creanceTile(BuildContext context, Creance c, String devise, AssetProvider prov) {
    final retard = c.estEnRetard;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: retard ? AppTheme.danger.withValues(alpha: 0.4) : AppTheme.success.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_circle_down_rounded, color: AppTheme.success, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.debiteurNom, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            if (c.debiteurContact.isNotEmpty)
              Text(c.debiteurContact, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(AppUtils.formatMontant(c.montantRestant, devise: devise),
                style: const TextStyle(color: AppTheme.success, fontSize: 15, fontWeight: FontWeight.bold)),
            if (c.dateEcheance != null)
              Text(retard ? '⚠ En retard' : 'Échéance: ${AppUtils.formatDate(c.dateEcheance!)}',
                  style: TextStyle(color: retard ? AppTheme.danger : AppTheme.textMuted, fontSize: 10)),
          ]),
        ]),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: c.pourcentageRembourse / 100,
          backgroundColor: AppTheme.navyLight,
          valueColor: AlwaysStoppedAnimation<Color>(c.estRembourse ? AppTheme.success : AppTheme.gold),
          minHeight: 4,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${c.pourcentageRembourse.toStringAsFixed(0)}% remboursé · ${AppUtils.formatMontant(c.montantRembourse, devise: devise)} / ${AppUtils.formatMontant(c.montant, devise: devise)}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          if (!c.estRembourse)
            GestureDetector(
              onTap: () => _showRemboursement(context, prov, creanceId: c.id, max: c.montantRestant, devise: devise),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                ),
                child: const Text('+ Remboursement', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _detteTile(BuildContext context, Dette d, String devise, AssetProvider prov) {
    final retard = d.estEnRetard;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: retard ? AppTheme.danger.withValues(alpha: 0.5) : AppTheme.danger.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_circle_up_rounded, color: AppTheme.danger, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.creancierNom, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            if (d.creancierContact.isNotEmpty)
              Text(d.creancierContact, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(AppUtils.formatMontant(d.montantRestant, devise: devise),
                style: const TextStyle(color: AppTheme.danger, fontSize: 15, fontWeight: FontWeight.bold)),
            if (d.dateEcheance != null)
              Text(retard ? '⚠ En retard' : 'Échéance: ${AppUtils.formatDate(d.dateEcheance!)}',
                  style: TextStyle(color: retard ? AppTheme.danger : AppTheme.textMuted, fontSize: 10)),
          ]),
        ]),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: d.pourcentageRembourse / 100,
          backgroundColor: AppTheme.navyLight,
          valueColor: AlwaysStoppedAnimation<Color>(d.estRembourse ? AppTheme.success : AppTheme.danger),
          minHeight: 4,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${d.pourcentageRembourse.toStringAsFixed(0)}% remboursé',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          if (!d.estRembourse)
            GestureDetector(
              onTap: () => _showRemboursement(context, prov, detteId: d.id, max: d.montantRestant, devise: devise),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.info.withValues(alpha: 0.4)),
                ),
                child: const Text('+ Remboursement', style: TextStyle(color: AppTheme.info, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _emptyState(String title, String sub, IconData icon, Color color) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: AppTheme.textMuted, size: 56),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
      const SizedBox(height: 6),
      Text(sub, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12), textAlign: TextAlign.center),
    ]));
  }

  Future<void> _showAddCreanceDialog(BuildContext context, AssetProvider prov, String devise) async {
    final nomC = TextEditingController();
    final contactC = TextEditingController();
    final montantC = TextEditingController();
    final descC = TextEditingController();
    DateTime? echeance;

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
                const Icon(Icons.arrow_circle_down_rounded, color: AppTheme.success, size: 20),
                const SizedBox(width: 8),
                const Text('Nouvelle créance', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 4),
              const Text('Quelqu\'un vous doit de l\'argent', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              _tf2(nomC, 'Nom du débiteur', Icons.person_rounded),
              const SizedBox(height: 10),
              _tf2(contactC, 'Contact (optionnel)', Icons.phone_rounded),
              const SizedBox(height: 10),
              _tf2(montantC, 'Montant ($devise)', Icons.payments_rounded, type: TextInputType.number),
              const SizedBox(height: 10),
              _tf2(descC, 'Description', Icons.notes_rounded),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx2, initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(), lastDate: DateTime(2100),
                    builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.gold, surface: AppTheme.navyMedium)), child: child!),
                  );
                  if (d != null) setS(() => echeance = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(color: AppTheme.navyDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.navyLight)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.gold, size: 18),
                    const SizedBox(width: 10),
                    Text(echeance != null ? 'Échéance : ${AppUtils.formatDate(echeance!)}' : 'Définir une échéance (optionnel)',
                        style: TextStyle(color: echeance != null ? AppTheme.textPrimary : AppTheme.textMuted, fontSize: 14)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nomC.text.isEmpty || montantC.text.isEmpty) return;
                    await prov.addCreance(Creance(
                      id: prov.generateId(),
                      debiteurNom: nomC.text.trim(),
                      debiteurContact: contactC.text.trim(),
                      montant: double.tryParse(montantC.text.replaceAll(',', '.')) ?? 0,
                      devise: devise,
                      description: descC.text.trim(),
                      dateCreance: DateTime.now(),
                      dateEcheance: echeance,
                    ));
                    if (ctx2.mounted) Navigator.pop(ctx2);
                  },
                  child: const Text('Enregistrer la créance', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDetteDialog(BuildContext context, AssetProvider prov, String devise) async {
    final nomC = TextEditingController();
    final contactC = TextEditingController();
    final montantC = TextEditingController();
    final descC = TextEditingController();
    DateTime? echeance;

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
                const Icon(Icons.arrow_circle_up_rounded, color: AppTheme.danger, size: 20),
                const SizedBox(width: 8),
                const Text('Nouvelle dette', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 4),
              const Text('Vous devez de l\'argent à quelqu\'un', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              _tf2(nomC, 'Nom du créancier', Icons.person_rounded),
              const SizedBox(height: 10),
              _tf2(contactC, 'Contact (optionnel)', Icons.phone_rounded),
              const SizedBox(height: 10),
              _tf2(montantC, 'Montant ($devise)', Icons.payments_rounded, type: TextInputType.number),
              const SizedBox(height: 10),
              _tf2(descC, 'Description', Icons.notes_rounded),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx2, initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(), lastDate: DateTime(2100),
                    builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.gold, surface: AppTheme.navyMedium)), child: child!),
                  );
                  if (d != null) setS(() => echeance = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(color: AppTheme.navyDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.navyLight)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.gold, size: 18),
                    const SizedBox(width: 10),
                    Text(echeance != null ? 'Échéance : ${AppUtils.formatDate(echeance!)}' : 'Définir une échéance (optionnel)',
                        style: TextStyle(color: echeance != null ? AppTheme.textPrimary : AppTheme.textMuted, fontSize: 14)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nomC.text.isEmpty || montantC.text.isEmpty) return;
                    await prov.addDette(Dette(
                      id: prov.generateId(),
                      creancierNom: nomC.text.trim(),
                      creancierContact: contactC.text.trim(),
                      montant: double.tryParse(montantC.text.replaceAll(',', '.')) ?? 0,
                      devise: devise,
                      description: descC.text.trim(),
                      dateDette: DateTime.now(),
                      dateEcheance: echeance,
                    ));
                    if (ctx2.mounted) Navigator.pop(ctx2);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                  child: const Text('Enregistrer la dette', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _showRemboursement(BuildContext context, AssetProvider prov,
      {String? creanceId, String? detteId, required double max, required String devise}) async {
    final montantC = TextEditingController(text: max.toStringAsFixed(0));
    final notesC = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyMedium,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Icon(creanceId != null ? Icons.arrow_circle_down_rounded : Icons.arrow_circle_up_rounded,
                color: creanceId != null ? AppTheme.success : AppTheme.info, size: 20),
            const SizedBox(width: 8),
            Text('Enregistrer un remboursement',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          _tf2(montantC, 'Montant remboursé ($devise)', Icons.payments_rounded, type: TextInputType.number),
          const SizedBox(height: 10),
          _tf2(notesC, 'Notes (optionnel)', Icons.notes_rounded),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final montant = double.tryParse(montantC.text.replaceAll(',', '.')) ?? 0;
                if (montant <= 0) return;
                final r = RemboursementCreance(id: prov.generateId(), montant: montant, date: DateTime.now(), notes: notesC.text.trim());
                if (creanceId != null) await prov.ajouterRemboursementCreance(creanceId, r);
                if (detteId != null) await prov.ajouterRemboursementDette(detteId, r);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Confirmer le remboursement', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tf2(TextEditingController c, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c, keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.gold, size: 20)),
    );
  }
}
