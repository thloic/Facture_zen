# Configuration de l'authentification Google

## ✅ Implémentation terminée

L'authentification Google a été implémentée avec succès dans votre application FactureZen !

### 📝 Modifications apportées :

1. **Ajout de la dépendance** `google_sign_in: ^6.2.2` dans `pubspec.yaml`
2. **Méthode `signInWithGoogle()`** ajoutée dans `AuthService`
3. **Méthode `signInWithGoogle()`** ajoutée dans `LoginViewModel`
4. **Bouton "Continuer avec Google"** ajouté dans `LoginScreen`
5. **Déconnexion Google** intégrée dans la méthode `signOut()`

---

## ⚙️ Configuration requise (IMPORTANT)

Pour que l'authentification Google fonctionne, vous devez configurer votre projet Firebase :

### 1️⃣ **Configuration Firebase Console**

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet **facture_zen**
3. Allez dans **Authentication** → **Sign-in method**
4. Activez **Google** comme fournisseur d'authentification
5. Configurez l'email du projet si demandé

### 2️⃣ **Configuration Android**

#### a) Obtenir le SHA-1 de votre application

Exécutez cette commande dans le terminal :

```bash
cd android
./gradlew signingReport
```

ou sur Windows :

```powershell
cd android
.\gradlew.bat signingReport
```

Copiez le **SHA-1** qui s'affiche (cherchez `Task :app:signingReport`)

#### b) Ajouter le SHA-1 dans Firebase

1. Dans Firebase Console, allez dans **Paramètres du projet** (icône ⚙️)
2. Scrollez jusqu'à **Vos applications** → Section **Android**
3. Cliquez sur votre application Android
4. Ajoutez le **SHA-1** dans "Empreintes de certificat numérique"
5. Téléchargez le nouveau fichier `google-services.json`
6. Remplacez l'ancien fichier dans `android/app/google-services.json`

### 3️⃣ **Configuration iOS** (si vous ciblez iOS)

#### a) Télécharger GoogleService-Info.plist

1. Dans Firebase Console → **Paramètres du projet**
2. Section **iOS**, téléchargez `GoogleService-Info.plist`
3. Copiez-le dans `ios/Runner/GoogleService-Info.plist`

#### b) Ajouter l'URL Scheme

1. Ouvrez `ios/Runner/Info.plist`
2. Ajoutez ce code (remplacez `YOUR_REVERSED_CLIENT_ID` par la valeur dans `GoogleService-Info.plist`) :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 4️⃣ **Optionnel : Ajouter le logo Google**

Le bouton utilise `assets/images/google_logo.png`. Pour un meilleur rendu :

1. Téléchargez le logo Google officiel
2. Créez le dossier `assets/images/` si nécessaire
3. Placez-y `google_logo.png`
4. Ajoutez dans `pubspec.yaml` :

```yaml
flutter:
  assets:
    - assets/images/google_logo.png
```

Si vous ne fournissez pas le logo, un icône de fallback sera affiché.

---

## 🧪 Test de l'authentification

1. Lancez l'application : `flutter run`
2. Sur la page de login, cliquez sur **"Continuer avec Google"**
3. Sélectionnez votre compte Google
4. Vous serez connecté et redirigé vers l'écran d'accueil

---

## 🔐 Fonctionnalités implémentées

✅ Connexion avec Google
✅ Création automatique du profil pour les nouveaux utilisateurs
✅ Sauvegarde des données dans Firebase Realtime Database
✅ Déconnexion Google intégrée
✅ Gestion des erreurs
✅ Interface utilisateur responsive
✅ Séparateur "OU" entre email/password et Google

---

## 📱 Structure du code

### AuthService (`lib/common/services/auth_service.dart`)

```dart
Future<User?> signInWithGoogle() async {
  // 1. Ouvre le sélecteur de compte Google
  // 2. Obtient les credentials Google
  // 3. Se connecte à Firebase avec ces credentials
  // 4. Crée/met à jour le profil dans la base de données
  // 5. Retourne l'utilisateur connecté
}
```

### LoginViewModel (`lib/features/auth/viewmodels/login_viewmodel.dart`)

```dart
Future<bool> signInWithGoogle() async {
  // Gère l'état de chargement et les erreurs
  // Appelle AuthService.signInWithGoogle()
  // Retourne true si succès, false sinon
}
```

### LoginScreen (`lib/features/auth/views/login_screen.dart`)

- Bouton Google stylisé
- Séparateur "OU"
- Navigation automatique après succès

---

## 🐛 Dépannage

### Erreur : "PlatformException (sign_in_failed)"

**Solution** : Vérifiez que le SHA-1 est correctement configuré dans Firebase

### Erreur : "API not enabled"

**Solution** : Activez Google Sign-In dans Firebase Console

### Le popup Google ne s'ouvre pas

**Solution** : Vérifiez que `google-services.json` est à jour

---

## 📞 Besoin d'aide ?

Si vous rencontrez des problèmes, vérifiez :
1. SHA-1 configuré ✓
2. Google activé dans Firebase Auth ✓
3. `google-services.json` à jour ✓
4. Dépendances installées (`flutter pub get`) ✓

Tout est prêt ! 🚀
