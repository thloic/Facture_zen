// ============================================================
// GUIDE : PROMOTIONS MODIFIABLES À DISTANCE VIA REVENUECAT
// ============================================================
//
// Ce fichier est une PROPOSITION D'AMÉLIORATION de revenue_cat_util.dart
// Il n'est pas utilisé dans l'app. Si tu le valides, on remplace
// revenue_cat_util.dart par ce contenu.
//
// PROBLÈME ACTUEL :
//   - Les offerings sont chargées 1 seule fois au démarrage de l'app.
//   - Si le client change une promo sur le Dashboard RevenueCat,
//     l'utilisateur ne voit le changement QUE s'il relance l'app.
//   - Dans revenue_cat_service.dart, l'offering est forcée à 'default'
//     au lieu de laisser offerings.current décider dynamiquement.
//
// SOLUTION :
//   1. Refresh automatique des offerings toutes les 30 min
//   2. Refresh forcé à chaque ouverture de l'écran abonnement
//   3. Utilisation exclusive de offerings.current (pas de 'default' hardcodé)
//   4. Callbacks pour notifier l'UI quand les offerings changent
//
// ============================================================
// COMMENT CRÉER UNE PROMO SANS REBUILD DE L'APP
// ============================================================
//
//  Dashboard RevenueCat → Offerings → [+ New Offering]
//
//  Tu peux créer par exemple :
//    - Identifier : "promo_avril"    → période d'essai 7 jours
//    - Identifier : "black_friday"   → discount 50%
//    - Identifier : "default"        → offre normale
//
//  Pour activer une promo : cliquer sur "Set as Current"
//  → Immédiatement, offerings.current retourne cette nouvelle offre.
//  → AUCUN rebuild nécessaire, AUCUNE modification du code.
//
//  Pour revenir à la normale : remettre "default" en Current.
//
// ============================================================
// ERREUR "Il existe déjà une offre avec un prix plus élevé"
// ============================================================
//
//  Cette erreur se produit sur App Store Connect quand on essaie de
//  modifier le PRIX D'UN PRODUIT existant.
//  Apple interdit de changer le prix de base d'un produit actif.
//
//  LA BONNE APPROCHE (que ResolueCat supporte nativement) :
//    ❌ NE PAS modifier le prix d'un produit existant
//    ✅ Créer un NOUVEAU produit avec le prix promo (ex: zen_pro_promo)
//    ✅ Créer une nouvelle Offering "promo_avril" qui pointe vers ce produit
//    ✅ Mettre cette Offering en "Current" sur le Dashboard
//    ✅ Le code ne change pas, offerings.current affiche automatiquement la promo
//
// ============================================================

import 'dart:async';
import 'dart:io' show Platform;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';

export 'package:purchases_flutter/purchases_flutter.dart' show Package, Offering;

// ─── État interne ────────────────────────────────────────────

Offerings? _offerings;
CustomerInfo? _customerInfo;
String? _loggedInUid;

// NOUVEAU : timer pour le refresh automatique
Timer? _offeringsRefreshTimer;

// NOUVEAU : callback pour notifier l'UI d'un changement d'offering
// Utilisation : rc_util.onOfferingsChanged = () => setState(() {});
void Function()? onOfferingsChanged;

// ─── Getters ─────────────────────────────────────────────────

Offerings? get offerings => _offerings;
CustomerInfo? get customerInfo => _customerInfo;
set customerInfo(CustomerInfo? value) => _customerInfo = value;

// INCHANGÉ : fonctionne déjà bien
bool get isPremium => _customerInfo?.entitlements.active.isNotEmpty ?? false;

List<String> get activeEntitlementIds =>
    _customerInfo?.entitlements.active.values
        .map((e) => e.identifier)
        .toList() ?? [];

// INCHANGÉ : fonctionne déjà bien, utilise bien offerings.current
List<Package>? get availablePackages => offerings?.current?.availablePackages;

// ─── Initialisation ──────────────────────────────────────────

Future<void> initialize(
  String appStoreKey,
  String playStoreKey, {
  bool debugLogEnabled = false,
  bool loadDataAfterLaunch = false,
}) async {
  if (kIsWeb) return;

  try {
    if (debugLogEnabled) Purchases.setLogLevel(LogLevel.debug);

    await Purchases.configure(
      PurchasesConfiguration(Platform.isIOS ? appStoreKey : playStoreKey),
    );

    await loadCustomerInfo();
    await loadOfferings();

    // Écoute les changements d'entitlements (achat, expiration, restore)
    // INCHANGÉ : déjà présent dans le code actuel
    Purchases.addCustomerInfoUpdateListener((info) {
      customerInfo = info;
    });

    // NOUVEAU : refresh automatique des offerings toutes les 30 minutes.
    // Permet à une promo activée sur le Dashboard d'apparaître sans restart.
    _offeringsRefreshTimer?.cancel();
    _offeringsRefreshTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _silentRefreshOfferings(),
    );

    debugPrint('✅ RevenueCat initialized successfully');
  } on Exception catch (e) {
    debugPrint('❌ RevenueCat initialization failed: $e');
  }
}

