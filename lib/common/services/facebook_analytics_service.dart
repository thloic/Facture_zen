import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

/// Service centralisé pour Facebook App Events
/// Utilisé pour tracker les événements Facebook Ads
class FacebookAnalyticsService {
  static final FacebookAnalyticsService _instance = FacebookAnalyticsService._internal();
  factory FacebookAnalyticsService() => _instance;
  FacebookAnalyticsService._internal();

  final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  /// ===== INITIALISATION =====

  /// Activer l'app (à appeler au lancement)
  Future<void> logActivateApp() async {
    try {
      // Utiliser logEvent car logActivatedApp n'existe pas dans cette version
      await _facebookAppEvents.logEvent(name: 'fb_mobile_activate_app');
      debugPrint('📘 Facebook: activated_app logged');
    } catch (e) {
      debugPrint('❌ Facebook error (logActivateApp): $e');
    }
  }

  /// ===== ÉVÉNEMENTS D'INSCRIPTION =====

  /// Tracker une inscription réussie
  Future<void> logCompleteRegistration({String? registrationMethod}) async {
    try {
      await _facebookAppEvents.logCompletedRegistration(
        registrationMethod: registrationMethod ?? 'email',
      );
      debugPrint('📘 Facebook: complete_registration logged (method: $registrationMethod)');
    } catch (e) {
      debugPrint('❌ Facebook error (logCompleteRegistration): $e');
    }
  }

  /// ===== ÉVÉNEMENTS D'ACHAT =====

  /// Tracker un achat (abonnement)
  Future<void> logPurchase({
    required double amount,
    required String currency,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _facebookAppEvents.logPurchase(
        amount: amount,
        currency: currency,
        parameters: parameters,
      );
      debugPrint('📘 Facebook: purchase logged ($amount $currency)');
    } catch (e) {
      debugPrint('❌ Facebook error (logPurchase): $e');
    }
  }

  /// Tracker le début du checkout
  Future<void> logInitiatedCheckout({
    double? totalPrice,
    String? currency,
    String? contentId,
    int? numItems,
  }) async {
    try {
      await _facebookAppEvents.logInitiatedCheckout(
        totalPrice: totalPrice,
        currency: currency,
        contentId: contentId,
        numItems: numItems,
      );
      debugPrint('📘 Facebook: initiated_checkout logged');
    } catch (e) {
      debugPrint('❌ Facebook error (logInitiatedCheckout): $e');
    }
  }

  /// Tracker l'ajout au panier
  Future<void> logAddToCart({
    required String contentId,
    required String contentType,
    required String currency,
    required double price,
  }) async {
    try {
      await _facebookAppEvents.logAddToCart(
        id: contentId,
        type: contentType,
        currency: currency,
        price: price,
      );
      debugPrint('📘 Facebook: add_to_cart logged ($contentId)');
    } catch (e) {
      debugPrint('❌ Facebook error (logAddToCart): $e');
    }
  }

  /// ===== ÉVÉNEMENTS MÉTIER =====

  /// Tracker la vue d'un contenu (ex: écran d'abonnement)
  Future<void> logViewContent({
    required String contentId,
    required String contentType,
    String? currency,
    double? price,
  }) async {
    try {
      await _facebookAppEvents.logViewContent(
        id: contentId,
        type: contentType,
        currency: currency,
        price: price,
      );
      debugPrint('📘 Facebook: view_content logged ($contentId)');
    } catch (e) {
      debugPrint('❌ Facebook error (logViewContent): $e');
    }
  }

  /// Tracker la recherche (si applicable)
  Future<void> logSearch({required String searchString}) async {
    try {
      // Utiliser logEvent car logSearch n'existe pas dans cette version
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_search',
        parameters: {'fb_search_string': searchString},
      );
      debugPrint('📘 Facebook: search logged ($searchString)');
    } catch (e) {
      debugPrint('❌ Facebook error (logSearch): $e');
    }
  }

  /// ===== ÉVÉNEMENTS PERSONNALISÉS =====

  /// Tracker un événement personnalisé
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: eventName,
        parameters: parameters,
      );
      debugPrint('📘 Facebook: $eventName logged');
    } catch (e) {
      debugPrint('❌ Facebook error (logCustomEvent $eventName): $e');
    }
  }

  /// Tracker la création d'une facture
  Future<void> logCreateInvoice({double? amount, String? currency}) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'CreateInvoice',
        parameters: {
          'amount': amount ?? 0,
          'currency': currency ?? 'EUR',
        },
      );
      debugPrint('📘 Facebook: CreateInvoice logged');
    } catch (e) {
      debugPrint('❌ Facebook error (logCreateInvoice): $e');
    }
  }

  /// Tracker l'utilisation de la voix
  Future<void> logVoiceRecording() async {
    try {
      await _facebookAppEvents.logEvent(name: 'VoiceRecordingUsed');
      debugPrint('📘 Facebook: VoiceRecordingUsed logged');
    } catch (e) {
      debugPrint('❌ Facebook error (logVoiceRecording): $e');
    }
  }

  /// ===== CONFIGURATION =====

  /// Définir l'ID utilisateur
  Future<void> setUserId(String? userId) async {
    try {
      if (userId != null) {
        await _facebookAppEvents.setUserID(userId);
        debugPrint('📘 Facebook: userId set to $userId');
      } else {
        await _facebookAppEvents.clearUserID();
        debugPrint('📘 Facebook: userId cleared');
      }
    } catch (e) {
      debugPrint('❌ Facebook error (setUserId): $e');
    }
  }

  /// Définir des données utilisateur (pour le matching avancé)
  Future<void> setUserData({
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      await _facebookAppEvents.setUserData(
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      debugPrint('📘 Facebook: user data set');
    } catch (e) {
      debugPrint('❌ Facebook error (setUserData): $e');
    }
  }

  /// Activer/désactiver le logging automatique des événements
  Future<void> setAutoLogAppEventsEnabled(bool enabled) async {
    try {
      await _facebookAppEvents.setAutoLogAppEventsEnabled(enabled);
      debugPrint('📘 Facebook: auto log events set to $enabled');
    } catch (e) {
      debugPrint('❌ Facebook error (setAutoLogAppEventsEnabled): $e');
    }
  }

  /// Activer/désactiver la collecte de données publicitaires
  Future<void> setAdvertiserTrackingEnabled(bool enabled) async {
    try {
      await _facebookAppEvents.setAdvertiserTracking(enabled: enabled);
      debugPrint('📘 Facebook: advertiser tracking set to $enabled');
    } catch (e) {
      debugPrint('❌ Facebook error (setAdvertiserTrackingEnabled): $e');
    }
  }
}
