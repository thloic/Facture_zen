import 'package:flutter_test/flutter_test.dart';
import 'package:facture_zen/common/services/tracking_service.dart';

/// Vérifie que TrackingService bloque bien tout envoi tant que le
/// consentement n'a pas été explicitement accordé (fail-safe par défaut).
///
/// TrackingService() est un singleton dont `_isTrackingAuthorized` vaut
/// `false` tant que `initialize()` n'a pas été appelé avec succès. Ce test
/// n'appelle volontairement PAS `initialize()` (qui nécessiterait de mocker
/// les plugins natifs ATT/Firebase/Facebook) : il vérifie que, dans cet état
/// par défaut, chaque méthode publique retourne immédiatement sans tenter
/// d'appeler un plugin natif (ce qui lèverait une MissingPluginException en
/// environnement de test si le garde-fou était absent ou mal placé).
void main() {
  group('TrackingService — refus par défaut sans consentement', () {
    final service = TrackingService();

    test('logSignUp ne lève pas d\'exception', () async {
      await expectLater(service.logSignUp(method: 'email'), completes);
    });

    test('logLogin ne lève pas d\'exception', () async {
      await expectLater(service.logLogin(method: 'email'), completes);
    });

    test('logPurchase (montant réel) ne lève pas d\'exception', () async {
      await expectLater(
        service.logPurchase(productId: 'zen_pro', price: 19.99, currency: 'EUR'),
        completes,
      );
    });

    test('logAddToCart ne lève pas d\'exception', () async {
      await expectLater(
        service.logAddToCart(productId: 'zen_pro', price: 19.99, currency: 'EUR'),
        completes,
      );
    });

    test('logBeginCheckout ne lève pas d\'exception', () async {
      await expectLater(
        service.logBeginCheckout(productId: 'zen_pro', price: 19.99, currency: 'EUR'),
        completes,
      );
    });

    test('logCreateInvoice (montant de facture) ne lève pas d\'exception', () async {
      await expectLater(
        service.logCreateInvoice(amount: 150.0, currency: 'EUR'),
        completes,
      );
    });

    test('logVoiceRecording ne lève pas d\'exception', () async {
      await expectLater(service.logVoiceRecording(), completes);
    });

    test('logViewSubscription ne lève pas d\'exception', () async {
      await expectLater(
        service.logViewSubscription(productId: 'zen_pro'),
        completes,
      );
    });

    test('setUserId ne lève pas d\'exception', () async {
      await expectLater(service.setUserId('some-uid'), completes);
    });

    test('setUserData (email/nom = PII) ne lève pas d\'exception', () async {
      await expectLater(
        service.setUserData(
          email: 'user@example.com',
          firstName: 'Jean',
          lastName: 'Dupont',
        ),
        completes,
      );
    });

    test('logScreenView ne lève pas d\'exception', () async {
      await expectLater(
        service.logScreenView(screenName: 'home'),
        completes,
      );
    });

    test('logCustomEvent ne lève pas d\'exception', () async {
      await expectLater(
        service.logCustomEvent(name: 'test_event'),
        completes,
      );
    });
  });
}
