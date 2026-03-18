import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ResetPinScreen extends StatefulWidget {
  const ResetPinScreen({super.key});
  @override
  State<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  bool _otpVerified = false;
  bool _confirming = false;
  String? _error;
  bool _loading = false;

  String get _otpValue => _otpControllers.map((c) => c.text).join();
  List<String> get _activePin => _confirming ? _confirmPin : _pin;

  Future<void> _initOtp() async {
    final auth = context.read<AuthProvider>();
    final otp = await auth.requestPinReset();
    if (!mounted) return;
    if (otp != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Code OTP (simulation) : $otp'),
        backgroundColor: AppTheme.info,
        duration: const Duration(seconds: 10),
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initOtp());
  }

  Future<void> _verifyOtp() async {
    if (_otpValue.length < 6) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyResetOtp(_otpValue);
    if (!mounted) return;
    setState(() {
      if (ok) {
        _otpVerified = true;
      } else {
        _error = 'Code OTP invalide ou expiré.';
      }
    });
  }

  void _onDigit(String d) {
    if (_activePin.length >= 4) return;
    setState(() => _activePin.add(d));
    if (_activePin.length == 4) {
      if (!_confirming) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _confirming = true);
        });
      } else {
        _submit();
      }
    }
  }

  void _onDelete() {
    if (_activePin.isEmpty) return;
    setState(() => _activePin.removeLast());
  }

  Future<void> _submit() async {
    if (_pin.join() != _confirmPin.join()) {
      setState(() {
        _confirmPin.clear();
        _confirming = false;
        _error = 'Les codes PIN ne correspondent pas.';
      });
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPin(_otpValue, _pin.join());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code PIN mis à jour avec succès !'), backgroundColor: AppTheme.success),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _loading = false;
        _error = 'Erreur lors de la mise à jour du PIN.';
      });
    }
  }

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(title: const Text('Modifier le code PIN')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_otpVerified) ...[
                const Center(child: Icon(Icons.verified_user_rounded, color: AppTheme.gold, size: 56)),
                const SizedBox(height: 16),
                const Center(child: Text('Vérification email', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold))),
                const SizedBox(height: 8),
                const Center(child: Text('Saisissez le code envoyé à votre email.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) => Container(
                    width: 44, height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.navyCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.navyLight),
                    ),
                    child: TextField(
                      controller: _otpControllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 5) FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                        if (_otpValue.length == 6) _verifyOtp();
                      },
                    ),
                  )),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Center(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                ],
              ] else ...[
                // PIN entry after OTP verified
                Center(child: Text(_confirming ? 'Confirmez le nouveau PIN' : 'Saisissez le nouveau PIN',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold))),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _activePin.length ? AppTheme.gold : AppTheme.navyLight,
                      border: Border.all(color: AppTheme.gold, width: 2),
                    ),
                  )),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Center(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                ],
                const SizedBox(height: 24),
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                else
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: ['1','2','3','4','5','6','7','8','9','','0','⌫'].map((k) {
                      if (k.isEmpty) return const SizedBox();
                      if (k == '⌫') {
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _onDelete,
                          child: Container(
                            decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(12)),
                            child: const Center(child: Icon(Icons.backspace_outlined, color: AppTheme.textMuted, size: 22)),
                          ),
                        );
                      }
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _onDigit(k),
                        child: Container(
                          decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(k, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w600))),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
