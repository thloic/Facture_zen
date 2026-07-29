import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service centralisé pour Firebase Analytics
/// Utilisé pour tracker les événements Google Ads
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Obtenir l'observer pour la navigation (à utiliser dans MaterialApp)
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Active/désactive la collecte Firebase Analytics selon le consentement
  /// de l'utilisateur (ATT sur iOS, popup de consentement sur Android).
  /// Quand désactivée, le SDK Firebase ignore lui-même tous les événements
  /// (y compris ceux de [observer]), donc aucun garde supplémentaire n'est
  /// nécessaire par événement.
  Future<void> setCollectionEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  /// ===== ÉVÉNEMENTS D'INSCRIPTION =====

  /// Tracker une inscription réussie
  Future<void> logSignUp({String? method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method ?? 'email');
      debugPrint('📊 Analytics: sign_up logged (method: $method)');
    } catch (e) {
      debugPrint('❌ Analytics error (logSignUp): $e');
    }
  }

  /// Tracker une connexion réussie
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method ?? 'email');
      debugPrint('📊 Analytics: login logged (method: $method)');
    } catch (e) {
      debugPrint('❌ Analytics error (logLogin): $e');
    }
  }

  /// ===== ÉVÉNEMENTS D'ACHAT =====

  /// Tracker un achat (abonnement)
  Future<void> logPurchase({
    required String productId,
    required double price,
    required String currency,
    String? transactionId,
  }) async {
    try {
      await _analytics.logPurchase(
        currency: currency,
        value: price,
        items: [
          AnalyticsEventItem(
            itemId: productId,
            itemName: productId,
            price: price,
          ),
        ],
        transactionId: transactionId,
      );
      debugPrint('📊 Analytics: purchase logged ($productId - $price $currency)');
    } catch (e) {
      debugPrint('❌ Analytics error (logPurchase): $e');
    }
  }

  /// Tracker l'ajout au panier (début du processus d'achat)
  Future<void> logAddToCart({
    required String productId,
    required double price,
    required String currency,
  }) async {
    try {
      await _analytics.logAddToCart(
        currency: currency,
        value: price,
        items: [
          AnalyticsEventItem(
            itemId: productId,
            itemName: productId,
            price: price,
          ),
        ],
      );
      debugPrint('📊 Analytics: add_to_cart logged ($productId)');
    } catch (e) {
      debugPrint('❌ Analytics error (logAddToCart): $e');
    }
  }

  /// Tracker le début du checkout
  Future<void> logBeginCheckout({
    required String productId,
    required double price,
    required String currency,
  }) async {
    try {
      await _analytics.logBeginCheckout(
        currency: currency,
        value: price,
        items: [
          AnalyticsEventItem(
            itemId: productId,
            itemName: productId,
            price: price,
          ),
        ],
      );
      debugPrint('📊 Analytics: begin_checkout logged ($productId)');
    } catch (e) {
      debugPrint('❌ Analytics error (logBeginCheckout): $e');
    }
  }

  /// ===== ÉVÉNEMENTS MÉTIER =====

  /// Tracker la création d'une facture
  Future<void> logCreateInvoice({double? amount, String? currency}) async {
    try {
      await _analytics.logEvent(
        name: 'create_invoice',
        parameters: {
          'amount': amount ?? 0,
          'currency': currency ?? 'EUR',
        },
      );
      debugPrint('📊 Analytics: create_invoice logged');
    } catch (e) {
      debugPrint('❌ Analytics error (logCreateInvoice): $e');
    }
  }

  /// Tracker l'utilisation de la reconnaissance vocale
  Future<void> logVoiceRecording() async {
    try {
      await _analytics.logEvent(name: 'voice_recording_used');
      debugPrint('📊 Analytics: voice_recording_used logged');
    } catch (e) {
      debugPrint('❌ Analytics error (logVoiceRecording): $e');
    }
  }

  /// Tracker l'affichage de l'écran d'abonnement
  Future<void> logViewSubscription() async {
    try {
      await _analytics.logEvent(name: 'view_subscription_screen');
      debugPrint('📊 Analytics: view_subscription_screen logged');
    } catch (e) {
      debugPrint('❌ Analytics error (logViewSubscription): $e');
    }
  }

  /// ===== ÉVÉNEMENTS PERSONNALISÉS =====

  /// Tracker un événement personnalisé
  Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('📊 Analytics: $name logged');
    } catch (e) {
      debugPrint('❌ Analytics error (logCustomEvent $name): $e');
    }
  }

  /// ===== CONFIGURATION UTILISATEUR =====

  /// Définir l'ID utilisateur pour le suivi cross-device
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      debugPrint('📊 Analytics: userId set to $userId');
    } catch (e) {
      debugPrint('❌ Analytics error (setUserId): $e');
    }
  }

  /// Définir des propriétés utilisateur personnalisées
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint('📊 Analytics: user property $name set to $value');
    } catch (e) {
      debugPrint('❌ Analytics error (setUserProperty): $e');
    }
  }

  /// Tracker l'écran actuel (pour les rapports de navigation)
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      debugPrint('📊 Analytics: screen_view logged ($screenName)');
    } catch (e) {
      debugPrint('❌ Analytics error (logScreenView): $e');
    }
  }
}
