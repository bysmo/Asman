import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';

class AddAssetScreen extends StatefulWidget {
  final Asset? assetToEdit;
  const AddAssetScreen({super.key, this.assetToEdit});
  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomC, _descC, _valeurC, _valeurInitC, _loyerC, _locataireC;
  AssetType _type = AssetType.immobilier;
  AssetStatus _statut = AssetStatus.actif;
  bool _estLoue = false;
  String _pays = 'France';
  String _devise = 'EUR';
  DateTime _dateAcq = DateTime.now();
  DateTime? _dateFinBail;

  bool get _isEdit => widget.assetToEdit != null;

  @override
  void initState() {
    super.initState();
    final a = widget.assetToEdit;
    _nomC = TextEditingController(text: a?.nom ?? '');
    _descC = TextEditingController(text: a?.description ?? '');
    _valeurC = TextEditingController(text: a?.valeurActuelle.toStringAsFixed(0) ?? '');
    _valeurInitC = TextEditingController(text: a?.valeurInitiale.toStringAsFixed(0) ?? '');
    _loyerC = TextEditingController(text: a?.loyerMensuel?.toStringAsFixed(0) ?? '');
    _locataireC = TextEditingController(text: a?.locataire ?? '');
    if (a != null) {
      _type = a.type;
      _statut = a.statut;
      _estLoue = a.estLoue;
      _pays = a.pays;
      _devise = a.devise;
      _dateAcq = a.dateAcquisition;
      _dateFinBail = a.dateFinBail;
    } else {
      final userDevise = Provider.of<AuthProvider>(context, listen: false).user?.devise ?? 'EUR';
      final userPays = Provider.of<AuthProvider>(context, listen: false).user?.pays ?? 'France';
      _devise = userDevise;
      _pays = userPays;
    }
  }

