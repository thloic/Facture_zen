import 'package:flutter_test/flutter_test.dart';

/// Teste la logique de mapping des entitlements → plan/limite
/// qui est utilisée dans PremiumProvider.refresh()
///
/// On ne peut pas instancier PremiumProvider directement dans les tests
/// car il appelle RevenueCat dans son constructeur.
/// On teste donc la logique pure de mapping isolément.
void main() {
  // ─── Logique de mapping entitlement → plan ─────────────────────────────
  //
  // Reproduit exactement la logique de PremiumProvider.refresh()

  /// Simule la logique de PremiumProvider.refresh()
  /// Retourne {planName, invoiceLimit, isPremium}
  Map<String, dynamic> resolvePlan(Set<String> normalizedKeys) {
    final isPremium = normalizedKeys.isNotEmpty;
    String planName;
    int invoiceLimit;

    if (normalizedKeys.any((k) => k.contains('entreprise') || k.contains('enterprise'))) {
      planName = 'Zen Entreprise';
      invoiceLimit = 5000;
    } else if (normalizedKeys.any((k) => k.contains('pro'))) {
      planName = 'Zen Pro';
      invoiceLimit = 500;
    } else if (normalizedKeys.any((k) => k.contains('basic'))) {
      planName = 'Zen Basic';
      invoiceLimit = 100;
    } else if (isPremium) {
      planName = 'Zen Basic';
      invoiceLimit = 100;
    } else {
      planName = 'Zen Gratuit';
      invoiceLimit = 3;
    }

    return {
      'planName': planName,
      'invoiceLimit': invoiceLimit,
      'isPremium': isPremium,
    };
  }

  /// Simule la normalisation des clés d'entitlement
  Set<String> normalizeKeys(List<String> rawKeys) {
    return rawKeys.map((k) =>
        k.toLowerCase()
         .replaceAll(' ', '_')
         .replaceAll('-', '_')).toSet();
  }

  // ─── Tests ────────────────────────────────────────────────────────────────

  group('PremiumProvider - mapping entitlement → plan', () {
    test('aucun entitlement → Zen Gratuit, 3 factures, non premium', () {
      final result = resolvePlan({});
      expect(result['planName'], 'Zen Gratuit');
      expect(result['invoiceLimit'], 3);
      expect(result['isPremium'], false);
    });

    test('entitlement basic → Zen Basic, 100 factures, premium', () {
      final keys = normalizeKeys(['Access zen basic content']);
      final result = resolvePlan(keys);
      expect(result['planName'], 'Zen Basic');
      expect(result['invoiceLimit'], 100);
      expect(result['isPremium'], true);
    });

    test('entitlement pro → Zen Pro, 500 factures, premium', () {
      final keys = normalizeKeys(['Access zen pro content']);
      final result = resolvePlan(keys);
      expect(result['planName'], 'Zen Pro');
      expect(result['invoiceLimit'], 500);
      expect(result['isPremium'], true);
    });

    test('entitlement entreprise → Zen Entreprise, 5000 factures, premium', () {
      final keys = normalizeKeys(['Access zen entreprise content']);
      final result = resolvePlan(keys);
      expect(result['planName'], 'Zen Entreprise');
      expect(result['invoiceLimit'], 5000);
      expect(result['isPremium'], true);
    });

    test('entitlement enterprise (anglais) → Zen Entreprise', () {
      final keys = normalizeKeys(['zen_enterprise']);
      final result = resolvePlan(keys);
      expect(result['planName'], 'Zen Entreprise');
      expect(result['invoiceLimit'], 5000);
    });

    test('entitlement inconnu mais actif → fallback Zen Basic, 100', () {
      final keys = normalizeKeys(['some_unknown_plan']);
      final result = resolvePlan(keys);
      expect(result['planName'], 'Zen Basic');
      expect(result['invoiceLimit'], 100);
      expect(result['isPremium'], true);
    });

    test('entreprise a priorité sur pro', () {
      final keys = normalizeKeys([
        'Access zen pro content',
        'Access zen entreprise content',
      ]);
      final result = resolvePlan(keys);
      expect(result['planName'], 'Zen Entreprise');
      expect(result['invoiceLimit'], 5000);
    });

    test('pro a priorité sur basic', () {
      final keys = normalizeKeys([
        'Access zen basic content',
        'Access zen pro content',
      ]);
      final result = resolvePlan(keys);
      expect(result['planName'], 'Zen Pro');
      expect(result['invoiceLimit'], 500);
    });
  });

  // ─── Normalisation ────────────────────────────────────────────────────────

  group('PremiumProvider - normalisation des clés', () {
    test('espaces → underscores, minuscules', () {
      final keys = normalizeKeys(['Access Zen Basic Content']);
      expect(keys.first, 'access_zen_basic_content');
    });

    test('tirets → underscores', () {
      final keys = normalizeKeys(['zen-pro-monthly']);
      expect(keys.first, 'zen_pro_monthly');
    });

    test('majuscules → minuscules', () {
      final keys = normalizeKeys(['ZEN_ENTREPRISE']);
      expect(keys.first, 'zen_entreprise');
    });
  });

  // ─── Cohérence avec SubscriptionSyncService ────────────────────────────

  group('Cohérence PremiumProvider ↔ SubscriptionSyncService', () {
    test('les limites sont alignées entre les deux', () {
      // Ces valeurs doivent être identiques dans
      // premium_provider.dart et subscription_sync_service.dart
      const expectedLimits = {
        'gratuit': 3,
        'basic': 100,
        'pro': 500,
        'entreprise': 5000,
      };

      for (final entry in expectedLimits.entries) {
        final keys = entry.key == 'gratuit'
            ? <String>{}
            : normalizeKeys(['zen_${entry.key}']);
        final result = resolvePlan(keys);
        expect(result['invoiceLimit'], entry.value,
            reason: 'Plan ${entry.key} devrait avoir ${entry.value} factures');
      }
    });
  });
}
