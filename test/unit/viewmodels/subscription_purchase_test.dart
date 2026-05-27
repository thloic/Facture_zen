// test/unit/viewmodels/subscription_purchase_test.dart
//
// Tests du flux d'achat et de chargement des offres dans SubscriptionViewModel.
// Ces tests remplacent les appels natifs RevenueCat et Firebase par des mocks.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:facture_zen/features/invoicing/viewmodels/subscription_view_model.dart';
import 'package:facture_zen/features/invoicing/services/revenue_cat_service.dart';
import '../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  // -------------------------------------------------------------------------
  // loadOfferings()
  // -------------------------------------------------------------------------

  group('loadOfferings() — liste vide', () {
    late MockRevenueCatService mockRevenueCat;
    late SubscriptionViewModel vm;

    setUp(() {
      mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.loadOfferings()).thenAnswer((_) async {});
      when(() => mockRevenueCat.allAvailablePackages).thenReturn([]);
      when(() => mockRevenueCat.offerings).thenReturn(null);

      vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );
    });

    test('errorMessage = "Aucun abonnement disponible"', () async {
      await vm.loadOfferings();
      expect(vm.errorMessage, 'Aucun abonnement disponible');
    });

    test('allPackages reste null', () async {
      await vm.loadOfferings();
      expect(vm.allPackages, isNull);
    });

    test('isLoading est false après chargement', () async {
      await vm.loadOfferings();
      expect(vm.isLoading, false);
    });
  });

  group('loadOfferings() — exception réseau', () {
    late SubscriptionViewModel vm;

    setUp(() {
      final mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.loadOfferings())
          .thenThrow(Exception('Network error'));
      when(() => mockRevenueCat.allAvailablePackages).thenReturn([]);

      vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );
    });

    test('errorMessage est renseigné', () async {
      await vm.loadOfferings();
      expect(vm.errorMessage, isNotNull);
    });

    test('isLoading est false même après exception', () async {
      await vm.loadOfferings();
      expect(vm.isLoading, false);
    });
  });

  group('loadOfferings() — succès', () {
    late SubscriptionViewModel vm;

    setUp(() {
      final pkg = createMockPackage(productId: 'voxin_pro_monthly');
      final mockRevenueCat = createMockRevenueCat(packages: [pkg]);

      vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );
    });

    test('allPackages est non vide', () async {
      await vm.loadOfferings();
      expect(vm.allPackages, isNotNull);
      expect(vm.allPackages!.isNotEmpty, true);
    });

    test('isLoading est false', () async {
      await vm.loadOfferings();
      expect(vm.isLoading, false);
    });

    test('errorMessage est null', () async {
      await vm.loadOfferings();
      expect(vm.errorMessage, isNull);
    });

    test('selectedPackage est automatiquement sélectionné', () async {
      await vm.loadOfferings();
      expect(vm.selectedPackage, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // purchaseSubscription() — aucun package sélectionné
  // -------------------------------------------------------------------------

  group('purchaseSubscription() — sans package sélectionné', () {
    late SubscriptionViewModel vm;

    setUp(() {
      vm = SubscriptionViewModel.forTesting(
        revenueCatService: createMockRevenueCat(),
        syncService: createNoOpSyncService(),
      );
    });

    test('retourne false', () async {
      final result = await vm.purchaseSubscription();
      expect(result, false);
    });

    test('errorMessage est renseigné', () async {
      await vm.purchaseSubscription();
      expect(vm.errorMessage, isNotNull);
    });

    test('isLoading reste false', () async {
      await vm.purchaseSubscription();
      expect(vm.isLoading, false);
    });
  });

  // -------------------------------------------------------------------------
  // purchaseSubscription() — avec package sélectionné
  // -------------------------------------------------------------------------

  group('purchaseSubscription() — succès', () {
    late MockRevenueCatService mockRevenueCat;
    late MockSubscriptionSyncService mockSync;
    late SubscriptionViewModel vm;

    setUp(() {
      mockRevenueCat = MockRevenueCatService();
      mockSync = MockSubscriptionSyncService();
      when(() => mockSync.syncSubscriptionStatus()).thenAnswer((_) async {});

      when(() => mockRevenueCat.purchasePackageObject(any()))
          .thenAnswer((_) async => true);

      vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: mockSync,
      );
      vm.selectPackage(createMockPackage());
    });

    test('retourne true', () async {
      final result = await vm.purchaseSubscription();
      expect(result, true);
    });

    test('errorMessage est null', () async {
      await vm.purchaseSubscription();
      expect(vm.errorMessage, isNull);
    });

    test('isLoading est false', () async {
      await vm.purchaseSubscription();
      expect(vm.isLoading, false);
    });

    test('syncSubscriptionStatus est appelé exactement une fois', () async {
      await vm.purchaseSubscription();
      verify(() => mockSync.syncSubscriptionStatus()).called(1);
    });
  });

  group('purchaseSubscription() — achat non confirmé (entitlements vides)', () {
    late SubscriptionViewModel vm;

    setUp(() {
      final mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.purchasePackageObject(any()))
          .thenAnswer((_) async => false);

      vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );
      vm.selectPackage(createMockPackage());
    });

    test('retourne false', () async {
      expect(await vm.purchaseSubscription(), false);
    });

    test('errorMessage est renseigné', () async {
      await vm.purchaseSubscription();
      expect(vm.errorMessage, isNotNull);
    });

    test('isLoading est false', () async {
      await vm.purchaseSubscription();
      expect(vm.isLoading, false);
    });
  });

  group('purchaseSubscription() — annulation utilisateur', () {
    late SubscriptionViewModel vm;

    setUp(() {
      final mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.purchasePackageObject(any()))
          .thenThrow(PlatformException(code: 'PURCHASE_CANCELLED'));

      vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );
      vm.selectPackage(createMockPackage());
    });

    test('retourne false', () async {
      expect(await vm.purchaseSubscription(), false);
    });

    // Règle UX : annulation → pas de message d'erreur affiché à l'utilisateur.
    test('errorMessage est null (pas de message d\'erreur)', () async {
      await vm.purchaseSubscription();
      expect(vm.errorMessage, isNull);
    });

    test('isLoading est false', () async {
      await vm.purchaseSubscription();
      expect(vm.isLoading, false);
    });
  });

  group('purchaseSubscription() — erreur réseau', () {
    late SubscriptionViewModel vm;

    setUp(() {
      final mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.purchasePackageObject(any()))
          .thenThrow(PlatformException(code: 'NETWORK_ERROR'));

      vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );
      vm.selectPackage(createMockPackage());
    });

    test('retourne false', () async {
      expect(await vm.purchaseSubscription(), false);
    });

    test('errorMessage mentionne "réseau"', () async {
      await vm.purchaseSubscription();
      expect(vm.errorMessage, contains('réseau'));
    });

    test('isLoading est false', () async {
      await vm.purchaseSubscription();
      expect(vm.isLoading, false);
    });
  });

  group('purchaseSubscription() — erreur de configuration', () {
    late SubscriptionViewModel vm;

    setUp(() {
      final mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.purchasePackageObject(any()))
          .thenThrow(PlatformException(code: 'DEVELOPER_ERROR'));

      vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );
      vm.selectPackage(createMockPackage());
    });

    test('retourne false', () async {
      expect(await vm.purchaseSubscription(), false);
    });

    test('errorMessage mentionne "configuration"', () async {
      await vm.purchaseSubscription();
      expect(vm.errorMessage, contains('configuration'));
    });
  });

  group('purchaseSubscription() — erreur inconnue', () {
    late SubscriptionViewModel vm;

    setUp(() {
      final mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.purchasePackageObject(any()))
          .thenThrow(Exception('Unexpected crash'));

      vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );
      vm.selectPackage(createMockPackage());
    });

    test('retourne false', () async {
      expect(await vm.purchaseSubscription(), false);
    });

    test('errorMessage est renseigné', () async {
      await vm.purchaseSubscription();
      expect(vm.errorMessage, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // restorePurchases()
  // -------------------------------------------------------------------------

  group('restorePurchases() — aucun achat à restaurer', () {
    late SubscriptionViewModel vm;

    setUp(() {
      final mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.restorePurchases()).thenAnswer((_) async {});
      when(() => mockRevenueCat.isPremium).thenReturn(false);

      vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );
    });

    test('retourne false', () async {
      expect(await vm.restorePurchases(), false);
    });

    test('errorMessage est renseigné', () async {
      await vm.restorePurchases();
      expect(vm.errorMessage, isNotNull);
    });
  });

  group('restorePurchases() — achat trouvé', () {
    late SubscriptionViewModel vm;

    setUp(() {
      final mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.restorePurchases()).thenAnswer((_) async {});
      when(() => mockRevenueCat.isPremium).thenReturn(true);

      vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );
    });

    test('retourne true', () async {
      expect(await vm.restorePurchases(), true);
    });

    test('errorMessage est null', () async {
      await vm.restorePurchases();
      expect(vm.errorMessage, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // clearError()
  // -------------------------------------------------------------------------

  group('clearError()', () {
    test('remet errorMessage à null', () async {
      final vm = SubscriptionViewModel.forTesting(
        revenueCatService: createMockRevenueCat(),
        syncService: createNoOpSyncService(),
      );

      // On provoque une erreur via purchaseSubscription sans package
      await vm.purchaseSubscription();
      expect(vm.errorMessage, isNotNull);

      vm.clearError();
      expect(vm.errorMessage, isNull);
    });
  });
}