// NOUVEAU : refresh silencieux (ne bloque pas l'UI)
Future<void> _silentRefreshOfferings() async {
  try {
    final fresh = await Purchases.getOfferings();
    final currentBefore = _offerings?.current?.identifier;
    _offerings = fresh;
    final currentAfter = fresh.current?.identifier;

    if (currentBefore != currentAfter) {
      // L'offering "current" a changé → promo activée ou désactivée
      debugPrint('🔔 Offering changed: $currentBefore → $currentAfter');
      onOfferingsChanged?.call(); // notifie l'UI si un callback est enregistré
    }
  } catch (_) {
    // Silencieux : ne pas perturber l'app si le réseau est absent
  }
}

// ─── Chargement des données ───────────────────────────────────

Future<void> loadOfferings() async {
  try {
    _offerings = await Purchases.getOfferings();
    debugPrint('✅ Offerings loaded: ${_offerings?.all.length ?? 0} offerings');
    debugPrint('   Current offering: ${_offerings?.current?.identifier ?? "none"}');

    // Log utile pour déboguer les promos actives
    _offerings?.all.forEach((key, offering) {
      debugPrint('   [$key] ${offering.availablePackages.length} packages'
          '${offering.identifier == _offerings?.current?.identifier ? " ← CURRENT" : ""}');
    });
  } on PlatformException catch (e) {
    debugPrint('❌ Error loading offerings: $e');
  }
}

// NOUVEAU : à appeler à l'ouverture de l'écran abonnement pour forcer
// un refresh et garantir que la dernière promo est visible
Future<void> forceRefreshOfferings() async {
  await loadOfferings();
  onOfferingsChanged?.call();
}

Future<void> loadCustomerInfo() async {
  try {
    _customerInfo = await Purchases.getCustomerInfo();
    debugPrint('✅ Customer info loaded');
  } on PlatformException catch (e) {
    debugPrint('❌ Error loading customer info: $e');
  }
}

// ─── Achat ───────────────────────────────────────────────────

// INCHANGÉ : utilise déjà offerings?.current → correct pour les promos
Future<bool> purchasePackage(String packageIdentifier) async {
  try {
    final pkg = offerings?.current?.getPackage(packageIdentifier);
    if (pkg == null) {
      debugPrint('⚠️ Package not found in current offering: $packageIdentifier');
      debugPrint('   Current offering: ${offerings?.current?.identifier}');
      return false;
    }

    final PurchaseResult result = await Purchases.purchasePackage(pkg);
    customerInfo = result.customerInfo;
    final bool success = result.customerInfo.entitlements.active.isNotEmpty;
    debugPrint(success ? '✅ Purchase successful' : '⚠️ Purchase incomplete');
    return success;
  } catch (e) {
    debugPrint('❌ Purchase error: $e');
    return false;
  }
}

// ─── Autres utilitaires (inchangés) ──────────────────────────

Future<bool?> isEntitled(String entitlementId) async {
  try {
    customerInfo = await Purchases.getCustomerInfo();
    return customerInfo!.entitlements.all[entitlementId]?.isActive ?? false;
  } on Exception catch (e) {
    debugPrint('❌ Unable to check RevenueCat entitlements: $e');
    return null;
  }
}

Future<void> login(String? uid) async {
  if (kIsWeb || uid == _loggedInUid) return;
  try {
    if (uid != null) {
      final LogInResult result = await Purchases.logIn(uid);
      customerInfo = result.customerInfo;
      debugPrint('✅ User logged in: $uid');
    } else {
      customerInfo = await Purchases.logOut();
      debugPrint('✅ User logged out');
    }
    _loggedInUid = uid;
  } on Exception catch (e) {
    debugPrint('❌ Unable to logIn or logOut: $e');
  }
}

Future<void> restorePurchases() async {
  try {
    customerInfo = await Purchases.restorePurchases();
    debugPrint('✅ Purchases restored');
  } on PlatformException catch (e) {
    debugPrint('❌ Unable to restore purchases: $e');
  }
}

// ─── À CHANGER aussi dans revenue_cat_service.dart ───────────
//
//  ACTUEL (problématique pour les promos) :
//    final defaultOffering = offerings!.all['default'] ?? offerings!.current;
//
//  PROPOSÉ (laisse RevenueCat décider quelle offre est "current") :
//    final currentOffering = offerings!.current;
//
//  Ainsi, si tu mets "promo_avril" en Current sur le Dashboard,
//  allAvailablePackages retourne automatiquement les packages promo.
//  Aucune ligne de code à toucher.
//
// ─────────────────────────────────────────────────────────────
