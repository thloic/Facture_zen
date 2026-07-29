# Cloud Function : vérification serveur du statut premium (RevenueCat)

Cette fonction (`revenueCatWebhook`) est la **seule** autorisée à écrire
`isPremium`, `monthlyInvoiceLimit`, `allowedTemplatesCount` et `planName` sous
`users/$uid` dans Firebase Realtime Database (voir `database.rules.json` à la
racine du repo, qui bloque ces champs pour toute écriture client). Sans ça,
n'importe quel utilisateur authentifié pouvait s'auto-attribuer le premium en
écrivant directement sur son propre nœud `users/$uid`.

## Mise en place (à faire une seule fois, hors de portée du code)

1. **Passer le projet Firebase `facturezen-558b0` au plan Blaze** (pay-as-you-go)
   dans la console Firebase — requis pour utiliser les Cloud Functions.
   Avec le volume de cette app, le coût réel restera très probablement à 0€
   (quota gratuit inclus dans Blaze).

2. **Générer une clé API secrète RevenueCat** (différente des clés publiques
   `goog_`/`appl_` déjà dans `.env`) : dashboard RevenueCat → *Project
   Settings* → *API Keys* → *Secret keys* → *Create secret key* (v1). Cette
   clé permet d'interroger l'API REST RevenueCat pour connaître l'état réel
   des entitlements d'un utilisateur.

3. **Choisir une valeur secrète arbitraire** pour authentifier le webhook
   (ex: générer 32+ caractères aléatoires) — elle sera envoyée par RevenueCat
   dans l'en-tête `Authorization` de chaque appel webhook, et vérifiée par la
   fonction.

4. **Définir les deux secrets côté Firebase** (depuis ce dossier, après
   `npm install`) :
   ```bash
   firebase functions:secrets:set REVENUECAT_AUTH_HEADER
   firebase functions:secrets:set REVENUECAT_SECRET_API_KEY
   ```

5. **Déployer** (⚠️ action sur l'infra live — à confirmer explicitement) :
   ```bash
   firebase deploy --only functions,database
   ```
   Notez l'URL affichée pour `revenueCatWebhook` (region `europe-west1`).

6. **Configurer le webhook dans RevenueCat** : dashboard → *Project Settings*
   → *Integrations* → *Webhooks* → coller l'URL de la fonction + la même
   valeur secrète que `REVENUECAT_AUTH_HEADER` dans le champ "Authorization
   header value".

7. **Tester** : RevenueCat propose un bouton "Send test event" dans la config
   du webhook. Vérifier dans les logs Cloud Functions (`firebase functions:log`)
   que l'appel est bien authentifié et traité, puis faire un achat sandbox
   réel (TestFlight iOS / piste interne Android) et vérifier que
   `users/$uid/isPremium` se met à jour dans la console Firebase.

## Pourquoi un appel REST à RevenueCat plutôt que faire confiance au payload du webhook ?

L'événement webhook (`event.entitlement_ids`, `event.type`, etc.) ne donne pas
un état complet et à jour des entitlements actifs (ex: sur `CANCELLATION`,
l'entitlement reste actif jusqu'à expiration). Cette fonction rappelle
`GET /v1/subscribers/{app_user_id}` avec la clé secrète pour obtenir l'état
authoritative des entitlements et de leurs dates d'expiration, comme recommandé
par RevenueCat.
