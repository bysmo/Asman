import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';

class ConfirmationVieScreen extends StatelessWidget {
  const ConfirmationVieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        if (user == null) return const SizedBox.shrink();
        final statut = user.statutVie;

        final Color statutColor = switch (statut) {
          StatutVie.actif => AppTheme.success,
          StatutVie.confirmationRequise => AppTheme.warning,
          StatutVie.relance => AppTheme.error,
          StatutVie.presumeDecede => Colors.red.shade900,
        };
        final String statutLabel = switch (statut) {
          StatutVie.actif => 'Vie Confirmée ✓',
          StatutVie.confirmationRequise => 'Confirmation Requise',
          StatutVie.relance => 'Relances en cours',
          StatutVie.presumeDecede => 'Présumé décédé',
        };
        final IconData statutIcon = switch (statut) {
          StatutVie.actif => Icons.favorite_rounded,
          StatutVie.confirmationRequise => Icons.notification_important_rounded,
          StatutVie.relance => Icons.warning_rounded,
          StatutVie.presumeDecede => Icons.remove_circle_rounded,
        };

        return Scaffold(
          backgroundColor: AppTheme.navyDark,
          appBar: AppBar(
            backgroundColor: AppTheme.navyMedium,
            title: const Text('Confirmation de Vie', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: AppTheme.gold),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statut principal
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statutColor.withValues(alpha: 0.2), AppTheme.navyCard],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statutColor.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: statutColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: Icon(statutIcon, color: statutColor, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(statutLabel, style: TextStyle(color: statutColor, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        _statutDescription(statut, user),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dates
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _infoRow(Icons.check_circle_rounded, 'Dernière confirmation',
                          user.derniereConfirmationVie != null ? AppUtils.formatDate(user.derniereConfirmationVie!) : 'Jamais confirmé',
                          AppTheme.success),
                      const Divider(color: AppTheme.navyLight),
                      _infoRow(Icons.schedule_rounded, 'Prochain envoi prévu',
                          user.prochainEnvoiConfirmation != null ? AppUtils.formatDate(user.prochainEnvoiConfirmation!) : 'Trimestriel (90 jours)',
                          AppTheme.gold),
                      if (user.nombreRelancesEnvoyees > 0) ...[ 
                        const Divider(color: AppTheme.navyLight),
                        _infoRow(Icons.repeat_rounded, 'Relances envoyées',
                            '${user.nombreRelancesEnvoyees} / 4', AppTheme.error),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // EXPLICATION
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.info_rounded, color: AppTheme.info, size: 16),
                        SizedBox(width: 8),
                        Text('Comment ça fonctionne ?', style: TextStyle(color: AppTheme.info, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 10),
                      _stepItem('1', 'Un email + SMS vous est envoyé chaque trimestre', AppTheme.info),
                      _stepItem('2', 'Cliquez sur le lien reçu et confirmez votre code PIN', AppTheme.gold),
                      _stepItem('3', 'Sans réponse après 7 jours, une relance est envoyée (max 4 relances)', AppTheme.warning),
                      _stepItem('4', 'Sans réponse pendant 1 mois de relances, la procédure de liquidation est déclenchée automatiquement', AppTheme.error),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton principal : Confirmer ma vie
                if (statut != StatutVie.presumeDecede) ...[ 
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showConfirmationDialog(context, auth),
                      icon: const Icon(Icons.favorite_rounded),
                      label: const Text('Je suis en vie — Confirmer avec mon PIN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: AppTheme.navyDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Section de simulation (dev/test)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.navyCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.navyLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚙️ Simulation (Tests)', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('Simuler les différentes étapes du cycle de vie', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _simBtn('Confirmation requise', AppTheme.warning, () => auth.simulerStatutVie(StatutVie.confirmationRequise)),
                        _simBtn('Relance', AppTheme.error, () => auth.simulerStatutVie(StatutVie.relance)),
                        _simBtn('Présumé décédé', Colors.red.shade900, () => _showLiquidationDialog(context, auth)),
                        _simBtn('Réinitialiser', AppTheme.success, () => auth.confirmerVie('')),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statutDescription(StatutVie s, UserProfile user) {
    switch (s) {
      case StatutVie.actif:
        return 'Votre vie est confirmée. Un prochain envoi de confirmation de vie sera fait dans environ 90 jours.';
      case StatutVie.confirmationRequise:
        return 'Un email et SMS de confirmation de vie ont été envoyés. Veuillez confirmer votre vie en cliquant sur le bouton ci-dessous.';
      case StatutVie.relance:
        return 'Vous n\'avez pas répondu à notre invitation. Des relances ont été envoyées (${user.nombreRelancesEnvoyees}/4). Confirmez votre vie immédiatement.';
      case StatutVie.presumeDecede:
        return 'Aucune réponse après les relances. La procédure de liquidation a été déclenchée et vos ayants-droits ont été notifiés.';
    }
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text('$label : ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          Expanded(child: Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _stepItem(String num, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20, height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Center(child: Text(num, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _simBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, AuthProvider auth) {
    final pinC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Row(children: [
          Icon(Icons.favorite_rounded, color: AppTheme.success, size: 20),
          SizedBox(width: 8),
          Text('Confirmation de vie', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez votre code PIN pour confirmer que vous êtes en vie.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: pinC,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textPrimary, letterSpacing: 8, fontSize: 22),
              decoration: InputDecoration(
                hintText: '• • • •',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                counterText: '',
                filled: true,
                fillColor: AppTheme.navyCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.gold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () async {
              final result = await auth.confirmerVie(pinC.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Vie confirmée avec succès ! Merci.'), backgroundColor: AppTheme.success),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN incorrect. Veuillez réessayer.'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showLiquidationDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: const Row(children: [
          Icon(Icons.warning_rounded, color: Colors.red, size: 22),
          SizedBox(width: 8),
          Expanded(child: Text('Procédure de Liquidation', style: TextStyle(color: Colors.red, fontSize: 15))),
        ]),
        content: const Text(
          'Cette simulation va déclencher la procédure de liquidation automatique.\n\n'
          '• Le statut passera à "Présumé décédé"\n'
          '• Les notaires désignés seront notifiés\n'
          '• Les ayants-droits et personnes ressources seront alertés\n'
          '• L\'exécution du testament sera demandée',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.declencherLiquidation();
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppTheme.navyMedium,
                    title: const Text('📢 Notifications Envoyées', style: TextStyle(color: AppTheme.textPrimary)),
                    content: const Text(
                      '✅ Email envoyé aux notaires désignés\n'
                      '✅ SMS envoyé à tous les ayants-droits\n'
                      '✅ Alerte envoyée aux personnes ressources\n'
                      '✅ Demande d\'exécution du testament transmise\n'
                      '✅ Rapport de liquidation généré',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: AppTheme.gold)))],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Simuler la liquidation'),
          ),
        ],
      ),
    );
  }
}
