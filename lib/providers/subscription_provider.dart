import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';
import '../services/api_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ─── State ────────────────────────────────────────────────────────────────
  List<SubscriptionPlan> _plans = [];
  UserSubscription? _currentSubscription;
  String _currentTier = 'decouverte';
  AsmanScore? _asmanScore;
  List<ExpertiseRequest> _expertises = [];
  List<CabinetProfessionnel> _cabinets = [];

  bool _isLoading = false;
  String? _error;

  // ─── Getters ─────────────────────────────────────────────────────────────
  List<SubscriptionPlan> get plans => _plans;
  UserSubscription? get currentSubscription => _currentSubscription;
  String get currentTier => _currentTier;
  AsmanScore? get asmanScore => _asmanScore;
  List<ExpertiseRequest> get expertises => _expertises;
  List<CabinetProfessionnel> get cabinets => _cabinets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isPremiumOrAbove => ['premium', 'elite', 'family'].contains(_currentTier);
  bool get isEliteOrAbove   => ['elite', 'family'].contains(_currentTier);
  bool get hasActiveSubscription => _currentSubscription?.isActive ?? false;

  // ─── Charger les plans ────────────────────────────────────────────────────
  Future<void> loadPlans() async {
    _setLoading(true);
    try {
      final resp = await _api.get('/subscriptions/plans');
      if (resp['success'] == true) {
        _plans = (resp['data'] as List)
            .map((p) => SubscriptionPlan.fromMap(p as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Charger l'abonnement courant ─────────────────────────────────────────
  Future<void> loadCurrentSubscription() async {
    try {
      final resp = await _api.get('/subscriptions/current');
      if (resp['success'] == true) {
        _currentTier = resp['data']['tier'] as String? ?? 'decouverte';
        final subData = resp['data']['subscription'];
        _currentSubscription = subData != null
            ? UserSubscription.fromMap(subData as Map<String, dynamic>)
            : null;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  // ─── Souscrire à un plan ──────────────────────────────────────────────────
  Future<bool> subscribe({
    required String planSlug,
    required String billingPeriod,
    required String paymentMethod,
    required String paymentRef,
  }) async {
    _setLoading(true);
    try {
      final resp = await _api.post('/subscriptions/subscribe', {
        'plan_slug':      planSlug,
        'billing_period': billingPeriod,
        'payment_method': paymentMethod,
        'payment_ref':    paymentRef,
      });
      if (resp['success'] == true) {
        await loadCurrentSubscription();
        return true;
      }
      _error = resp['message'] as String? ?? 'Erreur lors de la souscription';
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Résilier l'abonnement ────────────────────────────────────────────────
  Future<bool> cancelSubscription() async {
    _setLoading(true);
    try {
      final resp = await _api.post('/subscriptions/cancel', {});
      if (resp['success'] == true) {
        _currentSubscription = null;
        _currentTier = 'decouverte';
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Charger l'Asman Score ────────────────────────────────────────────────
  Future<void> loadAsmanScore() async {
    try {
      final resp = await _api.get('/score/current');
      if (resp['success'] == true) {
        _asmanScore = AsmanScore.fromMap(resp['data'] as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      // Score nécessite plan Standard+, ignorer silencieusement
      if (kDebugMode) debugPrint('Score non disponible: $e');
    }
  }

  // ─── Recalculer le score ──────────────────────────────────────────────────
  Future<void> recalculateScore() async {
    _setLoading(true);
    try {
      final resp = await _api.post('/score/recalculate', {});
      if (resp['success'] == true) {
        _asmanScore = AsmanScore.fromMap(resp['data'] as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Charger les cabinets professionnels ─────────────────────────────────
  Future<void> loadCabinets({String? type, String? ville}) async {
    _setLoading(true);
    try {
      final params = <String, String>{};
      if (type != null) params['type'] = type;
      if (ville != null) params['ville'] = ville;
      final query = params.isNotEmpty
          ? '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&')
          : '';
      final resp = await _api.get('/expertises/cabinets$query');
      if (resp['success'] == true) {
        _cabinets = (resp['data'] as List)
            .map((c) => CabinetProfessionnel.fromMap(c as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Charger les demandes d'expertise ────────────────────────────────────
  Future<void> loadExpertises() async {
    try {
      final resp = await _api.get('/expertises');
      if (resp['success'] == true) {
        _expertises = (resp['data'] as List)
            .map((e) => ExpertiseRequest.fromMap(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  // ─── Créer une demande d'expertise ────────────────────────────────────────
  Future<bool> createExpertise({
    required int assetId,
    required String typeExpertise,
    int? cabinetId,
    String? notesClient,
    bool urgence = false,
  }) async {
    _setLoading(true);
    try {
      final resp = await _api.post('/expertises', {
        'asset_id':               assetId,
        'type_expertise':         typeExpertise,
        if (cabinetId != null) 'professional_license_id': cabinetId,
        if (notesClient != null) 'notes_client': notesClient,
        'urgence': urgence,
      });
      if (resp['success'] == true) {
        await loadExpertises();
        return true;
      }
      _error = resp['message'] as String? ?? 'Erreur';
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Vérifier l'accès à une feature ──────────────────────────────────────
  Future<Map<String, dynamic>> checkFeature(String feature) async {
    try {
      final resp = await _api.get('/subscriptions/feature/$feature');
      if (resp['success'] == true) return resp['data'] as Map<String, dynamic>;
    } catch (_) {}
    return {'has_access': false, 'tier': _currentTier};
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
