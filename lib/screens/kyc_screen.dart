import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _dateNaissance;
  String _typePieceIdentite = 'CNI';
  final _numeroPieceC = TextEditingController();
  final _fonctionC = TextEditingController();
  final _adresseResidenceC = TextEditingController();
  final _nationaliteC = TextEditingController();
  final _nomCompletPereC = TextEditingController();
  final _nomCompletMereC = TextEditingController();

  String? _rectoPath;
  String? _versoPath;
  String? _selfiePath;

  bool _isSubmitting = false;

  final List<String> _typesPieces = ['CNI', 'Passeport', 'Carte consulaire', 'Permis de conduire', 'Autre'];

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.gold,
            surface: AppTheme.navyMedium,
            onPrimary: AppTheme.navyDark,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _dateNaissance = d);
  }

  Future<void> _pickDocument(bool isRecto) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      setState(() {
        if (isRecto) {
          _rectoPath = result.files.single.path;
        } else {
          _versoPath = result.files.single.path;
        }
      });
    }
  }

  Future<void> _takeSelfie() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _selfiePath = picked.path;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_dateNaissance == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner votre date de naissance')));
      return;
    }
    if (_rectoPath == null || _versoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez fournir le recto et le verso de votre pièce d\'identité')));
      return;
    }
    if (_selfiePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez prendre un selfie pour vérifier votre identité')));
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.submitKyc(
      dateNaissance: _dateNaissance!,
      typePieceIdentite: _typePieceIdentite,
      numeroPiece: _numeroPieceC.text.trim(),
      documentIdentiteRecto: _rectoPath!,
      documentIdentiteVerso: _versoPath!,
      selfie: _selfiePath!,
      fonction: _fonctionC.text.trim(),
      adresseResidence: _adresseResidenceC.text.trim(),
      nationalite: _nationaliteC.text.trim(),
      nomCompletPere: _nomCompletPereC.text.trim(),
      nomCompletMere: _nomCompletMereC.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Informations KYC soumises avec succès. En attente de validation.'),
        backgroundColor: AppTheme.success,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Une erreur est survenue'),
        backgroundColor: AppTheme.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        title: const Text('Vérification d\'identité (KYC)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
        backgroundColor: AppTheme.navyMedium,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _isSubmitting 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Informations personnelles'),
                  const SizedBox(height: 12),
                  _buildDateSelector(),
                  const SizedBox(height: 16),
                  _buildDropdown('Type de pièce', _typePieceIdentite, _typesPieces, (v) => setState(() => _typePieceIdentite = v!)),
                  const SizedBox(height: 16),
                  _buildTextField(_numeroPieceC, 'Numéro de la pièce', Icons.badge_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_fonctionC, 'Fonction / Profession', Icons.work_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_adresseResidenceC, 'Adresse de résidence', Icons.home_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_nationaliteC, 'Nationalité', Icons.flag_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_nomCompletPereC, 'Nom complet du père', Icons.person_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_nomCompletMereC, 'Nom complet de la mère', Icons.person_rounded),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Documents justificatifs'),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(child: _buildDocumentPicker('Document Recto', _rectoPath, () => _pickDocument(true))),
                      const SizedBox(width: 10),
                      Expanded(child: _buildDocumentPicker('Document Verso', _versoPath, () => _pickDocument(false))),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSelfiePicker(),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.verified_user_rounded, size: 20),
                      label: const Text('Soumettre à vérification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.navyCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.navyLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_rounded, color: AppTheme.gold, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _dateNaissance == null ? 'Date de naissance' : AppUtils.formatDate(_dateNaissance!),
                style: TextStyle(
                  color: _dateNaissance == null ? AppTheme.textMuted : AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_rounded, color: AppTheme.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.gold, size: 20),
        filled: true,
        fillColor: AppTheme.navyCard,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.navyLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.danger)),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Ce champ est requis' : null,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppTheme.navyMedium,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.gold, size: 20),
        filled: true,
        fillColor: AppTheme.navyCard,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.navyLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold)),
      ),
      items: items.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDocumentPicker(String title, String? path, VoidCallback onTap) {
    final hasFile = path != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: hasFile ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasFile ? AppTheme.success : AppTheme.navyLight, width: hasFile ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFile ? Icons.check_circle_rounded : Icons.file_upload_outlined,
              color: hasFile ? AppTheme.success : AppTheme.textMuted,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              hasFile ? 'Ajouté' : title,
              style: TextStyle(
                color: hasFile ? AppTheme.success : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: hasFile ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (hasFile && path.split('.').last.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                path.split('/').last,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSelfiePicker() {
    final hasFile = _selfiePath != null;
    return GestureDetector(
      onTap: _takeSelfie,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: hasFile ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasFile ? AppTheme.success : AppTheme.navyLight, width: hasFile ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(
              hasFile ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
              color: hasFile ? AppTheme.success : AppTheme.textMuted,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              hasFile ? 'Selfie capturé avec succès' : 'Prendre un selfie',
              style: TextStyle(
                color: hasFile ? AppTheme.success : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: hasFile ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Capturez votre visage pour vérifier votre identité',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
