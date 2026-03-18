import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Dialogue PIN réutilisable. Retourne true si le PIN est validé.
class PinDialog extends StatefulWidget {
  final String title;
  const PinDialog({super.key, this.title = 'Saisir votre code PIN'});

  static Future<bool> show(BuildContext context, {String title = 'Confirmer avec votre PIN'}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinDialog(title: title),
    );
    return result ?? false;
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final List<String> _digits = [];
  String? _error;
  bool _loading = false;

  void _onDigit(String d) {
    if (_digits.length >= 4) return;
    setState(() {
      _digits.add(d);
      _error = null;
    });
    if (_digits.length == 4) _validate();
  }

  void _onDelete() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  Future<void> _validate() async {
    setState(() => _loading = true);
    final pin = _digits.join();
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _digits.clear();
        _error = 'Code PIN incorrect. Réessayez.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.navyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, color: AppTheme.gold, size: 36),
            const SizedBox(height: 12),
            Text(widget.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _digits.length ? AppTheme.gold : AppTheme.navyLight,
                  border: Border.all(color: AppTheme.gold, width: 1.5),
                ),
              )),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            if (_loading)
              const CircularProgressIndicator(color: AppTheme.gold)
            else
              _buildKeypad(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
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
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox();
        if (k == '⌫') {
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _onDelete,
            child: Container(
              decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Icon(Icons.backspace_outlined, color: AppTheme.textMuted, size: 20)),
            ),
          );
        }
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _onDigit(k),
          child: Container(
            decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(k, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w600))),
          ),
        );
      }).toList(),
    );
  }
}
