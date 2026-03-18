import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telC = TextEditingController();
  final _emailC = TextEditingController();
  final _pwdC = TextEditingController();
  final _confirmC = TextEditingController();
  final _nomC = TextEditingController();
  final _prenomC = TextEditingController();
  bool _obscurePwd = true;
  bool _obscureConfirm = true;
  String _selectedPays = 'France';
  String _selectedDevise = 'EUR';

  @override
  void dispose() {
    _telC.dispose(); _emailC.dispose(); _pwdC.dispose();
    _confirmC.dispose(); _nomC.dispose(); _prenomC.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final otp = await auth.register(
      telephone: _telC.text.trim(),
      email: _emailC.text.trim(),
      password: _pwdC.text,
      nom: _nomC.text.trim(),
      prenom: _prenomC.text.trim(),
      pays: _selectedPays,
      devise: _selectedDevise,
    );
    if (!mounted) return;
    if (otp != null) {
      // Simulation : afficher l'OTP en SnackBar jusqu'à l'intégration backend
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📧 Email envoyé à ${_emailC.text.trim()}\n[Simulation] Code OTP : $otp'),
        backgroundColor: AppTheme.info,
        duration: const Duration(seconds: 12),
      ));
      Navigator.pushReplacementNamed(
        context,
        '/otp-verify',
        arguments: _emailC.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informations personnelles',
                        style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _buildField(_prenomC, 'Prénom', Icons.person_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField(_nomC, 'Nom', Icons.person_outline_rounded)),
                    ]),
                    const SizedBox(height: 16),
                    _buildField(_telC, 'Numéro de téléphone', Icons.phone_rounded,
                        hint: '+33 6 00 00 00 00', type: TextInputType.phone),
                    const SizedBox(height: 16),
                    const Text('Région & devise',
                        style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildDropdown('Pays', _selectedPays, AppUtils.pays, (v) => setState(() => _selectedPays = v!))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDropdown('Devise', _selectedDevise, AppUtils.devises, (v) => setState(() => _selectedDevise = v!))),
                    ]),
                    const SizedBox(height: 16),
                    const Text('Sécurité',
                        style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    _buildField(_emailC, 'Adresse email', Icons.email_rounded,
                        hint: 'example@email.com', type: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null),
                    const SizedBox(height: 12),
                    _buildPwdField(_pwdC, 'Mot de passe', _obscurePwd, () => setState(() => _obscurePwd = !_obscurePwd)),
                    const SizedBox(height: 12),
                    _buildPwdField(_confirmC, 'Confirmer le mot de passe', _obscureConfirm,
                        () => setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (v) => v != _pwdC.text ? 'Les mots de passe ne correspondent pas' : null),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text(
                            'Après inscription, un code de vérification sera envoyé à votre email. Puis, vous devrez configurer un code PIN à 4 chiffres distinct de votre mot de passe.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          )),
                        ],
                      ),
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(auth.error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: auth.isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.navyDark))
                            : const Text('Créer mon compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label, IconData icon,
      {String? hint, TextInputType type = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon, color: AppTheme.gold, size: 20)),
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Requis' : null,
      onChanged: (_) => context.read<AuthProvider>().clearError(),
    );
  }

  Widget _buildPwdField(TextEditingController c, String label, bool obscure, VoidCallback toggle, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.gold, size: 20),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: toggle),
      ),
      validator: validator ?? (v) { if (v == null || v.length < 6) return 'Minimum 6 caractères'; return null; },
      onChanged: (_) => context.read<AuthProvider>().clearError(),
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
