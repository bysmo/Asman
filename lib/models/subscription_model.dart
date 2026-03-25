// ─────────────────────────────────────────────────────────────────────────────
// ASMAN — Modèles Business Model : Abonnements, Expertise, Asman Score
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SUBSCRIPTION PLAN
// ══════════════════════════════════════════════════════════════════════════════

class SubscriptionPlan {
  final int id;
  final String slug;
  final String nom;
  final String description;
  final int monthlyPrice;
  final int annualPrice;
  final List<String> features;
  final Map<String, dynamic> limits;
  final String badgeColor;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.slug,
    required this.nom,
    required this.description,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.features,
    required this.limits,
    required this.badgeColor,
    this.isPopular = false,
  });

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id:           map['id'] as int? ?? 0,
      slug:         map['slug'] as String? ?? '',
      nom:          map['nom'] as String? ?? '',
      description:  map['description'] as String? ?? '',
      monthlyPrice: map['monthly_price'] as int? ?? 0,
      annualPrice:  map['annual_price'] as int? ?? 0,
      features:     (map['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
      limits:       Map<String, dynamic>.from(map['limits'] as Map? ?? {}),
      badgeColor:   map['badge_color'] as String? ?? '#9E9E9E',
      isPopular:    map['is_popular'] as bool? ?? false,
    );
  }

  Color get color {
    try {
      final hex = badgeColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  String get priceDisplay {
    if (monthlyPrice == 0) return 'Gratuit';
    return '${_formatXOF(monthlyPrice)} XOF/mois';
  }

  String get annualPriceDisplay {
    if (annualPrice == 0) return 'Gratuit';
    return '${_formatXOF(annualPrice)} XOF/an';
  }

  static String _formatXOF(int amount) {
    final str = amount.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write(' ');
      result.write(str[i]);
    }
    return result.toString();
  }

  IconData get icon {
    return switch (slug) {
      'standard' => Icons.star_border,
      'premium'  => Icons.star,
      'elite'    => Icons.diamond,
      'family'   => Icons.family_restroom,
      _          => Icons.explore,
    };
  }

  int getLimit(String key, {int defaultValue = -1}) {
    return (limits[key] as int?) ?? defaultValue;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUBSCRIPTION (abonnement actif d'un utilisateur)
// ══════════════════════════════════════════════════════════════════════════════

class UserSubscription {
  final int id;
  final SubscriptionPlan plan;
  final String billingPeriod;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int montantPaye;
  final String statut;
  final bool autoRenew;
  final int daysRemaining;

  const UserSubscription({
    required this.id,
    required this.plan,
    required this.billingPeriod,
    required this.dateDebut,
    required this.dateFin,
    required this.montantPaye,
    required this.statut,
    required this.autoRenew,
    required this.daysRemaining,
  });

  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    return UserSubscription(
      id:             map['id'] as int? ?? 0,
      plan:           SubscriptionPlan.fromMap(map['plan'] as Map<String, dynamic>? ?? {}),
      billingPeriod:  map['billing_period'] as String? ?? 'mensuel',
      dateDebut:      DateTime.tryParse(map['date_debut'] as String? ?? '') ?? DateTime.now(),
      dateFin:        DateTime.tryParse(map['date_fin'] as String? ?? '') ?? DateTime.now(),
      montantPaye:    map['montant_paye'] as int? ?? 0,
      statut:         map['statut'] as String? ?? 'actif',
      autoRenew:      map['auto_renew'] as bool? ?? true,
      daysRemaining:  map['days_remaining'] as int? ?? 0,
    );
  }

  bool get isActive => statut == 'actif' && dateFin.isAfter(DateTime.now());
  bool get expiresSOon => daysRemaining <= 7 && isActive;
}

// ══════════════════════════════════════════════════════════════════════════════
// CABINET PROFESSIONNEL (notaire / huissier / avocat / expert)
// ══════════════════════════════════════════════════════════════════════════════

class CabinetProfessionnel {
  final int id;
  final String type;
  final String nomCabinet;
  final String responsable;
  final String ville;
  final String telephone;
  final String email;
  final List<String> specialites;
  final double noteMoyenne;
  final int nbExpertises;
  final int? tarifBase;

  const CabinetProfessionnel({
    required this.id,
    required this.type,
    required this.nomCabinet,
    required this.responsable,
    required this.ville,
    required this.telephone,
    required this.email,
    required this.specialites,
    required this.noteMoyenne,
    required this.nbExpertises,
    this.tarifBase,
  });

  factory CabinetProfessionnel.fromMap(Map<String, dynamic> map) {
    return CabinetProfessionnel(
      id:           map['id'] as int? ?? 0,
      type:         map['type'] as String? ?? '',
      nomCabinet:   map['nom_cabinet'] as String? ?? '',
      responsable:  map['responsable'] as String? ?? '',
      ville:        map['ville'] as String? ?? '',
      telephone:    map['telephone'] as String? ?? '',
      email:        map['email'] as String? ?? '',
      specialites:  (map['specialites'] as List?)?.map((e) => e.toString()).toList() ?? [],
      noteMoyenne:  (map['note_moyenne'] as num?)?.toDouble() ?? 0.0,
      nbExpertises: map['nb_expertises'] as int? ?? 0,
      tarifBase:    map['tarif_base'] as int?,
    );
  }

  String get libelleType {
    return switch (type) {
      'notaire'            => 'Notaire',
      'huissier'           => 'Huissier de justice',
      'avocat'             => 'Avocat',
      'expert_immobilier'  => 'Expert immobilier',
      'expert_vehicule'    => 'Expert automobile',
      'expert_financier'   => 'Conseiller financier',
      _                    => type,
    };
  }

  IconData get icon {
    return switch (type) {
      'notaire'            => Icons.gavel,
      'huissier'           => Icons.balance,
      'avocat'             => Icons.account_balance,
      'expert_immobilier'  => Icons.home_work,
      'expert_vehicule'    => Icons.directions_car,
      'expert_financier'   => Icons.trending_up,
      _                    => Icons.business,
    };
  }

  Color get typeColor {
    return switch (type) {
      'notaire'            => const Color(0xFF1565C0),
      'huissier'           => const Color(0xFF6A1B9A),
      'avocat'             => const Color(0xFF2E7D32),
      'expert_immobilier'  => const Color(0xFFE65100),
      'expert_vehicule'    => const Color(0xFF00838F),
      'expert_financier'   => const Color(0xFF4527A0),
      _                    => Colors.grey,
    };
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EXPERTISE REQUEST (demande d'expertise)
// ══════════════════════════════════════════════════════════════════════════════

class ExpertiseRequest {
  final int id;
  final String reference;
  final String typeExpertise;
  final String statut;
  final int montantTotal;
  final double? valeurEstimee;
  final bool urgence;
  final String? rapportUrl;
  final DateTime? dateRapport;
  final String? notesClient;
  final String? notesExpert;
  final Map<String, dynamic>? asset;
  final CabinetProfessionnel? cabinet;
  final DateTime createdAt;

  const ExpertiseRequest({
    required this.id,
    required this.reference,
    required this.typeExpertise,
    required this.statut,
    required this.montantTotal,
    this.valeurEstimee,
    required this.urgence,
    this.rapportUrl,
    this.dateRapport,
    this.notesClient,
    this.notesExpert,
    this.asset,
    this.cabinet,
    required this.createdAt,
  });

  factory ExpertiseRequest.fromMap(Map<String, dynamic> map) {
    return ExpertiseRequest(
      id:             map['id'] as int? ?? 0,
      reference:      map['reference'] as String? ?? '',
      typeExpertise:  map['type_expertise'] as String? ?? '',
      statut:         map['statut'] as String? ?? 'en_attente',
      montantTotal:   map['montant_total'] as int? ?? 0,
      valeurEstimee:  (map['valeur_estimee'] as num?)?.toDouble(),
      urgence:        map['urgence'] as bool? ?? false,
      rapportUrl:     map['rapport_url'] as String?,
      dateRapport:    map['date_rapport'] != null
                          ? DateTime.tryParse(map['date_rapport'] as String)
                          : null,
      notesClient:    map['notes_client'] as String?,
      notesExpert:    map['notes_expert'] as String?,
      asset:          map['asset'] != null
                          ? Map<String, dynamic>.from(map['asset'] as Map)
                          : null,
      cabinet:        map['cabinet'] != null
                          ? CabinetProfessionnel.fromMap(map['cabinet'] as Map<String, dynamic>)
                          : null,
      createdAt:      DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String get statutLabel {
    return switch (statut) {
      'en_attente'      => 'En attente',
      'en_cours'        => 'En cours',
      'rapport_soumis'  => 'Rapport soumis',
      'valide'          => 'Validée',
      'annule'          => 'Annulée',
      _                 => statut,
    };
  }

  Color get statutColor {
    return switch (statut) {
      'en_attente'     => Colors.orange,
      'en_cours'       => Colors.blue,
      'rapport_soumis' => Colors.teal,
      'valide'         => Colors.green,
      'annule'         => Colors.red,
      _                => Colors.grey,
    };
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ASMAN SCORE
// ══════════════════════════════════════════════════════════════════════════════

class AsmanScore {
  final int scoreTotal;
  final String niveau;
  final int scoreDiversification;
  final int scoreCertification;
  final int scoreLiquidite;
  final int scoreDocumentation;
  final int scoreRegularite;
  final String badgeColor;
  final List<String> recommandations;
  final DateTime? updatedAt;

  const AsmanScore({
    required this.scoreTotal,
    required this.niveau,
    required this.scoreDiversification,
    required this.scoreCertification,
    required this.scoreLiquidite,
    required this.scoreDocumentation,
    required this.scoreRegularite,
    required this.badgeColor,
    required this.recommandations,
    this.updatedAt,
  });

  factory AsmanScore.fromMap(Map<String, dynamic> map) {
    return AsmanScore(
      scoreTotal:           map['score_total'] as int? ?? 0,
      niveau:               map['niveau'] as String? ?? 'Débutant',
      scoreDiversification: map['score_diversification'] as int? ?? 0,
      scoreCertification:   map['score_certification'] as int? ?? 0,
      scoreLiquidite:       map['score_liquidite'] as int? ?? 0,
      scoreDocumentation:   map['score_documentation'] as int? ?? 0,
      scoreRegularite:      map['score_regularite'] as int? ?? 0,
      badgeColor:           map['badge_color'] as String? ?? '#9E9E9E',
      recommandations:      (map['recommandations'] as List?)
                                ?.map((e) => e.toString()).toList() ?? [],
      updatedAt:            map['updated_at'] != null
                                ? DateTime.tryParse(map['updated_at'] as String)
                                : null,
    );
  }

  Color get color {
    try {
      final hex = badgeColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  double get progressRatio => scoreTotal / 1000;

  String get niveauEmoji {
    return switch (niveau) {
      'Patriarche'   => '👑',
      'Expert'       => '💎',
      'Confirmé'     => '⭐',
      'Intermédiaire' => '🔷',
      _              => '🔰',
    };
  }
}
