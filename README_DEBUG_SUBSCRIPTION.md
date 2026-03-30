# 🐛 VoxIn — Rapport de bugs & corrections
> Session de debug du 29 mars 2026  
> Stack : Flutter · Firebase Realtime Database · RevenueCat · Provider

---

## Vue d'ensemble

Trois problèmes distincts ont été identifiés et corrigés dans l'application VoxIn. Ce document explique **ce qui ne marchait pas**, **pourquoi**, et **ce qu'on a changé**.

---

## 🔴 Problème 1 — L'UI ne se met pas à jour après un abonnement

### Ce que l'utilisateur voyait
L'utilisateur prenait un abonnement. RevenueCat confirmait l'achat (visible dans le dashboard : 1 active subscription, $23 MRR). La limite de factures augmentait bien dans Firebase. **Mais l'interface restait bloquée sur le mode gratuit.** L'utilisateur devait relancer l'app pour voir les changements.

---

### Cause racine — Le `bool _isPremium` local

Dans `invoice_final_screen.dart`, le statut premium était stocké dans une variable locale :

```dart
// ❌ AVANT — Variable locale chargée UNE SEULE FOIS au démarrage
bool _isPremium = false;

Future<void> _loadUserProfile() async {
  final remainingInvoices = await _invoiceService.getRemainingInvoices();
  _isPremium = remainingInvoices == -1; // Chargé une fois, jamais mis à jour
}
```

**Le problème :** Cette variable était lue au `initState()` de l'écran. Après l'achat, l'écran n'était pas reconstruit — la variable restait `false` pour toujours jusqu'au redémarrage de l'app.

De plus, quand on naviguait vers `SubscriptionScreen` :

```dart
// ❌ AVANT — On ouvrait l'écran mais on n'écoutait pas le retour
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SubscriptionScreen(...),
  ),
);
// Aucun .then() → _isPremium ne se met jamais à jour
```

---

### Cause racine — Pas de listener global RevenueCat

RevenueCat fournit un listener `addCustomerInfoUpdateListener` qui se déclenche automatiquement quand un achat est confirmé. **Ce listener n'était connecté à aucun état global de l'app.** Il mettait à jour une variable globale `_customerInfo` dans `revenue_cat_util.dart`, mais aucun widget n'était abonné à ce changement.

```
Achat confirmé → RevenueCat notifie → _customerInfo mis à jour ✅
                                    → AUCUN widget reconstruit ❌
```

---

### La solution — `PremiumProvider` global

On a créé un `ChangeNotifier` global qui :
1. S'initialise au démarrage de l'app
2. Écoute RevenueCat en temps réel
3. Notifie **tous** les widgets abonnés automatiquement

```dart
// ✅ APRÈS — lib/common/providers/premium_provider.dart
class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  String _planName = 'Zen Gratuit';
  int _invoiceLimit = 3;

  PremiumProvider() {
    _init();
  }

  Future<void> _init() async {
    await refresh(); // Charge l'état initial

    // Écoute RevenueCat — se déclenche automatiquement après chaque achat
    Purchases.addCustomerInfoUpdateListener((info) async {
      rc_util.customerInfo = info;
      await refresh(); // ← Tous les widgets se reconstruisent
    });
  }
}
```

Ajouté en première position dans `MultiProvider` dans `main.dart` :

```dart
ChangeNotifierProvider(create: (_) => PremiumProvider()), // ← Premier
```

**Résultat :** Dès que l'achat est confirmé par RevenueCat, `PremiumProvider.refresh()` est appelé, `notifyListeners()` se déclenche, et **toute l'UI se reconstruit automatiquement** sans gérer de navigation, de `.then()`, ou de `setState()` manuel.

---

### Cause racine — Le compteur de factures ne se réinitialisait jamais

Dans `firebase_invoice_service.dart`, la logique de limite utilisait un compteur **global** qui ne se remettait jamais à zéro :

