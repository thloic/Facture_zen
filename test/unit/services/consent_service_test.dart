import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facture_zen/common/services/consent_service.dart';

/// Vérifie le comportement du consentement RGPD au tracking (Android),
/// pierre angulaire du chantier de conformité : par défaut (avant toute
/// réponse de l'utilisateur), aucun consentement ne doit être considéré
/// comme accordé.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ConsentService', () {
    test('avant toute question, hasBeenAsked=false et isGranted=false (fail-safe)', () async {
      final service = ConsentService();
      expect(await service.hasBeenAsked(), false);
      expect(await service.isGranted(), false);
    });

    test('setConsent(true) persiste hasBeenAsked=true et isGranted=true', () async {
      final service = ConsentService();
      await service.setConsent(true);

      expect(await service.hasBeenAsked(), true);
      expect(await service.isGranted(), true);
    });

    test('setConsent(false) persiste hasBeenAsked=true mais isGranted=false', () async {
      final service = ConsentService();
      await service.setConsent(false);

      expect(await service.hasBeenAsked(), true);
      expect(await service.isGranted(), false);
    });

    test('un refus persiste après un nouveau setConsent(false) (idempotence)', () async {
      final service = ConsentService();
      await service.setConsent(true);
      await service.setConsent(false);

      expect(await service.isGranted(), false);
    });
  });
}
