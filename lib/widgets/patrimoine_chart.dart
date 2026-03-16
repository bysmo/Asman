import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/asset_provider.dart';
import '../theme/app_theme.dart';

class PatrimoineChart extends StatefulWidget {
  final AssetProvider assetProvider;
  const PatrimoineChart({super.key, required this.assetProvider});

  @override
  State<PatrimoineChart> createState() => _PatrimoineChartState();
}

class _PatrimoineChartState extends State<PatrimoineChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final data = _buildChartData();
    if (data.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.navyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Distribution du patrimoine',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (response == null || response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: data.asMap().entries.map((e) {
                      final i = e.key;
                      final d = e.value;
                      final isTouched = i == _touchedIndex;
                      return PieChartSectionData(
                        value: d['value'] as double,
                        color: d['color'] as Color,
                        radius: isTouched ? 58 : 50,
                        showTitle: false,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: data.map((d) => _buildLegendItem(d)).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Map<String, dynamic> d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: d['color'] as Color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(d['label'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
          Text('${(d['pct'] as double).toStringAsFixed(1)}%',
              style: TextStyle(color: d['color'] as Color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildChartData() {
    final ap = widget.assetProvider;
    final total = ap.patrimoineTotal;
    if (total == 0) return [];
    final cats = [
      {'label': 'Immobilier', 'value': ap.totalImmobilier, 'color': AppTheme.colorImmobilier},
      {'label': 'Véhicules', 'value': ap.totalVehicules, 'color': AppTheme.colorVehicule},
      {'label': 'Investissements', 'value': ap.totalInvestissements, 'color': AppTheme.colorInvestissement},
      {'label': 'Créances', 'value': ap.totalCreancesActifs, 'color': AppTheme.colorCreance},
      {'label': 'Autres', 'value': ap.totalAutres, 'color': AppTheme.colorAutre},
    ];
    return cats
        .where((c) => (c['value'] as double) > 0)
        .map((c) => {...c, 'pct': (c['value'] as double) / total * 100})
        .toList();
  }
}
