// lib/features/subscription/services/revenue_cat_service.dart
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
  List<String> get activeEntitlementIds => rc_util.activeEntitlementIds;

  // ✅ NOUVELLE PROPRIÉTÉ: Retourne TOUS les packages de TOUTES les offerings
  List<Package> get allAvailablePackages {
    final allPackages = <Package>[];

    if (offerings == null) {
      print('⚠️ No offerings available');
      return allPackages;
    }

    print('📦 Scanning all offerings...');

    // Parcourir TOUTES les offerings disponibles
    for (var offering in offerings!.all.values) {
      print('  📋 Offering: ${offering.identifier}');
      print('     Packages count: ${offering.availablePackages.length}');

      for (var package in offering.availablePackages) {
        // Éviter les doublons (même identifier)
        if (!allPackages.any((p) => p.identifier == package.identifier)) {
          allPackages.add(package);
          print('     ✅ Added: ${package.identifier} - ${package.storeProduct.title}');
        } else {
          print('     ⏭️ Skipped (duplicate): ${package.identifier}');
        }
      }
    }

    print('✅ Total unique packages found: ${allPackages.length}');
    return allPackages;
  }

  // Obtenir l'offering courante (pour compatibilité)
  Offering? get currentOffering => offerings?.current;

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

  /// ✅ Acheter un package avec l'objet Package directement
  Future<bool> purchasePackageObject(Package package) async {
    try {
      print('🛒 Attempting to purchase: ${package.identifier}');
      print('   Product: ${package.storeProduct.title}');
      print('   Price: ${package.storeProduct.priceString}');

      final PurchaseResult result = await Purchases.purchasePackage(package);
      rc_util.customerInfo = result.customerInfo;

      final bool isPurchased = result.customerInfo.entitlements.active.isNotEmpty;

      if (isPurchased) {
        print('✅ Purchase successful!');
        print('   Active entitlements: ${result.customerInfo.entitlements.active.keys.join(", ")}');
      } else {
        print('⚠️ Purchase completed but no active entitlements found');
      }

      return isPurchased;
    } on PlatformException catch (e) {
      if (e.code == 'PURCHASE_CANCELLED') {
        print('ℹ️ Purchase cancelled by user');
        return false;
      }
      print('❌ Purchase error (PlatformException): ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Purchase error: $e');
      rethrow;
    }
  }

  /// Obtenir un package spécifique par identifiant
  Package? getPackage(String packageIdentifier) {
    return allAvailablePackages.firstWhere(
          (package) => package.identifier == packageIdentifier,
      orElse: () => throw Exception('Package not found: $packageIdentifier'),
    );
  }

  /// Obtenir le package mensuel (cherche dans tous les packages)
  Package? get monthlyPackage {
    try {
      return allAvailablePackages.firstWhere(
            (p) => p.packageType == PackageType.monthly,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtenir le package annuel (cherche dans tous les packages)
  Package? get annualPackage {
    try {
      return allAvailablePackages.firstWhere(
            (p) => p.packageType == PackageType.annual,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtenir le package hebdomadaire (cherche dans tous les packages)
  Package? get weeklyPackage {
    try {
      return allAvailablePackages.firstWhere(
            (p) => p.packageType == PackageType.weekly,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtenir tous les packages d'une offering spécifique
  List<Package>? getPackagesForOffering(String offeringIdentifier) {
    return offerings?.all[offeringIdentifier]?.availablePackages;
  }
}