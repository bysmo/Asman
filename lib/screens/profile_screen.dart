import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/asset_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';
import 'kyc_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late TextEditingController _nomC, _prenomC;
  String? _selectedPays;
  String? _selectedDevise;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nomC = TextEditingController(text: user?.nom ?? '');
    _prenomC = TextEditingController(text: user?.prenom ?? '');
    _selectedPays = user?.pays ?? 'Burkina Faso';
    _selectedDevise = user?.devise ?? 'XOF';
  }

  @override
  void dispose() {
    _nomC.dispose();
    _prenomC.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    await auth.updateProfile(
      nom: _nomC.text.trim(),
      prenom: _prenomC.text.trim(),
      pays: _selectedPays!,
      devise: _selectedDevise!,
    );
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<AuthProvider, AssetProvider>(
        builder: (context, auth, assets, _) {
          final user = auth.user;
          final devise = user?.devise ?? 'XOF';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              _buildAvatar(user),
              const SizedBox(height: 20),
              // Email & PIN status
              _buildSecurityBadges(user),
              const SizedBox(height: 20),
              _buildStats(assets, devise),
              const SizedBox(height: 24),
              _buildSection('Mon compte', [
                _settingsTile(
                  Icons.person_rounded,
                  'Informations personnelles',
                  'Nom, prénom, pays, devise',
                  () => setState(() => _editing = !_editing),
                ),
                if (_editing) _buildEditForm(),
                _settingsTile(
                  Icons.pin_rounded,
                  'Modifier mon code PIN',
                  'Vérification par email requise',
                  () => Navigator.pushNamed(context, '/reset-pin'),
                ),
              ]),
              const SizedBox(height: 16),
              _buildSection('Vérification d\'identité', [
                _buildKycStatusTile(user),
              ]),
              const SizedBox(height: 16),
              _buildSection('Données', [
                _settingsTile(Icons.bar_chart_rounded, 'Rapport de patrimoine', 'Synthèse de vos actifs', () {}),
                _settingsTile(Icons.download_rounded, 'Exporter les données', 'Format JSON', () {}),
              ]),
              const SizedBox(height: 16),
              _buildSection('Application', [
                _settingsTile(Icons.info_outline_rounded, 'À propos', 'Asman v1.0.0', () {}),
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

  Widget _buildSecurityBadges(user) {
    return Row(
      children: [
        _badge(
          icon: user?.emailVerifie == true ? Icons.verified_rounded : Icons.mark_email_unread_rounded,
          label: user?.emailVerifie == true ? 'Email vérifié' : 'Email non vérifié',
          color: user?.emailVerifie == true ? AppTheme.success : AppTheme.warning,
        ),
        const SizedBox(width: 8),
        _badge(
          icon: user?.hasPinConfigured == true ? Icons.lock_rounded : Icons.lock_open_rounded,
          label: user?.hasPinConfigured == true ? 'PIN configuré' : 'PIN non configuré',
          color: user?.hasPinConfigured == true ? AppTheme.success : AppTheme.warning,
        ),
      ],
    );
  }

  Widget _badge({required IconData icon, required String label, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informations modifiables', style: TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _miniField(_prenomC, 'Prénom')),
            const SizedBox(width: 10),
            Expanded(child: _miniField(_nomC, 'Nom')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _miniDropdown('Pays', _selectedPays!, AppUtils.pays, (v) => setState(() => _selectedPays = v!))),
            const SizedBox(width: 10),
            Expanded(child: _miniDropdown('Devise', _selectedDevise!, AppUtils.devises, (v) => setState(() => _selectedDevise = v!))),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 14),
                SizedBox(width: 6),
                Expanded(child: Text(
                  'Email, téléphone, mot de passe et code PIN ne sont pas modifiables ici.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _editing = false),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textMuted, side: const BorderSide(color: AppTheme.navyLight)),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Enregistrer'),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _miniField(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true, fillColor: AppTheme.navyCard,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.navyLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.gold)),
      ),
    );
  }

  Widget _miniDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppTheme.navyMedium,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true, fillColor: AppTheme.navyCard,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.navyLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.gold)),
      ),
      items: items.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAvatar(user) {
    final initiales = user?.nomComplet.isNotEmpty == true
        ? user!.nomComplet.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'AM';
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [AppTheme.gold, AppTheme.goldMuted]),
            boxShadow: [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 20)],
          ),
          child: Center(child: Text(initiales, style: const TextStyle(color: AppTheme.navyDark, fontSize: 28, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 12),
        Text(user?.nomComplet.isNotEmpty == true ? user!.nomComplet : 'Utilisateur',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(user?.telephone ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        if (user?.email?.isNotEmpty == true) ...[
          const SizedBox(height: 2),
          Text(user!.email, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
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
                decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppTheme.textSecondary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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

  Widget _buildKycStatusTile(UserProfile? user) {
    if (user == null) return const SizedBox.shrink();
    
    IconData icon;
    String title;
    String subtitle;
    Color color;
    VoidCallback? onTap;

    switch (user.kycStatus) {
      case KycStatus.valide:
        icon = Icons.verified_user_rounded;
        title = 'Identité vérifiée';
        subtitle = 'Votre compte est certifié';
        color = AppTheme.success;
        onTap = null;
        break;
      case KycStatus.enAttente:
        icon = Icons.hourglass_top_rounded;
        title = 'Vérification en cours';
        subtitle = 'Vos documents sont en cours d\'analyse';
        color = AppTheme.warning;
        onTap = null;
        break;
      case KycStatus.rejete:
        icon = Icons.error_outline_rounded;
        title = 'Vérification rejetée';
        subtitle = 'Cliquez ici pour soumettre à nouveau';
        color = AppTheme.danger;
        onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
        break;
      default:
        icon = Icons.admin_panel_settings_rounded;
        title = 'Compléter la vérification (KYC)';
        subtitle = 'Requis pour certifier ou vendre des actifs';
        color = AppTheme.gold;
        onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(title),
            backgroundColor: color,
          ));
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: onTap != null ? AppTheme.textPrimary : color, fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              if (onTap != null)
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