```dart
// ❌ AVANT — Compteur total depuis la création du compte
static const String TOTAL_INVOICES_CREATED_KEY = 'totalInvoicesCreated';

Future<bool> canCreateInvoice() async {
  final totalInvoicesCreated = userData['totalInvoicesCreated'] as int? ?? 0;
  
  if (isPremium) {
    return totalInvoicesCreated < monthlyLimit;
    // ❌ Un utilisateur Basic avec 20 factures créées depuis 3 mois
    // sera bloqué dès le premier jour du mois suivant !
  }
}
```

**Le problème concret :** Un utilisateur Basic (15 factures/mois) qui avait créé 20 factures au total depuis son inscription était bloqué définitivement, même s'il n'avait créé que 5 factures ce mois-ci.

---

### La solution — Compteur mensuel automatique

On a remplacé le compteur global par un compteur **mensuel** dont la clé change automatiquement chaque mois :

```dart
// ✅ APRÈS — Clé qui change chaque mois automatiquement
static String get _monthlyCountKey {
  final now = DateTime.now();
  return 'invoiceCount_${now.year}_${now.month}';
  // Janvier 2026 → "invoiceCount_2026_1"
  // Février 2026 → "invoiceCount_2026_2"  ← nouvelle clé = compteur repart à 0
  // Mars 2026    → "invoiceCount_2026_3"
}

Future<bool> canCreateInvoice() async {
  final monthlyCount = userData[_monthlyCountKey] as int? ?? 0;
  
  if (isPremium) {
    return monthlyCount < monthlyLimit; // ✅ Seulement ce mois
  }
  return monthlyCount < FREE_INVOICE_LIMIT;
}
```

**Pas de migration nécessaire** : les anciens utilisateurs ont leur nouveau compteur mensuel à 0, ils repartent proprement.

---

### Cause racine — Les entitlements RevenueCat mal mappés

RevenueCat renvoie les identifiants d'entitlements exactement tels qu'ils sont configurés dans le dashboard. Les entitlements réels de VoxIn sont :

| Identifiant RevenueCat | Ce que le code attendait | Résultat |
|---|---|---|
| `Zen Basic` | `zen_basic` | ✅ Match après normalisation |
| `Zen pro` | `zen_pro` | ✅ Match après normalisation |
| `Zen Entreprise` | `zen_enterprise` | ❌ `zen_entreprise` ≠ `zen_enterprise` |
| `rent up Pro` | — | ❌ Aucune entrée dans PLAN_LIMITS |

**Le problème :** Un utilisateur `Zen Entreprise` ou `rent up Pro` était traité comme **utilisateur gratuit** malgré un paiement réussi.

De plus, dans `getCurrentPlan()`, la normalisation des clés n'était pas appliquée :

```dart
// ❌ AVANT — Pas de normalisation dans getCurrentPlan()
for (var entitlementId in customerInfo.entitlements.active.keys) {
  final plan = PLAN_LIMITS[entitlementId];
  // "Zen Basic" ne matche jamais "zen_basic" → retourne plan gratuit
}
```

---

### La solution — `_resolvePlanKey()` et normalisation uniforme

On a créé une fonction de résolution qui couvre toutes les variantes :

```dart
// ✅ APRÈS — subscription_sync_service.dart
static const Map<String, SubscriptionPlan> PLAN_LIMITS = {
  'zen_gratuit':    SubscriptionPlan(name: 'Zen Gratuit',    monthlyInvoiceLimit: 3,   ...),
  'zen_basic':      SubscriptionPlan(name: 'Zen Basic',      monthlyInvoiceLimit: 15,  ...),
  'zen_pro':        SubscriptionPlan(name: 'Zen Pro',        monthlyInvoiceLimit: 300, ...),
  'zen_entreprise': SubscriptionPlan(name: 'Zen Entreprise', monthlyInvoiceLimit: 750, ...),
  'rent_up_pro':    SubscriptionPlan(name: 'Zen Pro',        monthlyInvoiceLimit: 300, ...),
};

String _resolvePlanKey(String normalizedId) {
  if (normalizedId.contains('basic'))                              return 'zen_basic';
  if (normalizedId == 'zen_pro')                                   return 'zen_pro';
  if (normalizedId == 'rent_up_pro')                               return 'rent_up_pro';
  if (normalizedId.contains('pro'))                                return 'zen_pro';
  if (normalizedId.contains('entreprise') || 
      normalizedId.contains('enterprise'))                         return 'zen_entreprise';
  return normalizedId;
}
```

