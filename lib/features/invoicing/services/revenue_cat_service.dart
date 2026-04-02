// lib/features/subscription/services/revenue_cat_service.dart
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:facture_zen/revenue_cat_util.dart' as rc_util;

export 'package:purchases_flutter/purchases_flutter.dart'
    show Package, Offering, CustomerInfo, PackageType;
export 'package:facture_zen/revenue_cat_util.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  Offerings? get offerings => rc_util.offerings;
  CustomerInfo? get customerInfo => rc_util.customerInfo;
  bool get isPremium => rc_util.isPremium;
  List<String> get activeEntitlementIds => rc_util.activeEntitlementIds;

  // lib/features/subscription/services/revenue_cat_service.dart

List<Package> get allAvailablePackages {
  if (offerings == null) return [];

  // ✅ offerings.current retourne automatiquement le bon Offering selon :
  // - Default Offering du Dashboard
  // - Targeting Rules (audiences, pays, version app)
  // - Experiments (A/B tests)
  // - Scheduled Rules (promos planifiées)
  final currentOff = offerings!.current;

  if (currentOff == null) {
    debugPrint('⚠️ Current offering introuvable');
    return [];
  }

  final packages = currentOff.availablePackages;
  debugPrint('🔍 Loading ${packages.length} packages from offering: ${currentOff.identifier}');
  for (final pkg in packages) {
    debugPrint('✅ Package: ${pkg.identifier} → ${pkg.storeProduct.identifier}');
  }
  return packages;
}
  Offering? get currentOffering => offerings?.current;

  Future<void> initialize(
    String appStoreKey,
    String playStoreKey, {
    bool debugLogEnabled = false,
    bool loadDataAfterLaunch = false,
  }) =>
      rc_util.initialize(
        appStoreKey,
        playStoreKey,
        debugLogEnabled: debugLogEnabled,
        loadDataAfterLaunch: loadDataAfterLaunch,
      );

  Future<void> loadOfferings() => rc_util.loadOfferings();
  Future<void> loadCustomerInfo() => rc_util.loadCustomerInfo();
  Future<bool> purchasePackage(String packageIdentifier) =>
      rc_util.purchasePackage(packageIdentifier);
  Future<bool?> isEntitled(String entitlementId) =>
      rc_util.isEntitled(entitlementId);
  Future<void> login(String? uid) => rc_util.login(uid);
  Future<void> restorePurchases() => rc_util.restorePurchases();

  Future<bool> purchasePackageObject(Package package) async {
    try {
      debugPrint('🛒 Starting purchase for: ${package.identifier}');
      debugPrint('   Product: ${package.storeProduct.title}');
      debugPrint('   Price: ${package.storeProduct.priceString}');

      final PurchaseResult result = await Purchases.purchasePackage(package);
      rc_util.customerInfo = result.customerInfo;

      final bool isPurchased =
          result.customerInfo.entitlements.active.isNotEmpty;

      if (isPurchased) {
        debugPrint('✅ Purchase successful!');
        debugPrint(
            '   Active entitlements: ${result.customerInfo.entitlements.active.keys.join(", ")}');
      } else {
        debugPrint(
            '⚠️ Purchase completed but no active entitlements found');
      }

      return isPurchased;
    } on PlatformException catch (e) {
      if (e.code == 'PURCHASE_CANCELLED') {
        debugPrint('ℹ️ Purchase cancelled by user');
        return false;
      }
      debugPrint(
          '❌ Purchase error (PlatformException): ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Purchase error: $e');
      rethrow;
    }
  }

  Package? getPackage(String packageIdentifier) {
    try {
      return allAvailablePackages
          .firstWhere((p) => p.identifier == packageIdentifier);
    } catch (_) {
      return null;
    }
  }

  Package? get monthlyPackage {
    try {
      return allAvailablePackages
          .firstWhere((p) => p.packageType == PackageType.monthly);
    } catch (_) {
      return null;
    }
  }

  Package? get annualPackage {
    try {
      return allAvailablePackages
          .firstWhere((p) => p.packageType == PackageType.annual);
    } catch (_) {
      return null;
    }
  }

  Package? get weeklyPackage {
    try {
      return allAvailablePackages
          .firstWhere((p) => p.packageType == PackageType.weekly);
    } catch (_) {
      return null;
    }
  }

  List<Package>? getPackagesForOffering(String offeringIdentifier) {
    return offerings?.all[offeringIdentifier]?.availablePackages;
  }
}