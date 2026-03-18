import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';
import '../widgets/pin_dialog.dart';

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
  String _pays = 'Burkina Faso';
  String _devise = 'XOF';
  DateTime _dateAcq = DateTime.now();
  DateTime? _dateFinBail;

  // Spécificités
  late TextEditingController _gpsC, _superficieC, _caractC; // Immobilier
  late TextEditingController _marqueC, _modeleC, _anneeC, _couleurC, _puissanceC, _chassisC, _immatC; // Véhicule
  late TextEditingController _ibanC, _compteNomC; // Compte / Banque
  late TextEditingController _siretC; // Entreprise
  late TextEditingController _temoinC, _refContratC; // Dette/Créance
  DateTime? _dateEcheance;
  bool _verrouillerGps = false;

  Map<String, String> _documents = {};

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

      // Spécificités depuis `a.details`
      _gpsC = TextEditingController(text: a.details['gps'] ?? '');
      _superficieC = TextEditingController(text: a.details['superficie'] ?? '');
      _caractC = TextEditingController(text: a.details['caracteristiques'] ?? '');
      _verrouillerGps = a.details['verrouillageGps'] ?? false;
      
      _marqueC = TextEditingController(text: a.details['marque'] ?? '');
      _modeleC = TextEditingController(text: a.details['modele'] ?? '');
      _anneeC = TextEditingController(text: a.details['annee'] ?? '');
      _couleurC = TextEditingController(text: a.details['couleur'] ?? '');
      _puissanceC = TextEditingController(text: a.details['puissance'] ?? '');
      _chassisC = TextEditingController(text: a.details['chassis'] ?? '');
      _immatC = TextEditingController(text: a.details['immatriculation'] ?? '');
      
      _ibanC = TextEditingController(text: a.details['iban'] ?? '');
      _compteNomC = TextEditingController(text: a.details['nom_banque'] ?? '');
      
      _siretC = TextEditingController(text: a.details['siret'] ?? '');
      
      _temoinC = TextEditingController(text: a.details['temoin'] ?? '');
      _refContratC = TextEditingController(text: a.details['reference_contrat'] ?? '');
      _dateEcheance = a.details['dateEcheance'] != null ? DateTime.tryParse(a.details['dateEcheance']) : null;
    } else {
      _gpsC = TextEditingController(); _superficieC = TextEditingController(); _caractC = TextEditingController();
      _marqueC = TextEditingController(); _modeleC = TextEditingController(); _anneeC = TextEditingController();
      _couleurC = TextEditingController(); _puissanceC = TextEditingController(); _chassisC = TextEditingController(); _immatC = TextEditingController();
      _ibanC = TextEditingController(); _compteNomC = TextEditingController();
      _siretC = TextEditingController();
      _temoinC = TextEditingController(); _refContratC = TextEditingController();
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
    _gpsC.dispose(); _superficieC.dispose(); _caractC.dispose();
    _marqueC.dispose(); _modeleC.dispose(); _anneeC.dispose();
    _couleurC.dispose(); _puissanceC.dispose(); _chassisC.dispose(); _immatC.dispose();
    _ibanC.dispose(); _compteNomC.dispose();
    _siretC.dispose();
    _temoinC.dispose(); _refContratC.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String typeDate) async {
    DateTime initial;
    if (typeDate == 'finBail') initial = _dateFinBail ?? DateTime.now();
    else if (typeDate == 'echeance') initial = _dateEcheance ?? DateTime.now();
    else initial = _dateAcq;

    final d = await showDatePicker(
      context: context,
      initialDate: initial,
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
        if (typeDate == 'finBail') _dateFinBail = d;
        else if (typeDate == 'echeance') _dateEcheance = d;
        else _dateAcq = d;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AssetProvider>();
    final details = <String, dynamic>{};
    
    if (_type == AssetType.immobilier) {
      details['gps'] = _gpsC.text.trim();
      details['verrouillageGps'] = _verrouillerGps;
      details['superficie'] = _superficieC.text.trim();
      details['caracteristiques'] = _caractC.text.trim();
    } else if (_type == AssetType.vehicule) {
      details['marque'] = _marqueC.text.trim();
      details['modele'] = _modeleC.text.trim();
      details['annee'] = _anneeC.text.trim();
      details['couleur'] = _couleurC.text.trim();
      details['puissance'] = _puissanceC.text.trim();
      details['chassis'] = _chassisC.text.trim();
      details['immatriculation'] = _immatC.text.trim();
    } else if (_type == AssetType.compteBancaire) {
      details['iban'] = _ibanC.text.trim();
      details['nom_banque'] = _compteNomC.text.trim();
    } else if (_type == AssetType.investissement) {
      details['siret'] = _siretC.text.trim();
    } else if (_type == AssetType.creance || _type == AssetType.dette) {
      details['temoin'] = _temoinC.text.trim();
      details['reference_contrat'] = _refContratC.text.trim();
      if (_dateEcheance != null) details['dateEcheance'] = _dateEcheance!.toIso8601String();
    }

    // ─── VALIDATION UNICITÉ ───
    if (!_isEdit) {
      final isUnique = await provider.checkAssetUniqueness(_type, details);
      if (!isUnique && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Un actif avec ces mêmes identifiants uniques (GPS, VIN, IBAN, etc.) existe déjà. Impossible de créer un doublon.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
    }

    // ─── VALIDATION PIN ───
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.user?.hasPinConfigured == true) {
      final pinOk = await PinDialog.show(
        context,
        title: _isEdit ? 'Confirmer la modification' : 'Confirmer l\'ajout de l\'actif',
      );
      if (!pinOk || !mounted) return;
    }

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
      details: details,
      estLoue: _estLoue,
      loyerMensuel: _estLoue && _loyerC.text.isNotEmpty ? double.tryParse(_loyerC.text.replaceAll(',', '.')) : null,
      locataire: _estLoue && _locataireC.text.isNotEmpty ? _locataireC.text.trim() : null,
      dateFinBail: _dateFinBail,
    );
    
    if (_isEdit) {
      await provider.updateAsset(asset);
    } else {
      await provider.addAsset(asset, documents: _documents);
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
                _sectionTitle('Date d\'acquisition / Consentement'),
                const SizedBox(height: 12),
                _buildDateButton('acquisition'),
                const SizedBox(height: 20),
                if (_type == AssetType.immobilier || _type == AssetType.vehicule || _type == AssetType.creance || _type == AssetType.dette) ...[
                  _sectionTitle('Spécificités'),
                  const SizedBox(height: 12),
                  _buildSpecificFields(),
                  const SizedBox(height: 20),
                ],
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
                  _buildDateButton('finBail'),
                ],
                if (!_isEdit) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Documents justificatifs (Optionnels, mais utiles pour la certification)'),
                  const SizedBox(height: 12),
                  _buildDocumentUploader(),
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

  Widget _buildDateButton(String typeDate) {
    DateTime? date;
    String prefix = '';
    String emptyText = '';
    
    if (typeDate == 'finBail') {
      date = _dateFinBail;
      prefix = 'Fin du bail : ';
      emptyText = 'Sélectionner fin du bail';
    } else if (typeDate == 'echeance') {
      date = _dateEcheance;
      prefix = 'Échéance : ';
      emptyText = 'Sélectionner l\'échéance';
    } else {
      date = _dateAcq;
      prefix = _type == AssetType.creance || _type == AssetType.dette ? 'Date de consentement : ' : 'Date d\'acquisition : ';
      emptyText = 'Date d\'acquisition';
    }

    return GestureDetector(
      onTap: () => _pickDate(typeDate),
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
                date != null ? '$prefix${AppUtils.formatDate(date)}' : emptyText,
                style: TextStyle(color: date != null ? AppTheme.textPrimary : AppTheme.textMuted, fontSize: 14),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificFields() {
    if (_type == AssetType.immobilier) {
      return Column(
        children: [
          _field(_superficieC, 'Superficie (m²)', Icons.square_foot_rounded, type: TextInputType.number),
          const SizedBox(height: 12),
          _field(_gpsC, 'Coordonnées GPS', Icons.pin_drop_rounded, hint: 'ex: 12.3456, -1.2345'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppTheme.textMuted, size: 16),
              const SizedBox(width: 8),
              const Expanded(child: Text('Verrouiller la position (signaler si occupé)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
              Switch(value: _verrouillerGps, onChanged: (v) => setState(() => _verrouillerGps = v), activeThumbColor: AppTheme.gold),
            ],
          ),
          const SizedBox(height: 12),
          _field(_caractC, 'Caractéristiques (ex: 4 pièces, piscine...)', Icons.list_alt_rounded, maxLines: 2),
        ],
      );
    } else if (_type == AssetType.vehicule) {
      return Column(
        children: [
          Row(children: [
            Expanded(child: _field(_marqueC, 'Marque', Icons.directions_car_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _field(_modeleC, 'Modèle', Icons.settings_rounded)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(_chassisC, 'Numéro de Châssis (VIN)', Icons.tag_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _field(_immatC, 'Plaque immatriculation', Icons.pin_rounded)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(_anneeC, 'Année', Icons.calendar_month_rounded, type: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field(_couleurC, 'Couleur', Icons.color_lens_rounded)),
          ]),
          const SizedBox(height: 12),
          _field(_puissanceC, 'Puissance (CV)', Icons.flash_on_rounded, type: TextInputType.number),
        ],
      );
    } else if (_type == AssetType.compteBancaire) {
      return Column(
        children: [
          _field(_compteNomC, 'Nom de la banque', Icons.account_balance_rounded),
          const SizedBox(height: 12),
          _field(_ibanC, 'IBAN', Icons.credit_card_rounded),
        ],
      );
    } else if (_type == AssetType.investissement) {
      return Column(
        children: [
          _field(_siretC, 'Numéro SIREN/SIRET', Icons.business_rounded),
        ],
      );
    } else if (_type == AssetType.creance || _type == AssetType.dette) {
      return Column(
        children: [
          _field(_refContratC, 'Référence du contrat', Icons.description_rounded),
          const SizedBox(height: 12),
          _field(_temoinC, 'Références du témoin', Icons.person_search_rounded),
          const SizedBox(height: 12),
          _buildDateButton('echeance'),
        ],
      );
    }
    return const SizedBox();
  }

  String _getHintForType() {
    switch (_type) {
      case AssetType.immobilier: return 'ex: Villa Côte d\'Azur, Appartement Paris';
      case AssetType.vehicule: return 'ex: Mercedes Classe C, Toyota Camry';
      case AssetType.investissement: return 'ex: Actions Apple, Parts SCI';
      case AssetType.creance: return 'ex: Prêt à Jean Dupont';
      case AssetType.dette: return 'ex: Crédit immobilier, Prêt personnel';
      case AssetType.compteBancaire: return 'ex: Compte courant, Livret A';
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
      value: items.contains(value) ? value : null,
      dropdownColor: AppTheme.navyMedium,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
      items: items.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDocumentUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Documents attachés', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            TextButton.icon(
              onPressed: () {
                // Simuler sélection de document
                setState(() {
                  _documents['Document_${_documents.length + 1}'] = '/path/to/simulated/doc.pdf';
                });
              },
              icon: const Icon(Icons.upload_file_rounded, size: 16),
              label: const Text('Ajouter'),
            )
          ],
        ),
        if (_documents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Aucun document joint. Ils aideront à accélérer la certification plus tard.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
          ),
        ..._documents.keys.map((docName) => 
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.navyMedium, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file_rounded, color: AppTheme.success, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(docName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                GestureDetector(
                  onTap: () => setState(() => _documents.remove(docName)),
                  child: const Icon(Icons.close_rounded, color: AppTheme.error, size: 16),
                ),
              ],
            ),
          )
        ).toList(),
      ],
    );
  }
}
