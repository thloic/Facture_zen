import 'package:flutter_test/flutter_test.dart';

/// Teste la logique de détection de promotion
/// utilisée dans SubscriptionViewModel.isPromoActive et currentPromoLabel
///
/// La logique est : isPromoActive = true UNIQUEMENT si l'identifier
/// de l'offering courante contient le mot "promo" (case-insensitive)
void main() {
  // ─── Reproduit la logique de isPromoActive (Source 1 : RevenueCat) ─────

  bool isPromoActiveFromOffering(String? currentId) {
    if (currentId != null && currentId.toLowerCase().contains('promo')) {
      return true;
    }
    return false;
  }

  // ─── Reproduit la logique de currentPromoLabel ─────────────────────────

  String currentPromoLabelFromOffering(String currentId) {
    if (currentId.isNotEmpty && currentId.toLowerCase().contains('promo')) {
      return currentId
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
    }
    return 'Offre spéciale';
  }

  // ─── Tests isPromoActive ──────────────────────────────────────────────

  group('isPromoActive - détection par offering identifier', () {
    test('null → pas de promo', () {
      expect(isPromoActiveFromOffering(null), false);
    });

    test('"default" → pas de promo', () {
      expect(isPromoActiveFromOffering('default'), false);
    });

    test('"nouveaux_prix_base" → PAS de promo (pas de mot "promo")', () {
      expect(isPromoActiveFromOffering('nouveaux_prix_base'), false);
    });

    test('"zen-basic-monthly-offer" → PAS de promo', () {
      expect(isPromoActiveFromOffering('zen-basic-monthly-offer'), false);
    });

    test('"zen-pro-monthly-offer" → PAS de promo (contient "pro" mais pas "promo")', () {
      expect(isPromoActiveFromOffering('zen-pro-monthly-offer'), false);
    });

    test('"promo_avril" → promo détectée', () {
      expect(isPromoActiveFromOffering('promo_avril'), true);
    });

    test('"promo_noel_2026" → promo détectée', () {
      expect(isPromoActiveFromOffering('promo_noel_2026'), true);
    });

    test('"offre_promo_ete" → promo détectée', () {
      expect(isPromoActiveFromOffering('offre_promo_ete'), true);
    });

    test('"PROMO_LANCEMENT" (majuscules) → promo détectée', () {
      expect(isPromoActiveFromOffering('PROMO_LANCEMENT'), true);
    });

    test('"Promo-Black-Friday" → promo détectée', () {
      expect(isPromoActiveFromOffering('Promo-Black-Friday'), true);
    });
  });

  // ─── Tests currentPromoLabel ─────────────────────────────────────────

  group('currentPromoLabel - génération du label', () {
    test('"promo_avril" → "Promo Avril"', () {
      expect(currentPromoLabelFromOffering('promo_avril'), 'Promo Avril');
    });

    test('"promo_noel_2026" → "Promo Noel 2026"', () {
      expect(currentPromoLabelFromOffering('promo_noel_2026'), 'Promo Noel 2026');
    });

    test('"promo_ete" → "Promo Ete"', () {
      expect(currentPromoLabelFromOffering('promo_ete'), 'Promo Ete');
    });

    test('offering sans "promo" → "Offre spéciale" (fallback)', () {
      expect(currentPromoLabelFromOffering('nouveaux_prix_base'), 'Offre spéciale');
    });

    test('string vide → "Offre spéciale"', () {
      expect(currentPromoLabelFromOffering(''), 'Offre spéciale');
    });
  });

  // ─── Edge cases ──────────────────────────────────────────────────────

  group('Edge cases - mot "promo" vs "pro"', () {
    test('"pro" seul ne déclenche PAS la promo', () {
      expect(isPromoActiveFromOffering('pro'), false);
    });

    test('"promo" seul déclenche la promo', () {
      expect(isPromoActiveFromOffering('promo'), true);
    });

    test('"promotion" contient "promo" → déclenche la promo', () {
      expect(isPromoActiveFromOffering('promotion_speciale'), true);
    });

    test('"zen_pro_monthly" ne contient PAS "promo"', () {
      expect(isPromoActiveFromOffering('zen_pro_monthly'), false);
    });
  });
}
