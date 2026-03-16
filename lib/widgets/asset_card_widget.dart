import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';

class AssetCardWidget extends StatelessWidget {
  final Asset asset;
  final String devise;
  final bool showDetails;

  const AssetCardWidget({
    super.key,
    required this.asset,
    required this.devise,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.getColorForType(asset.type);
    final plusValue = asset.plusValue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(AppUtils.getIconForType(asset.type), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.nom,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppUtils.getColorForStatus(asset.statut).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(AppUtils.getLabelForStatus(asset.statut),
                          style: TextStyle(color: AppUtils.getColorForStatus(asset.statut), fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    Text(asset.pays, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
                if (showDetails && asset.estLoue && asset.loyerMensuel != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.payments_rounded, color: AppTheme.success, size: 12),
                      const SizedBox(width: 4),
                      Text('${AppUtils.formatMontant(asset.loyerMensuel!, devise: devise)}/mois',
                          style: const TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppUtils.formatMontant(asset.valeurActuelle, devise: devise),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    plusValue >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: plusValue >= 0 ? AppTheme.success : AppTheme.danger,
                    size: 11,
                  ),
                  Text(
                    '${asset.plusValuePourcentage.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: plusValue >= 0 ? AppTheme.success : AppTheme.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
