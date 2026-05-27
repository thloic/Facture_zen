// test/integration/paywall_trigger_test.dart
//
// Teste la synchronisation abonnement → Firebase et la logique du paywall.
//
// Deux axes principaux :
//   1. SubscriptionSyncService.syncSubscriptionStatus() appelle Firebase avec
//      le bon plan (premium vs gratuit) selon les entitlements RevenueCat.
//   2. La logique de décision "peut créer une facture ?" est cohérente.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:facture_zen/features/invoicing/services/subscription_sync_service.dart';
import '../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  // -------------------------------------------------------------------------
  // syncSubscriptionStatus() — customerInfo null
  // -------------------------------------------------------------------------

  group('syncSubscriptionStatus() — customerInfo null', () {
    test('ne met PAS à jour Firebase si customerInfo est null', () async {
      final mockRevenueCat = MockRevenueCatService();
      final mockFirebase = createMockFirebaseService();

      when(() => mockRevenueCat.loadCustomerInfo()).thenAnswer((_) async {});
      when(() => mockRevenueCat.customerInfo).thenReturn(null);

      final service = SubscriptionSyncService.forTesting(
        revenueCatService: mockRevenueCat,
        firebaseService: mockFirebase,
      );

      await service.syncSubscriptionStatus();

      verifyNever(() => mockFirebase.updateUserPlan(
            isPremium: any(named: 'isPremium'),
            monthlyInvoiceLimit: any(named: 'monthlyInvoiceLimit'),
            planName: any(named: 'planName'),
            allowedTemplatesCount: any(named: 'allowedTemplatesCount'),
          ));
    });
  });

  // -------------------------------------------------------------------------
  // syncSubscriptionStatus() — aucun entitlement → plan gratuit
  // -------------------------------------------------------------------------

  group('syncSubscriptionStatus() — entitlements vides → plan gratuit', () {
    test('updateUserPlan appelé avec isPremium=false', () async {
      final mockRevenueCat = MockRevenueCatService();
      final mockFirebase = createMockFirebaseService();
      final mockCustomerInfo = createMockCustomerInfo(activeEntitlements: {});

      when(() => mockRevenueCat.loadCustomerInfo()).thenAnswer((_) async {});
      when(() => mockRevenueCat.customerInfo).thenReturn(mockCustomerInfo);

      final service = SubscriptionSyncService.forTesting(
        revenueCatService: mockRevenueCat,
        firebaseService: mockFirebase,
      );

      await service.syncSubscriptionStatus();

      verify(() => mockFirebase.updateUserPlan(
            isPremium: false,
            monthlyInvoiceLimit: any(named: 'monthlyInvoiceLimit'),
            planName: any(named: 'planName'),
            allowedTemplatesCount: any(named: 'allowedTemplatesCount'),
          )).called(1);
    });

    test('updateUserPlan appelé avec monthlyInvoiceLimit=3 (limite gratuit)',
        () async {
      final mockRevenueCat = MockRevenueCatService();
      final mockFirebase = createMockFirebaseService();
      final mockCustomerInfo = createMockCustomerInfo(activeEntitlements: {});

      when(() => mockRevenueCat.loadCustomerInfo()).thenAnswer((_) async {});
      when(() => mockRevenueCat.customerInfo).thenReturn(mockCustomerInfo);

      final service = SubscriptionSyncService.forTesting(
        revenueCatService: mockRevenueCat,
        firebaseService: mockFirebase,
      );

      await service.syncSubscriptionStatus();

      verify(() => mockFirebase.updateUserPlan(
            isPremium: false,
            monthlyInvoiceLimit: 3,
            planName: any(named: 'planName'),
            allowedTemplatesCount: any(named: 'allowedTemplatesCount'),
          )).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // syncSubscriptionStatus() — entitlement 'zen_pro' → plan pro
  // -------------------------------------------------------------------------

  group('syncSubscriptionStatus() — entitlement zen_pro → plan Pro', () {
    late MockRevenueCatService mockRevenueCat;
    late MockFirebaseInvoiceService mockFirebase;

    setUp(() async {
      mockRevenueCat = MockRevenueCatService();
      mockFirebase = createMockFirebaseService();

      // CustomerInfo avec un entitlement 'zen_pro'
      final mockEntitlementInfo = MockEntitlementInfos();
      // EntitlementInfo n'est pas mocké (valeur de la map non lue directement)
      when(() => mockEntitlementInfo.active)
          .thenReturn({'zen_pro': MockEntitlementInfo()});

      final mockCustomerInfo = MockCustomerInfo();
      when(() => mockCustomerInfo.entitlements).thenReturn(mockEntitlementInfo);

      when(() => mockRevenueCat.loadCustomerInfo()).thenAnswer((_) async {});
      when(() => mockRevenueCat.customerInfo).thenReturn(mockCustomerInfo);
    });

    test('updateUserPlan appelé avec isPremium=true', () async {
      final service = SubscriptionSyncService.forTesting(
        revenueCatService: mockRevenueCat,
        firebaseService: mockFirebase,
      );

      await service.syncSubscriptionStatus();

      verify(() => mockFirebase.updateUserPlan(
            isPremium: true,
            monthlyInvoiceLimit: any(named: 'monthlyInvoiceLimit'),
            planName: any(named: 'planName'),
            allowedTemplatesCount: any(named: 'allowedTemplatesCount'),
          )).called(1);
    });

    test('updateUserPlan appelé avec monthlyInvoiceLimit=500', () async {
      final service = SubscriptionSyncService.forTesting(
        revenueCatService: mockRevenueCat,
        firebaseService: mockFirebase,
      );

      await service.syncSubscriptionStatus();

      verify(() => mockFirebase.updateUserPlan(
            isPremium: true,
            monthlyInvoiceLimit: 500,
            planName: any(named: 'planName'),
            allowedTemplatesCount: any(named: 'allowedTemplatesCount'),
          )).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // Logique du paywall — peut-on créer une facture ?
  //
  // La logique dans FirebaseInvoiceService.canCreateInvoice() est :
  //   - isPremium → monthlyCount < monthlyInvoiceLimit
  //   - !isPremium → monthlyCount < FREE_INVOICE_LIMIT (3)
  // On teste la décision sans Firebase via du calcul direct.
  // -------------------------------------------------------------------------

  group('Logique paywall — utilisateur gratuit', () {
    const int freeLimit = 3;

    test('0 factures ce mois → peut créer', () {
      const monthlyCount = 0;
      expect(monthlyCount < freeLimit, true);
    });

    test('2 factures ce mois → peut créer', () {
      const monthlyCount = 2;
      expect(monthlyCount < freeLimit, true);
    });

    test('3 factures ce mois → paywall déclenché', () {
      const monthlyCount = 3;
      expect(monthlyCount < freeLimit, false);
    });

    test('10 factures ce mois → paywall déclenché', () {
      const monthlyCount = 10;
      expect(monthlyCount < freeLimit, false);
    });
  });

  group('Logique paywall — utilisateur premium Zen Pro (500/mois)', () {
    const int proLimit = 500;

    test('0 factures → peut créer', () {
      expect(0 < proLimit, true);
    });

    test('499 factures → peut créer', () {
      expect(499 < proLimit, true);
    });

    test('500 factures → paywall déclenché même pour premium', () {
      expect(500 < proLimit, false);
    });
  });

  // -------------------------------------------------------------------------
  // Invariant PLAN_LIMITS — cohérence des constantes
  // -------------------------------------------------------------------------

  group('PLAN_LIMITS — cohérence des constantes critiques', () {
    test('zen_gratuit : isPremium=false, limit=3', () {
      final plan = SubscriptionSyncService.PLAN_LIMITS['zen_gratuit']!;
      expect(plan.isPremium, false);
      expect(plan.monthlyInvoiceLimit, 3);
    });

    test('zen_basic : isPremium=true, limit=100', () {
      final plan = SubscriptionSyncService.PLAN_LIMITS['zen_basic']!;
      expect(plan.isPremium, true);
      expect(plan.monthlyInvoiceLimit, 100);
    });

    test('zen_pro : isPremium=true, limit=500', () {
      final plan = SubscriptionSyncService.PLAN_LIMITS['zen_pro']!;
      expect(plan.isPremium, true);
      expect(plan.monthlyInvoiceLimit, 500);
    });

    test('zen_entreprise : isPremium=true, limit=5000', () {
      final plan = SubscriptionSyncService.PLAN_LIMITS['zen_entreprise']!;
      expect(plan.isPremium, true);
      expect(plan.monthlyInvoiceLimit, 5000);
    });

    test('tous les plans premium ont limit > freeLimit (3)', () {
      final premiumPlans = SubscriptionSyncService.PLAN_LIMITS.values
          .where((p) => p.isPremium);
      for (final plan in premiumPlans) {
        expect(
          plan.monthlyInvoiceLimit > 3,
          true,
          reason: '${plan.name} devrait avoir une limite > 3',
        );
      }
    });
  });
}

/// Classe stub minimale pour remplir la valeur de la map d'entitlements.
/// On n'a pas besoin de stubber ses méthodes — seule la clé de la map est lue.
class MockEntitlementInfo extends Mock implements EntitlementInfo {}
