# Correction du filigrane "Généré avec VoxIn"

## Résumé

Le filigrane "Généré avec VoxIn" devait s'afficher uniquement pour les utilisateurs gratuits et Basic, mais **3 bugs** empêchaient sa suppression correcte sur les forfaits Pro et Entreprise.

---

## Bugs corrigés

### Bug 1 (Critique) — `pdf_generator_service.dart`

**Problème :** Le footer du PDF affichait le filigrane **systématiquement**, sans aucune vérification du statut premium. Tous les utilisateurs — gratuits ou payants — voyaient "Généré avec VoxIn" sur leurs factures générées par ce service.

**Correction :**
- Ajout du paramètre `{bool isPremium = false}` à `generateInvoicePdf()`, `_buildInvoicePage()` et `_buildFooter()`
- Le filigrane est maintenant conditionné par `if (!isPremium)`

---

### Bug 2 (Critique) — `invoice_preview_screen.dart`

**Problème :** L'écran de prévisualisation des factures n'avait **aucune référence** à `PremiumProvider`. Il appelait :
- `template.buildInvoice(context, _invoice)` → sans `isPremium` → défaut `false` → filigrane toujours visible
- `PdfTemplateFactory.generatePdfWithLogo(...)` → sans `isPremium` → défaut `false` → filigrane dans le PDF

Les utilisateurs Pro/Entreprise voyaient toujours le filigrane sur la prévisualisation et dans le PDF exporté.

**Correction :**
- Import de `PremiumProvider`
- Passage de `isPremium: context.read<PremiumProvider>().isPremium` aux deux appels

---

### Bug 3 (Mineur) — `invoice_history_screen.dart`

**Problème :** L'écran d'historique des factures chargeait le statut premium via un appel asynchrone à **Firebase** (`_invoiceService.isPremiumUser()`), qui pouvait être périmé si la sync RevenueCat → Firebase n'avait pas encore eu lieu.

De plus, cela causait un flash visuel : le filigrane apparaissait brièvement puis disparaissait après le retour de l'appel async.

**Correction :**
- Remplacement par `context.read<PremiumProvider>().isPremium` (synchrone, toujours à jour via le listener RevenueCat)
- Suppression du code async `_loadPremiumStatus()` et du `FirebaseInvoiceService` inutile

---

## Changement bonus — Plan Pro : 250 → 500 factures

Mis à jour dans :
- `subscription_sync_service.dart` : `PLAN_LIMITS['zen_pro']` et `PLAN_LIMITS['rent_up_pro']`
- `premium_provider.dart` : `_invoiceLimit = 500` pour les entitlements contenant "pro"
- `subscription_screen.dart` : affichage "500 factures/mois" + ajout "Sans filigrane VoxIn" pour Pro et Entreprise

---

## Fichiers modifiés

| Fichier | Modification |
|---------|-------------|
| `lib/features/invoicing/services/pdf_generator_service.dart` | Ajout `isPremium` + condition `if (!isPremium)` sur le filigrane |
| `lib/features/invoicing/views/invoice_preview_screen.dart` | Import `PremiumProvider` + passage `isPremium` à template et PDF |
| `lib/features/invoicing/views/invoice_history_screen.dart` | Remplacement Firebase async par `PremiumProvider` synchrone |
| `lib/common/providers/premium_provider.dart` | Pro : 250 → 500 factures |
| `lib/features/invoicing/services/subscription_sync_service.dart` | Pro : 250 → 500 factures |
| `lib/features/invoicing/views/subscription_screen.dart` | "500 factures/mois" + "Sans filigrane VoxIn" (Pro & Entreprise) |

---

## Comportement attendu après correction

| Plan | Filigrane sur prévisualisation | Filigrane sur PDF | Limite factures |
|------|-------------------------------|-------------------|-----------------|
| Zen Gratuit | ✅ Visible | ✅ Visible | 3/mois |
| Zen Basic | ❌ Masqué | ❌ Masqué | 100/mois |
| Zen Pro | ❌ Masqué | ❌ Masqué | 500/mois |
| Zen Entreprise | ❌ Masqué | ❌ Masqué | 5000/mois |

---

## Date

7 avril 2026
