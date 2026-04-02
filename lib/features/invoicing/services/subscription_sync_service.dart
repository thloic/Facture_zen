// lib/services/subscription_sync_service.dart
import 'package:flutter/foundation.dart';
import '../../../common/services/firebase_invoice_service.dart';
import '../templates/invoice_template_base.dart';
import 'revenue_cat_service.dart';

class SubscriptionSyncService {
  final RevenueCatService _revenueCatService = RevenueCatService();
  final FirebaseInvoiceService _firebaseService = FirebaseInvoiceService();

  /// ✅ Map des limites de factures selon l'entitlement
  static const Map<String, SubscriptionPlan> PLAN_LIMITS = {
    'zen_gratuit':    SubscriptionPlan(name: 'Zen Gratuit',    monthlyInvoiceLimit: 3,   allowedTemplatesCount: 2,  isPremium: false),
    'zen_basic':      SubscriptionPlan(name: 'Zen Basic',      monthlyInvoiceLimit: 100, allowedTemplatesCount: 7,  isPremium: true),
    'zen_pro':        SubscriptionPlan(name: 'Zen Pro',        monthlyInvoiceLimit: 250, allowedTemplatesCount: -1, isPremium: true),
    'zen_entreprise': SubscriptionPlan(name: 'Zen Entreprise', monthlyInvoiceLimit: 5000, allowedTemplatesCount: -1, isPremium: true),
    'rent_up_pro':    SubscriptionPlan(name: 'Zen Pro',        monthlyInvoiceLimit: 250, allowedTemplatesCount: -1, isPremium: true),
  };

  String _resolvePlanKey(String normalizedId) {
    if (normalizedId.contains('basic'))     return 'zen_basic';
    if (normalizedId == 'zen_pro')          return 'zen_pro';
    if (normalizedId == 'rent_up_pro')      return 'rent_up_pro';
    if (normalizedId.contains('pro'))       return 'zen_pro';
    if (normalizedId.contains('entreprise') || 
        normalizedId.contains('enterprise')) return 'zen_entreprise';
    return normalizedId;
  }

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
          // Normaliser l'ID: "Zen Basic" → "zen_basic"
          final normalizedId = entitlementId
              .toLowerCase()
              .replaceAll(' ', '_')
              .replaceAll('-', '_');
          final planKey = _resolvePlanKey(normalizedId);
          debugPrint('📦 Checking entitlement: $entitlementId → $normalizedId → $planKey');
          final plan = PLAN_LIMITS[planKey];

          if (plan != null) {
            debugPrint('✅ Plan found: ${plan.name}');
            if (highestPlan == null ||
                plan.monthlyInvoiceLimit > highestPlan.monthlyInvoiceLimit) {
              highestPlan = plan;
            }
          } else {
            debugPrint('❌ Plan not found for: $planKey');
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
        allowedTemplatesCount: plan.allowedTemplatesCount, // ✅ NOUVEAU
      );

      debugPrint('✅ Firebase updated:');
      debugPrint('   Plan: ${plan.name}');
      debugPrint('   Limit: ${plan.monthlyInvoiceLimit} invoices/month');
      debugPrint('   Templates: ${plan.allowedTemplatesCount == -1 ? "Illimité" : plan.allowedTemplatesCount}');
      debugPrint('   Premium: ${plan.isPremium}');

    } catch (e) {
      debugPrint('❌ Error updating Firebase plan: $e');
      rethrow;
    }
  }

  Future<bool> canAccessTemplate(InvoiceTemplateType templateType) async {
    try {
      final plan = await getCurrentPlan();

      // Si illimité, tous les templates sont accessibles
      if (plan.allowedTemplatesCount == -1) {
        return true;
      }

      // Obtenir la liste des templates autorisés selon le plan
      final allowedTemplates = _getAllowedTemplates(plan.allowedTemplatesCount);

      return allowedTemplates.contains(templateType);
    } catch (e) {
      debugPrint('❌ Error checking template access: $e');
      return false;
    }
  }

  List<InvoiceTemplateType> _getAllowedTemplates(int count) {
    final allTemplates = InvoiceTemplateType.values;

    if (count == -1) {
      // Illimité : tous les templates
      return allTemplates;
    }

    // Retourner les N premiers templates
    return allTemplates.take(count).toList();
  }

  Future<List<InvoiceTemplateType>> getAccessibleTemplates() async {
    try {
      final plan = await getCurrentPlan();
      return _getAllowedTemplates(plan.allowedTemplatesCount);
    } catch (e) {
      debugPrint('❌ Error getting accessible templates: $e');
      return _getAllowedTemplates(2); // Par défaut : plan gratuit
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
        // ✅ Même normalisation que syncSubscriptionStatus()
        final normalizedId = entitlementId
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll('-', '_');
        final planKey = _resolvePlanKey(normalizedId);
        debugPrint('🔍 getCurrentPlan: $entitlementId → $planKey');
        final plan = PLAN_LIMITS[planKey];

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
  final int allowedTemplatesCount;
  final bool isPremium;

  const SubscriptionPlan({
    required this.name,
    required this.monthlyInvoiceLimit,
    required this.allowedTemplatesCount,
    required this.isPremium,
  });
}