import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailC = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final otp = await auth.requestPasswordReset(_emailC.text.trim());
    if (!mounted) return;
    if (otp != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Code OTP (simulation) : $otp\nUn email sera envoyé lors de l\'intégration backend.'),
        backgroundColor: AppTheme.info,
        duration: const Duration(seconds: 10),
      ));
      Navigator.pushNamed(context, '/reset-password');
    }
  }

  @override
  void dispose() {
    _emailC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (ctx, auth, _) => Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Center(child: Icon(Icons.lock_reset_rounded, color: AppTheme.gold, size: 56)),
                  const SizedBox(height: 20),
                  const Center(child: Text('Réinitialiser votre mot de passe', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  const Center(child: Text('Saisissez votre adresse email pour recevoir un code de réinitialisation.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailC,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Adresse email',
                      prefixIcon: Icon(Icons.email_rounded, color: AppTheme.gold, size: 20),
                    ),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
                    onChanged: (_) => auth.clearError(),
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(auth.error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: auth.isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.navyDark))
                          : const Text('Envoyer le code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
