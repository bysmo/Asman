import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AppUtils {
  static String formatMontant(double montant, {String devise = 'EUR'}) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: _getSymbole(devise),
      decimalDigits: 0,
    );
    return formatter.format(montant);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  static String formatDateCourt(DateTime date) {
    return DateFormat('MM/yyyy', 'fr_FR').format(date);
  }

  static String _getSymbole(String devise) {
    switch (devise) {
      case 'EUR': return '€';
      case 'USD': return '\$';
      case 'GBP': return '£';
      case 'XOF': return 'FCFA';
      case 'XAF': return 'FCFA';
      case 'MAD': return 'DH';
      case 'DZD': return 'DA';
      case 'TND': return 'TND';
      case 'EGP': return 'E£';
      case 'NGN': return '₦';
      case 'GHS': return 'GH₵';
      case 'KES': return 'KSh';
      case 'ZAR': return 'R';
      case 'CHF': return 'CHF';
      case 'CAD': return 'CA\$';
      default: return devise;
    }
  }

  static Color getColorForType(AssetType type) {
    switch (type) {
      case AssetType.immobilier: return AppTheme.colorImmobilier;
      case AssetType.vehicule: return AppTheme.colorVehicule;
      case AssetType.investissement: return AppTheme.colorInvestissement;
      case AssetType.creance: return AppTheme.colorCreance;
      case AssetType.dette: return AppTheme.error;
      case AssetType.compteBancaire: return AppTheme.gold;
      case AssetType.autre: return AppTheme.colorAutre;
    }
  }

  static IconData getIconForType(AssetType type) {
    switch (type) {
      case AssetType.immobilier: return Icons.home_rounded;
      case AssetType.vehicule: return Icons.directions_car_rounded;
      case AssetType.investissement: return Icons.trending_up_rounded;
      case AssetType.creance: return Icons.description_rounded;
      case AssetType.dette: return Icons.money_off_rounded;
      case AssetType.compteBancaire: return Icons.account_balance_rounded;
      case AssetType.autre: return Icons.category_rounded;
    }
  }

  static String getLabelForType(AssetType type) {
    switch (type) {
      case AssetType.immobilier: return 'Immobilier';
      case AssetType.vehicule: return 'Véhicule';
      case AssetType.investissement: return 'Investissement';
      case AssetType.creance: return 'Créance';
      case AssetType.dette: return 'Dette';
      case AssetType.compteBancaire: return 'Compte Bancaire';
      case AssetType.autre: return 'Autre';
    }
  }

  static String getLabelForStatus(AssetStatus status) {
    switch (status) {
      case AssetStatus.actif: return 'Actif';
      case AssetStatus.loue: return 'Loué';
      case AssetStatus.vendu: return 'Vendu';
      case AssetStatus.inactif: return 'Inactif';
    }
  }

  static Color getColorForStatus(AssetStatus status) {
    switch (status) {
      case AssetStatus.actif: return AppTheme.success;
      case AssetStatus.loue: return AppTheme.info;
      case AssetStatus.vendu: return AppTheme.textMuted;
      case AssetStatus.inactif: return AppTheme.warning;
    }
  }

  static List<String> get devises => [
    'EUR', 'USD', 'GBP', 'CHF', 'CAD',
    'XOF', 'XAF', 'MAD', 'DZD', 'TND',
    'EGP', 'NGN', 'GHS', 'KES', 'ZAR',
  ];

  static List<String> get pays => [
    'France', 'Belgique', 'Suisse', 'Canada', 'Luxembourg',
    'Maroc', 'Algérie', 'Tunisie', 'Sénégal', 'Côte d\'Ivoire',
    'Cameroun', 'Mali', 'Burkina Faso', 'Niger', 'Togo',
    'Bénin', 'Guinée', 'Congo', 'Gabon', 'Mauritanie',
    'Égypte', 'Nigeria', 'Ghana', 'Kenya', 'Afrique du Sud',
    'Autre',
  ];
}
