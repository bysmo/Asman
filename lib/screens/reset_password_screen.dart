import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _pwdC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _obscurePwd = true;
  bool _obscureConfirm = true;
  bool _otpVerified = false;

  String get _otpValue => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otpValue.length < 6) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyResetOtp(_otpValue);
    if (!mounted) return;
    if (ok) {
      setState(() => _otpVerified = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code OTP invalide ou expiré.'), backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(_pwdC.text);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé avec succès !'), backgroundColor: AppTheme.success),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _pwdC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (ctx, auth, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text('Code de vérification', style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) => Container(
                    width: 44, height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.navyCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _otpVerified ? AppTheme.success : AppTheme.navyLight),
                    ),
                    child: TextField(
                      controller: _otpControllers[i],
                      focusNode: _focusNodes[i],
                      enabled: !_otpVerified,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                      style: TextStyle(color: _otpVerified ? AppTheme.success : AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 5) FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                        if (_otpValue.length == 6) _verifyOtp();
                      },
                    ),
                  )),
                ),
                if (!_otpVerified)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(child: Text('Saisissez le code reçu par email', style: TextStyle(color: AppTheme.textMuted, fontSize: 12))),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Center(child: Text('✓ Code vérifié', style: TextStyle(color: AppTheme.success, fontSize: 13))),
                  ),
                if (_otpVerified) ...[
                  const SizedBox(height: 28),
                  const Text('Nouveau mot de passe', style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _pwdC,
                          obscureText: _obscurePwd,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Nouveau mot de passe',
                            prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.gold, size: 20),
                            suffixIcon: IconButton(icon: Icon(_obscurePwd ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _obscurePwd = !_obscurePwd)),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmC,
                          obscureText: _obscureConfirm,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.gold, size: 20),
                            suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                          ),
                          validator: (v) => v != _pwdC.text ? 'Les mots de passe ne correspondent pas' : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: auth.isLoading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.navyDark))
                                : const Text('Réinitialiser', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
