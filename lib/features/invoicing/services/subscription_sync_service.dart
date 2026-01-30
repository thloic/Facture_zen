// lib/services/subscription_sync_service.dart
import 'package:flutter/foundation.dart';
import '../../../common/services/firebase_invoice_service.dart';
import 'revenue_cat_service.dart';

class SubscriptionSyncService {
  final RevenueCatService _revenueCatService = RevenueCatService();
  final FirebaseInvoiceService _firebaseService = FirebaseInvoiceService();

  /// ✅ Map des limites de factures selon l'entitlement
  static const Map<String, SubscriptionPlan> PLAN_LIMITS = {
    'zen_gratuit': SubscriptionPlan(
      name: 'Zen Gratuit',
      monthlyInvoiceLimit: 10,
      isPremium: false,
    ),
    'zen_basic': SubscriptionPlan(
      name: 'Zen Basic',
      monthlyInvoiceLimit: 250,
      isPremium: true,
    ),
    'zen_pro': SubscriptionPlan(
      name: 'Zen Pro',
      monthlyInvoiceLimit: 1500,
      isPremium: true,
    ),
    'zen_enterprise': SubscriptionPlan(
      name: 'Zen Enterprise',
      monthlyInvoiceLimit: 3500,
      isPremium: true,
    ),
  };

  /// ✅ Synchroniser le statut d'abonnement avec Firebase
  Future<void> syncSubscriptionStatus() async {
    try {
      debugPrint('🔄 Syncing subscription status...');

      // 1. Récupérer les infos client de RevenueCat
      await _revenueCatService.loadCustomerInfo();
      final customerInfo = _revenueCatService.customerInfo;

      if (customerInfo == null) {
        debugPrint('⚠️ No customer info available');
        return;
      }

      // 2. Vérifier les entitlements actifs
      final activeEntitlements = customerInfo.entitlements.active;

      debugPrint('📊 Active entitlements: ${activeEntitlements.keys.join(", ")}');

      if (activeEntitlements.isEmpty) {
        // Aucun abonnement actif = plan gratuit
        await _updateFirebasePlan(PLAN_LIMITS['zen_gratuit']!);
        debugPrint('✅ User set to FREE plan');
      } else {
        // Trouver le plan le plus élevé parmi les entitlements actifs
        SubscriptionPlan? highestPlan;

        for (var entitlementId in activeEntitlements.keys) {
          final plan = PLAN_LIMITS[entitlementId];

          if (plan != null) {
            if (highestPlan == null ||
                plan.monthlyInvoiceLimit > highestPlan.monthlyInvoiceLimit) {
              highestPlan = plan;
            }
          }
        }

        if (highestPlan != null) {
          await _updateFirebasePlan(highestPlan);
          debugPrint('✅ User upgraded to: ${highestPlan.name}');
        } else {
          debugPrint('⚠️ Unknown entitlement, defaulting to FREE');
          await _updateFirebasePlan(PLAN_LIMITS['zen_gratuit']!);
        }
      }

    } catch (e) {
      debugPrint('❌ Error syncing subscription: $e');
    }
  }

  /// ✅ Mettre à jour le plan dans Firebase
  Future<void> _updateFirebasePlan(SubscriptionPlan plan) async {
    try {
      final userId = _firebaseService.currentUser?.uid;
      if (userId == null) return;

      // Mettre à jour Firebase avec le nouveau plan
      await _firebaseService.updateUserPlan(
        isPremium: plan.isPremium,
        monthlyInvoiceLimit: plan.monthlyInvoiceLimit,
        planName: plan.name,
      );

      debugPrint('✅ Firebase updated:');
      debugPrint('   Plan: ${plan.name}');
      debugPrint('   Limit: ${plan.monthlyInvoiceLimit} invoices/month');
      debugPrint('   Premium: ${plan.isPremium}');

    } catch (e) {
      debugPrint('❌ Error updating Firebase plan: $e');
      rethrow;
    }
  }

  /// ✅ Obtenir le plan actuel de l'utilisateur
  Future<SubscriptionPlan> getCurrentPlan() async {
    try {
      await _revenueCatService.loadCustomerInfo();
      final customerInfo = _revenueCatService.customerInfo;

      if (customerInfo == null || customerInfo.entitlements.active.isEmpty) {
        return PLAN_LIMITS['zen_gratuit']!;
      }

      // Trouver le plan le plus élevé
      SubscriptionPlan? highestPlan;

      for (var entitlementId in customerInfo.entitlements.active.keys) {
        final plan = PLAN_LIMITS[entitlementId];

        if (plan != null) {
          if (highestPlan == null ||
              plan.monthlyInvoiceLimit > highestPlan.monthlyInvoiceLimit) {
            highestPlan = plan;
          }
        }
      }

      return highestPlan ?? PLAN_LIMITS['zen_gratuit']!;

    } catch (e) {
      debugPrint('❌ Error getting current plan: $e');
      return PLAN_LIMITS['zen_gratuit']!;
    }
  }
}

/// Classe pour définir un plan d'abonnement
class SubscriptionPlan {
  final String name;
  final int monthlyInvoiceLimit;
  final bool isPremium;

  const SubscriptionPlan({
    required this.name,
    required this.monthlyInvoiceLimit,
    required this.isPremium,
  });
}