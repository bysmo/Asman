import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _annuel = false;

  static const Color _navy = Color(0xFF0D1B2A);
  static const Color _gold = Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadPlans();
      context.read<SubscriptionProvider>().loadCurrentSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Abonnements ASMAN', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading && prov.plans.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFB300)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ────────────────────────────────────────────
                _buildHeader(prov),
                const SizedBox(height: 24),

                // ─── Toggle mensuel / annuel ──────────────────────────
                _buildBillingToggle(),
                const SizedBox(height: 24),

                // ─── Plans ────────────────────────────────────────────
                ...prov.plans.map((plan) => _buildPlanCard(plan, prov)),

                const SizedBox(height: 24),
                _buildRevenueShareInfo(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(SubscriptionProvider prov) {
    final tier = prov.currentTier;
    final sub  = prov.currentSubscription;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gold.withValues(alpha: 0.2), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getTierIcon(tier), color: _gold, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Votre plan actuel',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                  Text(tier.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          if (sub != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: sub.daysRemaining / 30.0,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(_gold),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text('${sub.daysRemaining} jours restants · expire le ${_formatDate(sub.dateFin)}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Plan gratuit · Passez à Standard pour plus de fonctionnalités',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _annuel = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !_annuel ? _gold : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Mensuel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: !_annuel ? _navy : Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          )),
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _annuel = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _annuel ? _gold : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Annuel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _annuel ? _navy : Colors.white,
                          fontWeight: FontWeight.bold)),
                  if (!_annuel) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                      child: const Text('-17%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, SubscriptionProvider prov) {
    final isCurrentPlan = prov.currentTier == plan.slug;
    final isPopular = plan.isPopular;
    final price = _annuel ? plan.annualPrice : plan.monthlyPrice;
    final priceStr = price == 0 ? 'Gratuit' : '${_formatXOF(price)} XOF';
    final period = _annuel ? '/an' : '/mois';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isCurrentPlan
            ? plan.color.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentPlan ? plan.color : Colors.white.withValues(alpha: 0.1),
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // ─── En-tête du plan ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isPopular
                  ? LinearGradient(colors: [_gold.withValues(alpha: 0.3), _gold.withValues(alpha: 0.1)])
                  : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: plan.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(plan.icon, color: plan.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(plan.nom,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: _gold, borderRadius: BorderRadius.circular(8)),
                              child: const Text('POPULAIRE',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                            ),
                          ],
                        ],
                      ),
                      Text(plan.description,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(priceStr,
                        style: TextStyle(color: plan.color, fontSize: 18, fontWeight: FontWeight.bold)),
                    if (price > 0) Text(period, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // ─── Fonctionnalités ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                ...plan.features.take(5).map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: plan.color, size: 16),
                      const SizedBox(width: 10),
                      Expanded(child: Text(feature,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13))),
                    ],
                  ),
                )),
                if (plan.features.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('+${plan.features.length - 5} autres avantages',
                        style: TextStyle(color: plan.color, fontSize: 12)),
                  ),

                const SizedBox(height: 16),

                // ─── Bouton ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: isCurrentPlan
                      ? OutlinedButton(
                          onPressed: plan.slug == 'decouverte' ? null : () => _confirmCancel(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: plan.color,
                            side: BorderSide(color: plan.color),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(plan.slug == 'decouverte' ? 'Plan actuel' : 'Plan actuel · Résilier'),
                        )
                      : ElevatedButton(
                          onPressed: plan.slug == 'decouverte'
                              ? null
                              : () => _showPaymentDialog(context, plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: plan.color,
                            foregroundColor: plan.slug == 'elite' || plan.slug == 'premium' ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(plan.slug == 'decouverte' ? 'Gratuit' : 'Souscrire · $priceStr$period',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueShareInfo() {
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
              Icon(Icons.handshake, color: Color(0xFFFFB300)),
              SizedBox(width: 10),
              Text('Partage de revenus transparent',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          _revenueRow('Expert / Notaire / Avocat', '60–70%', Colors.green),
          _revenueRow('Plateforme Asman', '25–30%', const Color(0xFFFFB300)),
          _revenueRow('Fonds de garantie', '5%', Colors.blue),
          const Divider(color: Colors.white24, height: 24),
          Text('Chaque service facturé (expertise, certification, testament) est partagé équitablement entre le professionnel et la plateforme.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _revenueRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13))),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext ctx, SubscriptionPlan plan) {
    String selectedPayment = 'mobile_money';
    final refController = TextEditingController();

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dCtx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2C3D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(plan.icon, color: plan.color),
              const SizedBox(width: 10),
              Text('Souscrire — ${plan.nom}', style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _annuel ? plan.annualPriceDisplay : plan.priceDisplay,
                style: TextStyle(color: plan.color, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Mode de paiement', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              ...[
                ('mobile_money', Icons.phone_android, 'Orange Money / Moov Money'),
                ('carte',        Icons.credit_card,   'Carte bancaire'),
                ('virement',     Icons.account_balance, 'Virement bancaire'),
              ].map((method) => RadioListTile<String>(
                title: Row(children: [
                  Icon(method.$2, size: 18, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(method.$3, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ]),
                value: method.$1,
                groupValue: selectedPayment,
                onChanged: (v) => setDialogState(() => selectedPayment = v!),
                activeColor: plan.color,
                contentPadding: EdgeInsets.zero,
              )),
              const SizedBox(height: 8),
              TextField(
                controller: refController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Référence de paiement',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: plan.color),
              onPressed: () async {
                if (refController.text.trim().isEmpty) return;
                Navigator.pop(dialogCtx);
                final prov = ctx.read<SubscriptionProvider>();
                final ok = await prov.subscribe(
                  planSlug:      plan.slug,
                  billingPeriod: _annuel ? 'annuel' : 'mensuel',
                  paymentMethod: selectedPayment,
                  paymentRef:    refController.text.trim(),
                );
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(ok ? 'Abonnement ${plan.nom} activé !' : prov.error ?? 'Erreur'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ));
                }
              },
              child: const Text('Confirmer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2C3D),
        title: const Text('Résilier l\'abonnement ?', style: TextStyle(color: Colors.white)),
        content: const Text('Vous passerez au plan Découverte à l\'expiration.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Non', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ctx.read<SubscriptionProvider>().cancelSubscription();
            },
            child: const Text('Résilier'),
          ),
        ],
      ),
    );
  }

  IconData _getTierIcon(String tier) {
    return switch (tier) {
      'standard' => Icons.star_border,
      'premium'  => Icons.star,
      'elite'    => Icons.diamond,
      'family'   => Icons.family_restroom,
      _          => Icons.explore,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatXOF(int amount) {
    final str = amount.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write(' ');
      result.write(str[i]);
    }
    return result.toString();
  }
}
