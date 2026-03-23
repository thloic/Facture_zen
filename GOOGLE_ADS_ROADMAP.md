# 🚀 Feuille de Route Google Ads - voXin

> **Pour le marketeur** : Ce document résume tout ce qui est configuré côté technique et ce dont vous avez besoin pour lancer vos campagnes Google Ads.

---

## 📋 RÉSUMÉ EXÉCUTIF

| Élément | Status | Notes |
|---------|--------|-------|
| Attribution iOS (SKAdNetwork) | ✅ Prêt | 60+ IDs configurés |
| App Tracking Transparency | ✅ Prêt | Permission demandée à l'utilisateur |
| Firebase Analytics | ✅ Prêt | Événements trackés automatiquement |
| Événements de conversion | ✅ Prêt | purchase, sign_up, etc. |
| Lien Firebase ↔ Google Ads | ⏳ À faire | Action manuelle requise |

---

## 📱 CE QUI EST DÉJÀ CONFIGURÉ (Côté Dev)

### 1. App Tracking Transparency (ATT) - iOS 14+
Apple exige qu'on demande la permission à l'utilisateur pour le tracking publicitaire.

- ✅ **Permission configurée** : L'app demande automatiquement la permission au premier lancement
- ✅ **Message affiché** : *"Nous utilisons vos données pour vous proposer des publicités personnalisées et améliorer votre expérience."*

### 2. SKAdNetwork (Attribution iOS)
C'est le système d'Apple pour mesurer les conversions sans identifier l'utilisateur.

- ✅ **60+ IDs SKAdNetwork** configurés incluant :
  - `cstr6suwn9.skadnetwork` (Google Ads - OBLIGATOIRE)
  - Tous les partenaires Google Ads
  - Facebook Ads (pour le futur)

### 3. Firebase Analytics
Les données de l'app sont automatiquement envoyées à Firebase.

- ✅ **Événements trackés automatiquement** :

| Événement Firebase | Quand ? | Utile pour |
|-------------------|---------|------------|
| `sign_up` | Inscription réussie | Mesurer les inscriptions |
| `login` | Connexion réussie | Rétention |
| `purchase` | Achat d'abonnement | **Conversions d'achat** |
| `add_to_cart` | Sélection d'un plan | Intent d'achat |
| `begin_checkout` | Début du paiement | Funnel |
| `create_invoice` | Création de facture | Engagement |

---

## 🔗 CE QUE LE MARKETEUR DOIT FAIRE

### Étape 1 : Accéder à la Console Firebase
1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner le projet **facturezen-558b0**
3. Demander les accès à l'équipe dev si nécessaire

### Étape 2 : Lier Firebase à Google Ads (CRITIQUE)
**Sans cette étape, Google Ads ne peut pas recevoir les conversions !**

1. Dans Firebase Console → **Paramètres du projet** (roue dentée)
2. Onglet **Intégrations**
3. Cliquer sur **Google Ads**
4. Cliquer **Associer**
5. Sélectionner votre compte Google Ads
6. Autoriser le partage des données

### Étape 3 : Configurer les conversions dans Google Ads
1. Aller sur [Google Ads](https://ads.google.com/)
2. **Outils et paramètres** → **Mesure** → **Conversions**
3. Cliquer **+ Nouvelle action de conversion**
4. Choisir **Application**
5. Sélectionner **Firebase** comme source
6. Importer les événements :
   - `in_app_purchase` ou `purchase` → Conversion d'achat
   - `sign_up` → Conversion d'inscription

### Étape 4 : Créer vos campagnes
Une fois les conversions configurées, vous pouvez créer vos campagnes :
- **App Campaigns** (recommandé pour les apps)
- Objectif : **Installations d'app** ou **Actions dans l'app**

---

## 📊 INFORMATIONS TECHNIQUES À FOURNIR AU MARKETEUR

### Identifiants de l'application

| Plateforme | Bundle ID / Package Name |
|------------|--------------------------|
| iOS | `com.example.factureZen` |
| Android | `com.facturezen.app` |

### Projet Firebase

| Élément | Valeur |
|---------|--------|
| Project ID | `facturezen-558b0` |
| Console | https://console.firebase.google.com/project/facturezen-558b0 |

### App Store Connect (pour iOS)

| Élément | Valeur |
|---------|--------|
| App Name | voXin |
| Bundle ID | `com.example.factureZen` |

> ⚠️ **Note** : Le marketeur aura besoin d'accès à App Store Connect pour voir les stats Apple Search Ads.

---

## 🧪 COMMENT TESTER QUE ÇA MARCHE

### Avant de lancer les campagnes :

1. **Vérifier Firebase Analytics** :
   - Firebase Console → Analytics → Events
   - Vous devez voir les événements (`sign_up`, `purchase`, etc.)
   - Utiliser **DebugView** pour le temps réel

2. **Vérifier le lien Google Ads** :
   - Firebase Console → Project Settings → Integrations → Google Ads
   - Status doit être "Linked"

3. **Vérifier les conversions Google Ads** :
   - Google Ads → Tools → Conversions
   - Les conversions Firebase doivent apparaître

---

## ⚠️ POINTS D'ATTENTION

### Délai des données
- Les données Firebase peuvent avoir **24-48h de retard**
- SKAdNetwork (iOS) a un délai de **24-72h** par conception Apple
- Les premières données peuvent prendre **quelques jours** à apparaître

### iOS 14+ et ATT
- ~20-40% des utilisateurs iOS acceptent le tracking
- Les conversions des utilisateurs qui refusent sont quand même mesurées via SKAdNetwork (mais agrégées, pas individuelles)

### Budget recommandé pour démarrer
- Minimum recommandé : **50€/jour** pour avoir assez de données
- Phase de learning Google Ads : **7-14 jours**

---

## 📞 CONTACTS

| Rôle | Pour quoi ? |
|------|-------------|
| Développeur | Problèmes techniques, nouveaux événements |
| Marketeur | Campagnes, budgets, créatives |

---

## 📝 CHECKLIST AVANT LANCEMENT

- [ ] Accès Firebase Console obtenu
- [ ] Firebase lié à Google Ads
- [ ] Conversions importées dans Google Ads
- [ ] App publiée sur App Store et Play Store
- [ ] Budget validé
- [ ] Créatives (images/vidéos) prêtes
- [ ] Première campagne créée en draft

---

## 🔄 MISES À JOUR

| Date | Modification |
|------|--------------|
| 20 mars 2026 | Configuration initiale complète |
| - | IS_ANALYTICS_ENABLED activé |
| - | 60+ SKAdNetwork IDs ajoutés |

---

*Document généré automatiquement - Projet voXin/FactureZen*
