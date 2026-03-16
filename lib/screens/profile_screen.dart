import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/asset_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<AuthProvider, AssetProvider>(
        builder: (context, auth, assets, _) {
          final user = auth.user;
          final devise = user?.devise ?? 'EUR';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              _buildAvatar(user),
              const SizedBox(height: 24),
              _buildStats(assets, devise),
              const SizedBox(height: 24),
              _buildSection('Mon compte', [
                _settingsTile(Icons.person_rounded, 'Informations personnelles', 'Nom, prénom, téléphone', () {}),
                _settingsTile(Icons.public_rounded, 'Pays & devise', '${user?.pays ?? '-'} · ${user?.devise ?? '-'}', () {}),
                _settingsTile(Icons.lock_rounded, 'Changer le mot de passe', '', () {}),
              ]),
              const SizedBox(height: 16),
              _buildSection('Données', [
                _settingsTile(Icons.bar_chart_rounded, 'Rapport de patrimoine', 'Synthèse de vos actifs', () {}),
                _settingsTile(Icons.download_rounded, 'Exporter les données', 'Format JSON', () {}),
              ]),
              const SizedBox(height: 16),
              _buildSection('Application', [
                _settingsTile(Icons.info_outline_rounded, 'À propos', 'Asset Manager v1.0.0', () {}),
                _settingsTile(Icons.privacy_tip_outlined, 'Politique de confidentialité', '', () {}),
              ]),
              const SizedBox(height: 24),
              _buildLogoutButton(context, auth),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatar(user) {
    final initiales = user?.nomComplet.isNotEmpty == true
        ? user!.nomComplet.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'AM';
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [AppTheme.gold, AppTheme.goldMuted]),
            boxShadow: [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 20)],
          ),
          child: Center(
            child: Text(initiales, style: const TextStyle(color: AppTheme.navyDark, fontSize: 28, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        Text(user?.nomComplet.isNotEmpty == true ? user!.nomComplet : 'Utilisateur',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(user?.telephone ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
          ),
          child: Text(user?.pays ?? '', style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildStats(AssetProvider assets, String devise) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.navyMedium, AppTheme.navyCard], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.account_balance_rounded, color: AppTheme.gold, size: 16),
            const SizedBox(width: 8),
            const Text('Résumé du patrimoine', style: TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem('Patrimoine total', AppUtils.formatMontant(assets.patrimoineTotal, devise: devise), AppTheme.gold),
            Container(width: 1, height: 40, color: AppTheme.navyLight),
            _statItem('Nb. d\'actifs', '${assets.assets.length}', AppTheme.textPrimary),
            Container(width: 1, height: 40, color: AppTheme.navyLight),
            _statItem('Revenus/mois', AppUtils.formatMontant(assets.loyersMensuelsTotaux, devise: devise), AppTheme.success),
          ]),
          const SizedBox(height: 12),
          Container(height: 1, color: AppTheme.navyLight),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem('Immobilier', AppUtils.formatMontant(assets.totalImmobilier, devise: devise), AppTheme.colorImmobilier),
            _statItem('Véhicules', AppUtils.formatMontant(assets.totalVehicules, devise: devise), AppTheme.colorVehicule),
            _statItem('Investissements', AppUtils.formatMontant(assets.totalInvestissements, devise: devise), AppTheme.colorInvestissement),
          ]),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(14)),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.navyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.textSecondary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return GestureDetector(
      onTap: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.navyMedium,
            title: const Text('Déconnexion', style: TextStyle(color: AppTheme.textPrimary)),
            content: const Text('Voulez-vous vous déconnecter ?', style: TextStyle(color: AppTheme.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted))),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                child: const Text('Déconnexion'),
              ),
            ],
          ),
        );
    if (ok == true) {
        if (!context.mounted) return;
        await auth.logout();
        if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.danger, size: 20),
            SizedBox(width: 10),
            Text('Se déconnecter', style: TextStyle(color: AppTheme.danger, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
