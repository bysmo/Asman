import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';

class NotairesSelectionScreen extends StatefulWidget {
  const NotairesSelectionScreen({super.key});

  @override
  State<NotairesSelectionScreen> createState() => _NotairesSelectionScreenState();
}

class _NotairesSelectionScreenState extends State<NotairesSelectionScreen> {
  List<Notaire> _allNotaires = [];
  List<Notaire> _filtered = [];
  List<String> _selectedIds = [];
  String? _executeurId;
  bool _isLoading = true;
  bool _isSaving = false;
  final TextEditingController _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    final notaires = await DatabaseService().getAllNotaires();
    setState(() {
      _allNotaires = notaires;
      _filtered = notaires;
      _selectedIds = List.from(user?.notairesChoisisIds ?? []);
      _executeurId = user?.notaireExecuteurId;
      _isLoading = false;
    });
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _allNotaires.where((n) {
        return n.nom.toLowerCase().contains(q) ||
            n.prenom.toLowerCase().contains(q) ||
            n.ville.toLowerCase().contains(q) ||
            n.pays.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<AuthProvider>().saveNotairesChoisis(_selectedIds, _executeurId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vos notaires ont été enregistrés avec succès'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        backgroundColor: AppTheme.navyMedium,
        title: const Text('Mes Notaires Désignés', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppTheme.gold),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _selectedIds.isEmpty ? null : _save,
              child: Text('Enregistrer', style: TextStyle(color: _selectedIds.isEmpty ? AppTheme.textMuted : AppTheme.gold, fontWeight: FontWeight.bold)),
            ),
          if (_isSaving)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold)))),
        ],
      ),
      body: Column(
        children: [
          // Bandeau info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.gold, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Sélectionnez jusqu\'à 3 notaires habilités. Parmi eux, désignez celui qui sera l\'Exécuteur de votre Testament.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Compteur de sélection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_selectedIds.length} / 3 notaires sélectionnés',
                    style: TextStyle(color: _selectedIds.length == 3 ? AppTheme.gold : AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                if (_executeurId != null) ...[ 
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Exécuteur désigné', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchC,
              onChanged: _filter,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, ville, pays...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.navyCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) => _buildNotaireTile(_filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaireTile(Notaire n) {
    final isSelected = _selectedIds.contains(n.id);
    final isExecuteur = _executeurId == n.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.gold.withValues(alpha: 0.08) : AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExecuteur ? AppTheme.success.withValues(alpha: 0.6) :
                 isSelected ? AppTheme.gold.withValues(alpha: 0.4) : AppTheme.navyLight,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.gold.withValues(alpha: 0.2) : AppTheme.navyLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              n.nom.isNotEmpty ? n.nom[0] : '?',
              style: TextStyle(color: isSelected ? AppTheme.gold : AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(n.nomComplet, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
            if (isExecuteur)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: const Text('Exécuteur', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_rounded, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text('${n.ville}, ${n.pays}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ]),
            if (n.email.isNotEmpty) Row(children: [
              const Icon(Icons.email_rounded, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(n.email, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ]),
          ],
        ),
        trailing: isSelected
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.gold),
              color: AppTheme.navyMedium,
              onSelected: (v) {
                setState(() {
                  if (v == 'deselect') {
                    _selectedIds.remove(n.id);
                    if (_executeurId == n.id) _executeurId = null;
                  } else if (v == 'executeur') {
                    _executeurId = n.id;
                  }
                });
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'executeur', child: Row(children: [
                  Icon(Icons.gavel_rounded, color: AppTheme.gold, size: 16),
                  SizedBox(width: 8),
                  Text('Désigner Exécuteur', style: TextStyle(color: AppTheme.textPrimary)),
                ])),
                const PopupMenuItem(value: 'deselect', child: Row(children: [
                  Icon(Icons.remove_circle_outline_rounded, color: AppTheme.error, size: 16),
                  SizedBox(width: 8),
                  Text('Retirer', style: TextStyle(color: AppTheme.error)),
                ])),
              ],
            )
          : IconButton(
              icon: Icon(_selectedIds.length >= 3 ? Icons.block_rounded : Icons.add_circle_rounded,
                  color: _selectedIds.length >= 3 ? AppTheme.textMuted : AppTheme.gold),
              onPressed: _selectedIds.length >= 3 ? null : () {
                setState(() => _selectedIds.add(n.id));
              },
            ),
      ),
    );
  }
}
