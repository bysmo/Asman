import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';

class AsmanScoreScreen extends StatefulWidget {
  const AsmanScoreScreen({super.key});

  @override
  State<AsmanScoreScreen> createState() => _AsmanScoreScreenState();
}

class _AsmanScoreScreenState extends State<AsmanScoreScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scoreAnim;

  static const Color _navy = Color(0xFF0D1B2A);
  static const Color _gold = Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<SubscriptionProvider>();
      // Vérifier si l'accès est disponible
      if (!['standard', 'premium', 'elite', 'family'].contains(prov.currentTier)) return;
      await prov.loadAsmanScore();
      if (prov.asmanScore != null) {
        _scoreAnim = Tween<double>(begin: 0, end: prov.asmanScore!.progressRatio)
            .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
        _animCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Asman Score', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _recalculer(context),
            tooltip: 'Recalculer',
          ),
        ],
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (ctx, prov, _) {
          // ─── Accès restreint ─────────────────────────────────────
          if (!['standard', 'premium', 'elite', 'family'].contains(prov.currentTier)) {
            return _buildUpgradePrompt(ctx);
          }

          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFB300)));
          }

          final score = prov.asmanScore;
          if (score == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('Score non encore calculé', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _recalculer(ctx),
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calculer mon score'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _gold, foregroundColor: Colors.black),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildScoreGauge(score),
                const SizedBox(height: 24),
                _buildDetailCards(score),
                const SizedBox(height: 24),
                _buildRecommandations(score),
                const SizedBox(height: 24),
                _buildNiveaux(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreGauge(AsmanScore score) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [score.color.withValues(alpha: 0.3), _navy],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: score.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text('${score.niveauEmoji} ${score.niveau}',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),

          // ─── Jauge circulaire ────────────────────────────────
          SizedBox(
            width: 180,
            height: 180,
            child: AnimatedBuilder(
              animation: _animCtrl.isAnimating ? _scoreAnim : AlwaysStoppedAnimation(score.progressRatio),
              builder: (_, __) {
                final progress = _animCtrl.isAnimating
                    ? _scoreAnim.value
                    : score.progressRatio;
                return CustomPaint(
                  painter: _ScoreGaugePainter(progress: progress, color: score.color),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          score.scoreTotal.toString(),
                          style: TextStyle(
                              color: score.color,
                              fontSize: 48,
                              fontWeight: FontWeight.bold),
                        ),
                        const Text('/1000', style: TextStyle(color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (score.updatedAt != null)
            Text(
              'Mis à jour le ${_formatDate(score.updatedAt!)}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailCards(AsmanScore score) {
    final modules = [
      {'label': 'Diversification', 'value': score.scoreDiversification, 'max': 300, 'icon': Icons.pie_chart},
      {'label': 'Certification',   'value': score.scoreCertification,   'max': 250, 'icon': Icons.verified},
      {'label': 'Liquidité',       'value': score.scoreLiquidite,       'max': 200, 'icon': Icons.water_drop},
      {'label': 'Documentation',   'value': score.scoreDocumentation,   'max': 150, 'icon': Icons.description},
      {'label': 'Régularité',      'value': score.scoreRegularite,      'max': 100, 'icon': Icons.calendar_today},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Détail par module',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...modules.map((m) => _ModuleBar(
          label: m['label'] as String,
          value: m['value'] as int,
          max:   m['max'] as int,
          icon:  m['icon'] as IconData,
        )),
      ],
    );
  }

  Widget _buildRecommandations(AsmanScore score) {
    if (score.recommandations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFFFFB300)),
              SizedBox(width: 10),
              Text('Recommandations pour progresser',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          ...score.recommandations.take(5).map((rec) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_right, color: Color(0xFFFFB300), size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(rec, style: const TextStyle(color: Colors.white70, fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNiveaux() {
    final niveaux = [
      {'nom': '🔰 Débutant',     'min': 0,    'max': 199,  'color': Colors.grey},
      {'nom': '🔷 Intermédiaire','min': 200,  'max': 399,  'color': Colors.blue},
      {'nom': '⭐ Confirmé',     'min': 400,  'max': 599,  'color': Colors.green},
      {'nom': '💎 Expert',       'min': 600,  'max': 799,  'color': _gold},
      {'nom': '👑 Patriarche',   'min': 800,  'max': 1000, 'color': const Color(0xFF7B1FA2)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Niveaux Asman Score',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...niveaux.map((n) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(n['nom'] as String,
                    style: TextStyle(color: n['color'] as Color, fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Text('${n['min']} – ${n['max']} pts',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt(BuildContext ctx) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.1),
                border: Border.all(color: _gold.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.analytics, size: 48, color: Color(0xFFFFB300)),
            ),
            const SizedBox(height: 24),
            const Text('Asman Score',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Mesurez la santé de votre patrimoine en temps réel. Obtenez des recommandations personnalisées pour maximiser la valeur de vos actifs.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _featureRow('Score sur 1 000 points', Icons.score),
                  _featureRow('5 modules d\'analyse détaillés', Icons.analytics),
                  _featureRow('Recommandations personnalisées', Icons.lightbulb),
                  _featureRow('Historique sur 12 mois', Icons.history),
                  _featureRow('Classement anonymisé', Icons.leaderboard),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(ctx, '/subscription'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Passer à Standard – 5 000 XOF/mois',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: _gold, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  void _recalculer(BuildContext ctx) async {
    final prov = ctx.read<SubscriptionProvider>();
    await prov.recalculateScore();
    if (prov.asmanScore != null) {
      _scoreAnim = Tween<double>(begin: 0, end: prov.asmanScore!.progressRatio)
          .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
      _animCtrl.forward(from: 0);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET : Barre de module
// ══════════════════════════════════════════════════════════════════════════════

class _ModuleBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final IconData icon;

  const _ModuleBar({required this.label, required this.value, required this.max, required this.icon});

  @override
  Widget build(BuildContext context) {
    final ratio = value / max;
    final color = ratio >= 0.7 ? Colors.green : ratio >= 0.4 ? const Color(0xFFFFB300) : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13))),
              Text('$value / $max',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER : Jauge circulaire
// ══════════════════════════════════════════════════════════════════════════════

class _ScoreGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ScoreGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const startAngle = 2.35619; // 135° en radians
    const sweepMax   = 4.71239; // 270° en radians

    // Fond de la jauge
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepMax, false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progression colorée
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepMax * progress, false,
        Paint()
          ..color = color
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreGaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
