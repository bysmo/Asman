import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';

class EvaluationScreen extends StatefulWidget {
  final Asset asset;
  const EvaluationScreen({super.key, required this.asset});
  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final _valeurC = TextEditingController();
  final _notesC = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _valeurC.text = widget.asset.valeurActuelle.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _valeurC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  double get _nouvelleValeur => double.tryParse(_valeurC.text.replaceAll(',', '.').replaceAll(' ', '')) ?? widget.asset.valeurActuelle;
  double get _variation => _nouvelleValeur - widget.asset.valeurActuelle;
  double get _variationPct => widget.asset.valeurActuelle > 0 ? (_variation / widget.asset.valeurActuelle) * 100 : 0;

  Future<void> _save() async {
    if (_valeurC.text.isEmpty) return;
    setState(() => _saving = true);
    await context.read<AssetProvider>().updateValeur(widget.asset.id, _nouvelleValeur);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Valeur mise à jour avec succès'),
        ]),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devise = context.read<AuthProvider>().user?.devise ?? widget.asset.devise;
    final color = AppUtils.getColorForType(widget.asset.type);

    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(title: const Text('Évaluation de l\'actif')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card actif
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.navyCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(AppUtils.getIconForType(widget.asset.type), color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.asset.nom, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(AppUtils.getLabelForType(widget.asset.type),
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Valeur actuelle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.navyCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _valCard('Coût d\'achat', AppUtils.formatMontant(widget.asset.valeurInitiale, devise: devise), AppTheme.textSecondary),
                      _valCard('Valeur actuelle', AppUtils.formatMontant(widget.asset.valeurActuelle, devise: devise), AppTheme.gold),
                      _valCard('Plus-value', AppUtils.formatMontant(widget.asset.plusValue, devise: devise),
                          widget.asset.plusValue >= 0 ? AppTheme.success : AppTheme.danger),
                    ]),
                    if (widget.asset.dateDerniereEvaluation != null) ...[
                      const SizedBox(height: 10),
                      Text('Dernière évaluation : ${AppUtils.formatDate(widget.asset.dateDerniereEvaluation!)}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('NOUVELLE VALEUR', style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valeurC,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(devise, style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              // Aperçu variation
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _variation >= 0 ? AppTheme.success.withValues(alpha: 0.08) : AppTheme.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _variation >= 0 ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Impact de l\'évaluation', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(_variation >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: _variation >= 0 ? AppTheme.success : AppTheme.danger, size: 16),
                        Text(AppUtils.formatMontant(_variation.abs(), devise: devise),
                            style: TextStyle(
                                color: _variation >= 0 ? AppTheme.success : AppTheme.danger,
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ]),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: (_variation >= 0 ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_variationPct >= 0 ? '+' : ''}${_variationPct.toStringAsFixed(2)}%',
                          style: TextStyle(
                              color: _variation >= 0 ? AppTheme.success : AppTheme.danger,
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesC,
                style: const TextStyle(color: AppTheme.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes sur l\'évaluation (optionnel)',
                  prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.gold, size: 20),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navyDark))
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(_saving ? 'Enregistrement...' : 'Confirmer l\'évaluation',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _valCard(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
