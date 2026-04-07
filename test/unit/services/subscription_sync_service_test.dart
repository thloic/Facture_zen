import 'package:flutter_test/flutter_test.dart';
import 'package:facture_zen/features/invoicing/services/subscription_sync_service.dart';

/// Teste la logique pure de SubscriptionSyncService
/// sans instancier le service (qui dépend de Firebase/RevenueCat)
void main() {
  // ─── PLAN_LIMITS (constantes statiques, pas besoin d'instance) ─────────

  group('PLAN_LIMITS', () {
    test('zen_gratuit a 3 factures, non premium', () {
      final plan = SubscriptionSyncService.PLAN_LIMITS['zen_gratuit']!;
      expect(plan.monthlyInvoiceLimit, 3);
      expect(plan.isPremium, false);
      expect(plan.allowedTemplatesCount, 2);
    });

    test('zen_basic a 100 factures, premium', () {
      final plan = SubscriptionSyncService.PLAN_LIMITS['zen_basic']!;
      expect(plan.monthlyInvoiceLimit, 100);
      expect(plan.isPremium, true);
      expect(plan.allowedTemplatesCount, 7);
    });

    test('zen_pro a 500 factures, premium', () {
      final plan = SubscriptionSyncService.PLAN_LIMITS['zen_pro']!;
      expect(plan.monthlyInvoiceLimit, 500);
      expect(plan.isPremium, true);
      expect(plan.allowedTemplatesCount, -1);
    });

    test('zen_entreprise a 5000 factures, premium', () {
      final plan = SubscriptionSyncService.PLAN_LIMITS['zen_entreprise']!;
      expect(plan.monthlyInvoiceLimit, 5000);
      expect(plan.isPremium, true);
      expect(plan.allowedTemplatesCount, -1);
    });

    test('rent_up_pro a 500 factures, premium', () {
      final plan = SubscriptionSyncService.PLAN_LIMITS['rent_up_pro']!;
      expect(plan.monthlyInvoiceLimit, 500);
      expect(plan.isPremium, true);
    });

    test('hiérarchie des limites : gratuit < basic < pro < entreprise', () {
      final gratuit = SubscriptionSyncService.PLAN_LIMITS['zen_gratuit']!;
      final basic = SubscriptionSyncService.PLAN_LIMITS['zen_basic']!;
      final pro = SubscriptionSyncService.PLAN_LIMITS['zen_pro']!;
      final entreprise = SubscriptionSyncService.PLAN_LIMITS['zen_entreprise']!;

      expect(gratuit.monthlyInvoiceLimit < basic.monthlyInvoiceLimit, true);
      expect(basic.monthlyInvoiceLimit < pro.monthlyInvoiceLimit, true);
      expect(pro.monthlyInvoiceLimit < entreprise.monthlyInvoiceLimit, true);
    });

    test('tous les plans premium ont isPremium = true', () {
      for (final key in ['zen_basic', 'zen_pro', 'zen_entreprise', 'rent_up_pro']) {
        final plan = SubscriptionSyncService.PLAN_LIMITS[key]!;
        expect(plan.isPremium, true, reason: '$key devrait être premium');
      }
    });

    test('seul zen_gratuit a isPremium = false', () {
      expect(SubscriptionSyncService.PLAN_LIMITS['zen_gratuit']!.isPremium, false);
    });
  });

  // ─── resolvePlanKey (logique reproduite, identique au code source) ─────

  /// Reproduit exactement la logique de resolvePlanKey
  String resolvePlanKey(String normalizedId) {
    if (normalizedId.contains('basic'))     return 'zen_basic';
    if (normalizedId == 'zen_pro')          return 'zen_pro';
    if (normalizedId == 'rent_up_pro')      return 'rent_up_pro';
    if (normalizedId.contains('pro'))       return 'zen_pro';
    if (normalizedId.contains('entreprise') || 
        normalizedId.contains('enterprise')) return 'zen_entreprise';
    return normalizedId;
  }

  group('resolvePlanKey', () {
    test('contient "basic" → zen_basic', () {
      expect(resolvePlanKey('zen_basic'), 'zen_basic');
      expect(resolvePlanKey('access_zen_basic_content'), 'zen_basic');
      expect(resolvePlanKey('basic_monthly'), 'zen_basic');
    });

    test('"zen_pro" exact → zen_pro', () {
      expect(resolvePlanKey('zen_pro'), 'zen_pro');
    });

    test('"rent_up_pro" exact → rent_up_pro', () {
      expect(resolvePlanKey('rent_up_pro'), 'rent_up_pro');
    });

    test('contient "pro" (mais pas basic) → zen_pro', () {
      expect(resolvePlanKey('access_zen_pro_content'), 'zen_pro');
      expect(resolvePlanKey('pro_monthly'), 'zen_pro');
    });

    test('contient "entreprise" → zen_entreprise', () {
      expect(resolvePlanKey('zen_entreprise'), 'zen_entreprise');
      expect(resolvePlanKey('access_zen_entreprise_content'), 'zen_entreprise');
    });

    test('contient "enterprise" (anglais) → zen_entreprise', () {
      expect(resolvePlanKey('zen_enterprise'), 'zen_entreprise');
    });

    test('entitlement RevenueCat réel normalisé', () {
      final raw = 'Access zen basic content';
      final normalized = raw.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
      expect(resolvePlanKey(normalized), 'zen_basic');
    });

    test('entitlement inconnu retourne la clé telle quelle', () {
      expect(resolvePlanKey('unknown_plan'), 'unknown_plan');
    });

    test('"basic" a priorité sur "pro" quand les deux sont présents', () {
      expect(resolvePlanKey('basic_pro'), 'zen_basic');
    });
  });

  // ─── Normalisation des entitlements ────────────────────────────────────

  group('Normalisation des entitlements', () {
    String normalize(String raw) {
      return raw.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    }

    test('espaces convertis en underscores', () {
      expect(normalize('Zen Basic'), 'zen_basic');
      expect(normalize('Access zen basic content'), 'access_zen_basic_content');
    });

    test('tirets convertis en underscores', () {
      expect(normalize('zen-pro'), 'zen_pro');
    });

    test('majuscules converties en minuscules', () {
      expect(normalize('ZEN_PRO'), 'zen_pro');
    });

    test('bout en bout : normalisation + resolvePlanKey', () {
      final testCases = {
        'Access zen basic content': 'zen_basic',
        'Access zen pro content': 'zen_pro',
        'Access zen entreprise content': 'zen_entreprise',
        'Zen Basic': 'zen_basic',
        'Zen-Pro': 'zen_pro',
        'ZEN_ENTREPRISE': 'zen_entreprise',
      };

      for (final entry in testCases.entries) {
        final normalized = normalize(entry.key);
        final result = resolvePlanKey(normalized);
        expect(result, entry.value,
            reason: '"${entry.key}" → "$normalized" → devrait être "${entry.value}"');
      }
    });
  });

  // ─── SubscriptionPlan ─────────────────────────────────────────────────

  group('SubscriptionPlan', () {
    test('peut être créé avec const', () {
      const plan = SubscriptionPlan(
        name: 'Test',
        monthlyInvoiceLimit: 10,
        allowedTemplatesCount: 5,
        isPremium: true,
      );
      expect(plan.name, 'Test');
      expect(plan.monthlyInvoiceLimit, 10);
      expect(plan.allowedTemplatesCount, 5);
      expect(plan.isPremium, true);
    });
  });
}
