// lib/services/revenue_cat_service.dart
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';

// Import de votre util existant
import 'package:facture_zen/revenue_cat_util.dart' as rc_util;

// Ré-exporter pour faciliter l'usage
export 'package:purchases_flutter/purchases_flutter.dart' show Package, Offering, CustomerInfo, PackageType;
export 'package:facture_zen/revenue_cat_util.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // Accesseurs vers l'util existant
  Offerings? get offerings => rc_util.offerings;
  CustomerInfo? get customerInfo => rc_util.customerInfo;
  bool get isPremium => rc_util.isPremium;
  List<Package>? get availablePackages => rc_util.availablePackages;
  List<String> get activeEntitlementIds => rc_util.activeEntitlementIds;

  // Méthodes de l'util
  Future<void> initialize(
      String appStoreKey,
      String playStoreKey, {
        bool debugLogEnabled = false,
        bool loadDataAfterLaunch = false,
      }) => rc_util.initialize(
    appStoreKey,
    playStoreKey,
    debugLogEnabled: debugLogEnabled,
    loadDataAfterLaunch: loadDataAfterLaunch,
  );

  Future<void> loadOfferings() => rc_util.loadOfferings();
  Future<void> loadCustomerInfo() => rc_util.loadCustomerInfo();
  Future<bool> purchasePackage(String packageIdentifier) => rc_util.purchasePackage(packageIdentifier);
  Future<bool?> isEntitled(String entitlementId) => rc_util.isEntitled(entitlementId);
  Future<void> login(String? uid) => rc_util.login(uid);
  Future<void> restorePurchases() => rc_util.restorePurchases();

  // ✅ NOUVELLES MÉTHODES qui manquent dans l'util

  /// Acheter un package avec l'objet Package directement
  Future<bool> purchasePackageObject(Package package) async {
    try {
      final PurchaseResult result = await Purchases.purchasePackage(package);
      rc_util.customerInfo = result.customerInfo;

      final bool isPurchased = result.customerInfo.entitlements.active.isNotEmpty;
      print(isPurchased ? '✅ Purchase successful' : '⚠️ Purchase incomplete');

      return isPurchased;
    } on PlatformException catch (e) {
      if (e.code == 'PURCHASE_CANCELLED') {
        print('ℹ️ Purchase cancelled by user');
        return false;
      }
      print('❌ Purchase error: $e');
      rethrow;
    } catch (e) {
      print('❌ Purchase error: $e');
      rethrow;
    }
  }

  /// Obtenir un package spécifique par identifiant
  Package? getPackage(String packageIdentifier) {
    return offerings?.current?.getPackage(packageIdentifier);
  }

  /// Obtenir le package mensuel (si disponible)
  Package? get monthlyPackage {
    return offerings?.current?.monthly;
  }

  /// Obtenir le package annuel (si disponible)
  Package? get annualPackage {
    return offerings?.current?.annual;
  }

  /// Obtenir le package hebdomadaire (si disponible)
  Package? get weeklyPackage {
    return offerings?.current?.weekly;
  }

  /// Obtenir tous les packages d'une offering spécifique
  List<Package>? getPackagesForOffering(String offeringIdentifier) {
    return offerings?.all[offeringIdentifier]?.availablePackages;
  }
}