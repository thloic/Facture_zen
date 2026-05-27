// test/helpers/mocks.dart
//
// Centralize all mocktail mocks and fake factories used across the test suite.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:facture_zen/features/invoicing/services/revenue_cat_service.dart';
import 'package:facture_zen/features/invoicing/services/subscription_sync_service.dart';
import 'package:facture_zen/common/services/firebase_invoice_service.dart';

// ---------------------------------------------------------------------------
// Mock classes
// ---------------------------------------------------------------------------

class MockRevenueCatService extends Mock implements RevenueCatService {}

class MockSubscriptionSyncService extends Mock
    implements SubscriptionSyncService {}

class MockFirebaseInvoiceService extends Mock implements FirebaseInvoiceService {}

class MockPackage extends Mock implements Package {}

class MockStoreProduct extends Mock implements StoreProduct {}

class MockCustomerInfo extends Mock implements CustomerInfo {}

class MockEntitlementInfos extends Mock implements EntitlementInfos {}

class MockFirebaseAuthUser extends Mock implements User {}

// ---------------------------------------------------------------------------
// Fallback registration — call once in setUpAll
// ---------------------------------------------------------------------------

/// Must be called in [setUpAll] for any test that uses [any<Package>()].
void registerFallbacks() {
  registerFallbackValue(MockPackage());
}

// ---------------------------------------------------------------------------
// Factory helpers
// ---------------------------------------------------------------------------

/// Crée un [MockRevenueCatService] dont [loadOfferings] est un no-op et
/// [allAvailablePackages] retourne [packages].
MockRevenueCatService createMockRevenueCat({
  List<Package> packages = const [],
}) {
  final mock = MockRevenueCatService();
  when(() => mock.loadOfferings()).thenAnswer((_) async {});
  when(() => mock.allAvailablePackages).thenReturn(packages);
  when(() => mock.offerings).thenReturn(null);
  return mock;
}

/// Crée un [MockSubscriptionSyncService] dont [syncSubscriptionStatus] est un
/// no-op (n'appelle pas Firebase ni RevenueCat).
MockSubscriptionSyncService createNoOpSyncService() {
  final mock = MockSubscriptionSyncService();
  when(() => mock.syncSubscriptionStatus()).thenAnswer((_) async {});
  return mock;
}

/// Crée un [MockPackage] entièrement configuré avec des valeurs plausibles.
MockPackage createMockPackage({
  String identifier = r'$rc_monthly',
  String productId = 'voxin_pro_monthly',
  double price = 9.99,
  String currency = 'EUR',
  String priceString = '9,99 €',
  String title = 'Voxin Pro',
  PackageType packageType = PackageType.monthly,
}) {
  final product = MockStoreProduct();
  when(() => product.identifier).thenReturn(productId);
  when(() => product.price).thenReturn(price);
  when(() => product.currencyCode).thenReturn(currency);
  when(() => product.priceString).thenReturn(priceString);
  when(() => product.introductoryPrice).thenReturn(null);
  when(() => product.title).thenReturn(title);
  when(() => product.description).thenReturn('');

  final package = MockPackage();
  when(() => package.identifier).thenReturn(identifier);
  when(() => package.storeProduct).thenReturn(product);
  when(() => package.packageType).thenReturn(packageType);

  return package;
}

/// Crée un [MockCustomerInfo] avec un map d'entitlements actifs donné.
MockCustomerInfo createMockCustomerInfo({
  Map<String, EntitlementInfo> activeEntitlements = const {},
}) {
  final mockEntitlements = MockEntitlementInfos();
  when(() => mockEntitlements.active).thenReturn(activeEntitlements);

  final mock = MockCustomerInfo();
  when(() => mock.entitlements).thenReturn(mockEntitlements);
  return mock;
}

/// Crée un [MockFirebaseInvoiceService] configuré avec un uid utilisateur.
MockFirebaseInvoiceService createMockFirebaseService({
  String uid = 'test_user_uid',
}) {
  final mockUser = MockFirebaseAuthUser();
  when(() => mockUser.uid).thenReturn(uid);

  final mock = MockFirebaseInvoiceService();
  when(() => mock.currentUser).thenReturn(mockUser);
  when(() => mock.updateUserPlan(
        isPremium: any(named: 'isPremium'),
        monthlyInvoiceLimit: any(named: 'monthlyInvoiceLimit'),
        planName: any(named: 'planName'),
        allowedTemplatesCount: any(named: 'allowedTemplatesCount'),
      )).thenAnswer((_) async {});
  return mock;
}
