# Tracking Google Ads & Facebook Ads - Configuration

## 🎯 Résumé

Le tracking Google Ads et Facebook Ads est maintenant intégré dans l'application. Ce système envoie automatiquement les événements clés aux deux plateformes en parallèle.

---

## 📦 Dépendances installées

```yaml
firebase_analytics: ^12.1.2      # Google Ads tracking
facebook_app_events: ^0.19.2     # Facebook Ads tracking  
app_tracking_transparency: ^2.0.6 # Permission iOS 14+
```

---

## ⚙️ Configuration requise

### 1. Facebook App ID (OBLIGATOIRE)

Vous devez remplacer les placeholders par vos vrais identifiants Facebook :

#### Android (`android/app/src/main/res/values/strings.xml`)
```xml
<string name="facebook_app_id">VOTRE_FACEBOOK_APP_ID</string>
<string name="facebook_client_token">VOTRE_FACEBOOK_CLIENT_TOKEN</string>
<string name="fb_login_protocol_scheme">fbVOTRE_FACEBOOK_APP_ID</string>
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>FacebookAppID</key>
<string>VOTRE_FACEBOOK_APP_ID</string>
<key>FacebookClientToken</key>
<string>VOTRE_FACEBOOK_CLIENT_TOKEN</string>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fbVOTRE_FACEBOOK_APP_ID</string>
        </array>
    </dict>
</array>
```

### 2. Obtenir les identifiants Facebook

1. Aller sur [Facebook Developers](https://developers.facebook.com/apps/)
2. Créer ou sélectionner votre app
3. Aller dans **Paramètres > Général**
4. Copier :
   - **App ID** (numéro à 15 chiffres)
   - **Client Token** (dans Paramètres > Avancé)

---

## 📊 Événements trackés

| Événement | Firebase | Facebook | Trigger |
|-----------|----------|----------|---------|
| `sign_up` | ✅ | ✅ | Inscription réussie |
| `login` | ✅ | - | Connexion réussie |
| `purchase` | ✅ | ✅ | Achat d'abonnement |
| `add_to_cart` | ✅ | ✅ | Sélection d'un plan |
| `create_invoice` | ✅ | ✅ | Création de facture |
| `voice_recording` | ✅ | ✅ | Utilisation vocale |

---

## 🔧 Architecture

```
lib/common/services/
├── analytics_service.dart       # Firebase Analytics (Google Ads)
├── facebook_analytics_service.dart # Facebook App Events
└── tracking_service.dart        # Service unifié (appelle les deux)
```

### Utilisation

```dart
import 'package:facture_zen/common/services/tracking_service.dart';

// Tracker un événement (envoyé à Firebase ET Facebook)
await TrackingService().logPurchase(
  productId: 'pro_monthly',
  price: 9.99,
  currency: 'EUR',
);

// Tracker une inscription
await TrackingService().logSignUp(method: 'email');

// Définir l'ID utilisateur
await TrackingService().setUserId('user_123');
```

---

## 🍎 iOS - App Tracking Transparency (ATT)

La permission ATT est demandée automatiquement au lancement de l'app sur iOS 14+.

Le message affiché à l'utilisateur est configuré dans `Info.plist` :
```
"Nous utilisons ces données pour améliorer votre expérience et vous proposer des publicités personnalisées."
```

### SKAdNetwork

Les IDs SKAdNetwork pour Facebook et Google sont déjà configurés dans `Info.plist`.

---

## 🧪 Tests

### Firebase Analytics (DebugView)

1. Activer le mode debug :
```bash
# Android
adb shell setprop debug.firebase.analytics.app com.facturezen.app

# iOS
-FIRDebugEnabled
```

2. Aller dans **Firebase Console > Analytics > DebugView**
3. Les événements apparaissent en temps réel

### Facebook Events Manager

1. Aller dans [Meta Events Manager](https://business.facebook.com/events_manager)
2. Sélectionner votre app
3. Onglet **Test Events**
4. Les événements apparaissent avec un délai de 20min max

---

## 🔗 Liens utiles

- [Firebase Analytics Flutter](https://firebase.google.com/docs/analytics/get-started?platform=flutter)
- [Facebook App Events Flutter](https://pub.dev/packages/facebook_app_events)
- [App Tracking Transparency](https://pub.dev/packages/app_tracking_transparency)
- [SKAdNetwork IDs](https://developers.facebook.com/docs/SKAdNetwork)

---

## ⚠️ Notes importantes

1. **Production** : Les événements ne sont PAS envoyés en mode debug par défaut pour Firebase. Utilisez DebugView pour tester.

2. **RGPD** : Assurez-vous d'avoir le consentement utilisateur avant d'activer le tracking (ATT sur iOS + popup RGPD si nécessaire).

3. **Délai** : Les événements Facebook peuvent prendre jusqu'à 20 minutes pour apparaître dans Events Manager.