  @override
  void dispose() {
    _nomC.dispose(); _descC.dispose(); _valeurC.dispose();
    _valeurInitC.dispose(); _loyerC.dispose(); _locataireC.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFinBail) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isFinBail ? (_dateFinBail ?? DateTime.now()) : _dateAcq,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.gold, surface: AppTheme.navyMedium),
        ),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() {
        if (isFinBail) { _dateFinBail = d; } else { _dateAcq = d; }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AssetProvider>();
    final asset = Asset(
      id: _isEdit ? widget.assetToEdit!.id : provider.generateId(),
      nom: _nomC.text.trim(),
      type: _type,
      statut: _estLoue ? AssetStatus.loue : _statut,
      valeurActuelle: double.parse(_valeurC.text.replaceAll(',', '.')),
      valeurInitiale: double.parse(_valeurInitC.text.replaceAll(',', '.')),
      description: _descC.text.trim(),
      devise: _devise,
      pays: _pays,
      dateAcquisition: _dateAcq,
      estLoue: _estLoue,
      loyerMensuel: _estLoue && _loyerC.text.isNotEmpty ? double.tryParse(_loyerC.text.replaceAll(',', '.')) : null,
      locataire: _estLoue && _locataireC.text.isNotEmpty ? _locataireC.text.trim() : null,
      dateFinBail: _dateFinBail,
    );
    if (_isEdit) {
      await provider.updateAsset(asset);
    } else {
      await provider.addAsset(asset);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier l\'actif' : 'Nouvel actif'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Enregistrer', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Type d\'actif'),
                _buildTypeSelector(),
                const SizedBox(height: 20),
                _sectionTitle('Informations générales'),
                const SizedBox(height: 12),
                _field(_nomC, 'Nom de l\'actif', Icons.label_rounded,
                    hint: _getHintForType(), validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null),
                const SizedBox(height: 12),
                _field(_descC, 'Description (optionnel)', Icons.notes_rounded, maxLines: 2),
                const SizedBox(height: 20),
                _sectionTitle('Valeur & finances'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_valeurInitC, 'Valeur d\'acquisition', Icons.paid_rounded,
                      type: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_valeurC, 'Valeur actuelle', Icons.trending_up_rounded,
                      type: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _buildDropdown('Devise', _devise, AppUtils.devises, (v) => setState(() => _devise = v!))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown('Pays', _pays, AppUtils.pays, (v) => setState(() => _pays = v!))),
                ]),
                const SizedBox(height: 20),
                _sectionTitle('Date d\'acquisition'),
                const SizedBox(height: 12),
                _buildDateButton(false),
                const SizedBox(height: 20),
                _sectionTitle('Statut'),
                const SizedBox(height: 12),
                _buildStatutSelector(),
                const SizedBox(height: 16),
                // Location
                _buildLocationToggle(),
                if (_estLoue) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Informations de location'),
                  const SizedBox(height: 12),
                  _field(_loyerC, 'Loyer mensuel', Icons.payments_rounded, type: TextInputType.number),
                  const SizedBox(height: 12),
                  _field(_locataireC, 'Nom du locataire', Icons.person_rounded),
                  const SizedBox(height: 12),
                  _buildDateButton(true),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(_isEdit ? 'Mettre à jour' : 'Enregistrer l\'actif',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1));

  Widget _buildTypeSelector() {
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: AssetType.values.map((t) {
          final selected = _type == t;
          final color = AppUtils.getColorForType(t);
          return GestureDetector(
            onTap: () => setState(() => _type = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10, top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.2) : AppTheme.navyCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? color : AppTheme.navyLight, width: selected ? 2 : 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppUtils.getIconForType(t), color: selected ? color : AppTheme.textMuted, size: 20),
                  const SizedBox(height: 4),
                  Text(AppUtils.getLabelForType(t),
                      style: TextStyle(color: selected ? color : AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatutSelector() {
    return Wrap(
      spacing: 8,
      children: AssetStatus.values.where((s) => s != AssetStatus.loue).map((s) {
        final selected = _statut == s;
        final color = AppUtils.getColorForStatus(s);
        return GestureDetector(
          onTap: () => setState(() => _statut = s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.15) : AppTheme.navyCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? color : AppTheme.navyLight),
            ),
            child: Text(AppUtils.getLabelForStatus(s),
                style: TextStyle(color: selected ? color : AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _estLoue ? AppTheme.info.withValues(alpha: 0.4) : AppTheme.navyLight),
      ),
      child: Row(
        children: [
          Icon(Icons.vpn_key_rounded, color: _estLoue ? AppTheme.info : AppTheme.textMuted, size: 20),
          const SizedBox(width: 12),
          const Expanded(child: Text('Cet actif est loué', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15))),
          Switch(
            value: _estLoue,
            onChanged: (v) => setState(() => _estLoue = v),
            activeThumbColor: AppTheme.info,
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(bool isFinBail) {
    final date = isFinBail ? _dateFinBail : _dateAcq;
    return GestureDetector(
      onTap: () => _pickDate(isFinBail),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.navyMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.navyLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppTheme.gold, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isFinBail
                    ? (date != null ? 'Fin du bail : ${AppUtils.formatDate(date)}' : 'Sélectionner fin du bail')
                    : 'Date d\'acquisition : ${AppUtils.formatDate(date ?? DateTime.now())}',
                style: TextStyle(color: date != null ? AppTheme.textPrimary : AppTheme.textMuted, fontSize: 14),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  String _getHintForType() {
    switch (_type) {
      case AssetType.immobilier: return 'ex: Villa Côte d\'Azur, Appartement Paris';
      case AssetType.vehicule: return 'ex: Mercedes Classe C, Toyota Camry';
      case AssetType.investissement: return 'ex: Actions Apple, Parts SCI';
      case AssetType.creance: return 'ex: Prêt à Jean Dupont';
      case AssetType.autre: return 'ex: Œuvre d\'art, Montre de luxe';
    }
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {String? hint, TextInputType type = TextInputType.text, String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.gold, size: 20),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppTheme.navyMedium,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
      items: items.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }
}
