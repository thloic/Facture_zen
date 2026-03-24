import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';
import 'facebook_analytics_service.dart';

/// Service unifié pour le tracking Google Ads + Facebook Ads
/// Envoie les événements aux deux plateformes en parallèle
class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  final AnalyticsService _firebaseAnalytics = AnalyticsService();
  final FacebookAnalyticsService _facebookAnalytics = FacebookAnalyticsService();

  bool _isTrackingAuthorized = false;

  /// ===== INITIALISATION =====

  /// Initialiser le tracking (demande la permission iOS + active Facebook)
  Future<void> initialize() async {
    // Demander la permission de tracking sur iOS
    if (Platform.isIOS) {
      await _requestTrackingPermission();
    } else {
      // Sur Android, le tracking est autorisé par défaut
      _isTrackingAuthorized = true;
    }

    // Configurer le tracking Facebook selon la permission (doit être fait AVANT logActivateApp)
    await _facebookAnalytics.setAdvertiserTrackingEnabled(_isTrackingAuthorized);
    // S'assurer que l'autolog est activé (important si désactivé côté Facebook)
    await _facebookAnalytics.setAutoLogAppEventsEnabled(true);
    // Activer Facebook App Events
    await _facebookAnalytics.logActivateApp();

    debugPrint('🎯 TrackingService initialized (authorized: $_isTrackingAuthorized)');
  }

  /// Demander la permission ATT (App Tracking Transparency) sur iOS
  Future<void> _requestTrackingPermission() async {
    try {
      // Vérifier le statut actuel
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      debugPrint('🔒 ATT current status: $status');

      if (status == TrackingStatus.notDetermined) {
        // Attendre un peu pour que l'UI soit prête (recommandé par Apple)
        await Future.delayed(const Duration(milliseconds: 500));

        // Demander la permission
        final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();
        _isTrackingAuthorized = newStatus == TrackingStatus.authorized;
        debugPrint('🔒 ATT new status: $newStatus');
      } else {
        _isTrackingAuthorized = status == TrackingStatus.authorized;
      }
    } catch (e) {
      debugPrint('❌ ATT error: $e');
      _isTrackingAuthorized = false;
    }
  }

  /// ===== ÉVÉNEMENTS D'INSCRIPTION =====

  /// Tracker une inscription réussie (Firebase + Facebook)
  Future<void> logSignUp({String? method}) async {
    await Future.wait([
      _firebaseAnalytics.logSignUp(method: method),
      _facebookAnalytics.logCompleteRegistration(registrationMethod: method),
    ]);
  }

  /// Tracker une connexion réussie
  Future<void> logLogin({String? method}) async {
    await Future.wait([
      _firebaseAnalytics.logLogin(method: method),
      _facebookAnalytics.logCustomEvent(eventName: 'fb_mobile_complete_login'),
    ]);
  }

  /// ===== ÉVÉNEMENTS D'ACHAT =====

  /// Tracker un achat (Firebase + Facebook)
  Future<void> logPurchase({
    required String productId,
    required double price,
    required String currency,
    String? transactionId,
  }) async {
    await Future.wait([
      _firebaseAnalytics.logPurchase(
        productId: productId,
        price: price,
        currency: currency,
        transactionId: transactionId,
      ),
      _facebookAnalytics.logPurchase(
        amount: price,
        currency: currency,
        parameters: {
          'content_id': productId,
          'transaction_id': transactionId ?? '',
        },
      ),
    ]);
  }

  /// Tracker l'ajout au panier (Firebase + Facebook)
  Future<void> logAddToCart({
    required String productId,
    required double price,
    required String currency,
  }) async {
    await Future.wait([
      _firebaseAnalytics.logAddToCart(
        productId: productId,
        price: price,
        currency: currency,
      ),
      _facebookAnalytics.logAddToCart(
        contentId: productId,
        contentType: 'subscription',
        currency: currency,
        price: price,
      ),
    ]);
  }

  /// Tracker le début du checkout (Firebase + Facebook)
  Future<void> logBeginCheckout({
    required String productId,
    required double price,
    required String currency,
  }) async {
    await Future.wait([
      _firebaseAnalytics.logBeginCheckout(
        productId: productId,
        price: price,
        currency: currency,
      ),
      _facebookAnalytics.logInitiatedCheckout(
        totalPrice: price,
        currency: currency,
        contentId: productId,
        numItems: 1,
      ),
    ]);
  }

  /// ===== ÉVÉNEMENTS MÉTIER =====

  /// Tracker la création d'une facture (Firebase + Facebook)
  Future<void> logCreateInvoice({double? amount, String? currency}) async {
    await Future.wait([
      _firebaseAnalytics.logCreateInvoice(amount: amount, currency: currency),
      _facebookAnalytics.logCreateInvoice(amount: amount, currency: currency),
    ]);
  }

  /// Tracker l'utilisation de la voix (Firebase + Facebook)
  Future<void> logVoiceRecording() async {
    await Future.wait([
      _firebaseAnalytics.logVoiceRecording(),
      _facebookAnalytics.logVoiceRecording(),
    ]);
  }

  /// Tracker l'affichage de l'écran d'abonnement (Firebase + Facebook)
  Future<void> logViewSubscription({
    required String productId,
    double? price,
    String? currency,
  }) async {
    await Future.wait([
      _firebaseAnalytics.logViewSubscription(),
      _facebookAnalytics.logViewContent(
        contentId: productId,
        contentType: 'subscription',
        price: price,
        currency: currency,
      ),
    ]);
  }

  /// ===== CONFIGURATION UTILISATEUR =====

  /// Définir l'ID utilisateur (Firebase + Facebook)
  Future<void> setUserId(String? userId) async {
    await Future.wait([
      _firebaseAnalytics.setUserId(userId),
      _facebookAnalytics.setUserId(userId),
    ]);
  }

  /// Définir les données utilisateur pour Facebook (matching avancé)
  Future<void> setUserData({
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    await _facebookAnalytics.setUserData(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
  }

  /// ===== NAVIGATION =====

  /// Tracker la vue d'un écran
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _firebaseAnalytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// ===== ÉVÉNEMENT PERSONNALISÉ =====

  /// Tracker un événement personnalisé (Firebase + Facebook)
  Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await Future.wait([
      _firebaseAnalytics.logCustomEvent(name: name, parameters: parameters),
      _facebookAnalytics.logCustomEvent(
        eventName: name,
        parameters: parameters?.map((k, v) => MapEntry(k, v)),
      ),
    ]);
  }
}
