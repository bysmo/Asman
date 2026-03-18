import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});
  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  bool _confirming = false;
  String? _error;
  bool _loading = false;

  List<String> get _activeList => _confirming ? _confirmPin : _pin;

  void _onDigit(String d) {
    if (_activeList.length >= 4) return;
    setState(() {
      _activeList.add(d);
      _error = null;
    });
    if (_activeList.length == 4) {
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
    if (_activeList.isEmpty) return;
    setState(() => _activeList.removeLast());
  }

  Future<void> _submit() async {
    if (_pin.join() != _confirmPin.join()) {
      setState(() {
        _confirmPin.clear();
        _error = 'Les codes PIN ne correspondent pas. Réessayez.';
      });
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.setupPin(_pin.join());
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _loading = false;
        _error = auth.error ?? 'Erreur lors de la configuration du PIN.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _confirming ? 'Confirmez votre code PIN' : 'Créez votre code PIN';
    final activeList = _activeList;
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(title: const Text('Configuration du PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pin_rounded, color: AppTheme.gold, size: 48),
              ),
              const SizedBox(height: 24),
              Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Ce code sera utilisé pour valider les opérations dans l\'application.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < activeList.length ? AppTheme.gold : AppTheme.navyLight,
                    border: Border.all(color: AppTheme.gold, width: 2),
                  ),
                )),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 32),
              if (_loading)
                const CircularProgressIndicator(color: AppTheme.gold)
              else
                _buildKeypad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 1.8,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: keys.map((k) {
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
    );
  }
}
