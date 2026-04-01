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
  final allPackages = <Package>[];
  if (offerings == null) return allPackages;

  // ✅ FORCER l'offering "default" au lieu de "current"
  final defaultOffering = offerings!.all['default'] ?? offerings!.current;

  if (defaultOffering == null) {
    debugPrint('⚠️ Default offering introuvable');
    return allPackages;
  }

  debugPrint('🔍 Loading packages from offering: ${defaultOffering.identifier}');
  
  // Package mensuel
  final monthlyPackage = defaultOffering.monthly;
  if (monthlyPackage != null) {
    allPackages.add(monthlyPackage);
    debugPrint('✅ Added (monthly): ${monthlyPackage.identifier} → ${monthlyPackage.storeProduct.identifier}');
  }
  
  // Package annuel
  final annualPackage = defaultOffering.annual;
  if (annualPackage != null) {
    allPackages.add(annualPackage);
    debugPrint('✅ Added (annual): ${annualPackage.identifier} → ${annualPackage.storeProduct.identifier}');
  }
  
  // Package à vie
  final lifetimePackage = defaultOffering.lifetime;
  if (lifetimePackage != null) {
    allPackages.add(lifetimePackage);
    debugPrint('✅ Added (lifetime): ${lifetimePackage.identifier} → ${lifetimePackage.storeProduct.identifier}');
  }

  debugPrint('✅ Total packages loaded: ${allPackages.length}');
  return allPackages;
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