Appliqué de manière **identique** dans `syncSubscriptionStatus()`, `getCurrentPlan()`, et `PremiumProvider.refresh()`.

---

## 📁 Fichiers modifiés — Problème 1

| Fichier | Modification |
|---|---|
| `lib/common/providers/premium_provider.dart` | **Créé** — Provider global avec listener RevenueCat |
| `main.dart` | Ajout de `PremiumProvider` dans `MultiProvider` |
| `invoice_final_screen.dart` | Suppression de `bool _isPremium` local, remplacement par `context.read<PremiumProvider>()` |
| `firebase_invoice_service.dart` | Compteur mensuel `_monthlyCountKey`, correction de `canCreateInvoice()` et `getRemainingInvoices()` |
| `subscription_sync_service.dart` | `PLAN_LIMITS` mis à jour, `_resolvePlanKey()` ajouté, `getCurrentPlan()` corrigé |
| `premium_provider.dart` | Détection des entitlements par `contains()` au lieu d'égalité stricte |
| `subscription_view_model.dart` | Nouveau copywriting dans `getPlanInfo()`, `rent_up` couvert |

---

## 🟡 Problème 2 — Code PIN optionnel pour tous

### Ce que l'utilisateur vivait
Le code PIN était créé obligatoirement à la création du compte. Il n'existait pas de moyen simple de le désactiver depuis les paramètres.

### Ce qui est attendu
- PIN créé à la création du compte (déjà en place ✅)
- Dans les paramètres : un **toggle** pour activer/désactiver le PIN
- Accessible à tous les utilisateurs, gratuits et premium

### Statut
⏳ **À implémenter** — nécessite `pin_service.dart` et l'écran paramètres

---

## 🟠 Problème 3 — Publicités Facebook ne fonctionnent pas

### Ce que le dashboard montrait
Facebook Ads affichait : *"Mettez vos applications à jour vers le dernier SDK Facebook"*

- Tâche 1 (Mettre à jour le SDK iOS) : ✅ Cochée
- Tâche 2 (Publier l'app) : ❌ Non cochée

### Cause probable
La mise à jour du SDK Facebook a été faite dans le code **mais l'app n'a pas été soumise à l'App Store** avec cette mise à jour. Facebook ne peut pas confirmer que le SDK est actif en production tant qu'une version de l'app incluant le nouveau SDK n'est pas live.

### Statut
⏳ **À traiter** — nécessite une soumission App Store avec la nouvelle version

---

## 📊 Schéma du flux corrigé — Problème 1

```
AVANT (cassé)
─────────────
Achat RevenueCat ──→ customerInfo mis à jour
                  ──→ Firebase mis à jour
                  ──→ UI : RIEN (bool local figé à false)
                  → Utilisateur voit toujours "mode gratuit" ❌

APRÈS (corrigé)
───────────────
Achat RevenueCat ──→ CustomerInfoUpdateListener déclenché
                  ──→ PremiumProvider.refresh()
                  ──→ notifyListeners()
                  ──→ TOUS les Consumer<PremiumProvider> reconstruits
                  ──→ Firebase sync via syncSubscriptionStatus()
                  → UI reflète immédiatement le bon plan ✅
```

---

## 🔑 Leçon principale

> **Ne jamais stocker l'état d'abonnement dans une variable locale d'un widget.**  
> L'état premium est une donnée globale qui peut changer à tout moment (achat, expiration, restauration). Il doit vivre dans un `ChangeNotifier` global écouté par tous les widgets qui en dépendent.

---

*Document généré le 29 mars 2026*
