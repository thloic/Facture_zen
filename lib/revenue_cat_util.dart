import 'dart:io' show Platform;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

export 'package:purchases_flutter/purchases_flutter.dart' show Package, Offering;

Offerings? _offerings;
CustomerInfo? _customerInfo;
String? _loggedInUid;

Offerings? get offerings => _offerings;

CustomerInfo? get customerInfo => _customerInfo;

set customerInfo(CustomerInfo? customerInfo) => _customerInfo = customerInfo;

Future initialize(
    String appStoreKey,
    String playStoreKey, {
      bool debugLogEnabled = false,
      bool loadDataAfterLaunch = false,
    }) async {
  if (kIsWeb) {
    print('RevenueCat is not supported on web.');
    return;
  }
  try {

    if (debugLogEnabled) {
      Purchases.setLogLevel(LogLevel.debug);
    }
    // Configuration
    final configuration = PurchasesConfiguration(
      Platform.isIOS ? appStoreKey : playStoreKey,
    );

    await Purchases.configure(configuration);

    if (loadDataAfterLaunch) {
      loadCustomerInfo();
      loadOfferings();
    } else {
      await loadCustomerInfo();
      await loadOfferings();
    }

    Purchases.addCustomerInfoUpdateListener((info) {
      customerInfo = info;
    });

    print('✅ RevenueCat initialized successfully');
  } on Exception catch (e) {
    print("❌ RevenueCat initialization failed: $e");
  }
}

/// ✅ CORRIGÉ : Purchase a package
Future<bool> purchasePackage(String packageIdentifier) async {
  try {
    final revenueCatPackage = offerings?.current?.getPackage(packageIdentifier);
    if (revenueCatPackage == null) {
      print('⚠️ Package not found: $packageIdentifier');
      return false;
    }

    // ✅ purchasePackage retourne maintenant PurchaseResult
    final PurchaseResult result = await Purchases.purchasePackage(revenueCatPackage);

    // Extraire le CustomerInfo du résultat
    customerInfo = result.customerInfo;

    // Vérifier si l'achat a réussi
    final bool isPurchased = result.customerInfo.entitlements.active.isNotEmpty;

    print(isPurchased ? '✅ Purchase successful' : '⚠️ Purchase incomplete');
    return isPurchased;
  } catch (e) {
    print('❌ Purchase error: $e');
    return false;
  }
}

List<String> get activeEntitlementIds =>
    _customerInfo != null
        ? _customerInfo!.entitlements.active.values.map((e) => e.identifier).toList()
        : [];

Future loadOfferings() async {
  try {
    _offerings = await Purchases.getOfferings();
    print("✅ Offerings loaded: ${_offerings?.all.length ?? 0} offerings");
  } on PlatformException catch (e) {
    print("❌ Error loading offerings: $e");
  }
}

Future loadCustomerInfo() async {
  try {
    _customerInfo = await Purchases.getCustomerInfo();
    print("✅ Customer info loaded");
  } on PlatformException catch (e) {
    print("❌ Error loading customer info: $e");
  }
}

/// Return if the user has the entitlement
Future<bool?> isEntitled(String entitlementId) async {
  try {
    customerInfo = await Purchases.getCustomerInfo();
    return customerInfo!.entitlements.all[entitlementId]?.isActive ?? false;
  } on Exception catch (e) {
    print("❌ Unable to check RevenueCat entitlements: $e");
    return null;
  }
}

/// ✅ CORRIGÉ : Login user
/// https://docs.revenuecat.com/docs/user-ids
Future login(String? uid) async {
  if (kIsWeb || uid == _loggedInUid) {
    return;
  }
  try {
    if (uid != null) {
      // ✅ logIn retourne LogInResult
      final LogInResult result = await Purchases.logIn(uid);
      customerInfo = result.customerInfo;
      print('✅ User logged in: $uid (created: ${result.created})');
    } else {
      // ✅ logOut retourne CustomerInfo directement
      customerInfo = await Purchases.logOut();
      print('✅ User logged out');
    }
    _loggedInUid = uid;
  } on Exception catch (e) {
    print("❌ Unable to logIn or logOut user in RevenueCat: $e");
  }
}

/// ✅ CORRIGÉ : Restore purchases
/// https://docs.revenuecat.com/docs/restoring-purchases
Future restorePurchases() async {
  try {
    customerInfo = await Purchases.restorePurchases();
    print('✅ Purchases restored');
  } on PlatformException catch (e) {
    print("❌ Unable to restore purchases in RevenueCat: $e");
  }
}

/// ✅ BONUS : Vérifier si l'utilisateur est premium
bool get isPremium {
  return _customerInfo?.entitlements.active.isNotEmpty ?? false;
}

/// ✅ BONUS : Obtenir les packages disponibles
List<Package>? get availablePackages {
  return offerings?.current?.availablePackages;
}