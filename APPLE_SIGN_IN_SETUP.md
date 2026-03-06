# Configuration de l'authentification Apple

## ✅ Implémentation terminée

L'authentification Apple a été implémentée avec succès dans votre application FactureZen !

### 📝 Modifications apportées :

1. **Ajout des dépendances** `sign_in_with_apple: ^6.2.0` et `crypto: ^3.0.6` dans `pubspec.yaml`
2. **Méthode `signInWithApple()`** ajoutée dans `AuthService`
3. **Méthode `signInWithApple()`** ajoutée dans `LoginViewModel`
4. **Bouton Apple** ajouté dans `LoginScreen` à côté du bouton Google
5. **Système de PIN** intégré (même fonctionnement que Google)

---

## ⚙️ Configuration requise (IMPORTANT)

Pour que l'authentification Apple fonctionne, vous devez configurer votre projet Firebase et votre compte Apple Developer :

### 1️⃣ **Configuration Apple Developer**

#### a) Créer un App ID

1. Allez sur [Apple Developer](https://developer.apple.com/account/)
2. Sélectionnez **Certificates, Identifiers & Profiles**
3. Cliquez sur **Identifiers** → **+** (nouveau)
4. Sélectionnez **App IDs** → **Continue**
5. Sélectionnez **App** → **Continue**
6. Remplissez :
   - **Description** : FactureZen
   - **Bundle ID** : `com.example.facture_zen` (ou votre Bundle ID)
7. Cochez **Sign in with Apple** dans les Capabilities
8. Cliquez sur **Continue** → **Register**

#### b) Créer un Service ID

1. Dans **Identifiers** → **+** (nouveau)
2. Sélectionnez **Services IDs** → **Continue**
3. Remplissez :
   - **Description** : FactureZen Web Auth
   - **Identifier** : `com.example.facture_zen.service` (doit être unique)
4. Cochez **Sign in with Apple**
5. Cliquez sur **Configure** à côté de Sign in with Apple
6. Sélectionnez votre **Primary App ID** créé précédemment
7. Dans **Web Authentication Configuration** :
   - **Domains** : `facture-zen.firebaseapp.com`
   - **Return URLs** : `https://facture-zen.firebaseapp.com/__/auth/handler`
   
   ⚠️ **Remplacez `facture-zen`** par le nom de votre projet Firebase !
   
8. Cliquez sur **Continue** → **Register**

#### c) Créer une Key

1. Dans **Keys** → **+** (nouveau)
2. Remplissez :
   - **Key Name** : FactureZen Apple Sign In Key
3. Cochez **Sign in with Apple**
4. Cliquez sur **Configure**
5. Sélectionnez votre **Primary App ID**
6. Cliquez sur **Save** → **Continue** → **Register**
7. **Téléchargez la clé** (.p8 file) et **notez le Key ID** (vous ne pourrez plus la télécharger)

---

### 2️⃣ **Configuration Firebase Console**

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet **facture_zen**
3. Allez dans **Authentication** → **Sign-in method**
4. Activez **Apple** comme fournisseur d'authentification
5. Remplissez les informations requises :
   - **Service ID** : celui créé dans Apple Developer (`com.example.facture_zen.service`)
   - **Apple Team ID** : trouvez-le dans [Membership](https://developer.apple.com/account/#!/membership)
   - **Key ID** : celui noté lors de la création de la Key
   - **Private Key** : contenu du fichier .p8 téléchargé (ouvrez-le avec un éditeur de texte)
6. Cliquez sur **Save**

---

### 3️⃣ **Configuration iOS** (Xcode)

#### a) Ouvrez le projet dans Xcode

```bash
cd ios
open Runner.xcworkspace
```

#### b) Activez Sign in with Apple Capability

1. Dans Xcode, sélectionnez le projet **Runner**
2. Sélectionnez la cible **Runner**
3. Allez dans l'onglet **Signing & Capabilities**
4. Cliquez sur **+ Capability**
5. Recherchez et ajoutez **Sign in with Apple**

#### c) Configurez le Bundle Identifier

1. Dans **Signing & Capabilities** → **Bundle Identifier**
2. Assurez-vous qu'il correspond à celui configuré dans Apple Developer
   (exemple : `com.example.facture_zen`)

---

### 4️⃣ **Configuration Android** (Optionnel)

L'authentification Apple sur Android fonctionne via le web. Aucune configuration supplémentaire n'est nécessaire si vous avez déjà configuré Firebase.

---

### 5️⃣ **Optionnel : Ajouter le logo Apple**

Le bouton utilise actuellement l'icône Flutter `Icons.apple`. Pour un meilleur rendu :

1. Téléchargez le logo Apple officiel
2. Placez-le dans `assets/images/apple_logo.png`
3. Modifiez `login_screen.dart` :

```dart
// Remplacez dans _buildSocialSignInButtons :
child: const Icon(
  Icons.apple,
  size: 32,
  color: Color(0xFF000000),
),

// Par :
child: Image.asset(
  'assets/images/apple_logo.png',
  height: 32,
  width: 32,
),
```

4. Ajoutez dans `pubspec.yaml` :

```yaml
flutter:
  assets:
    - assets/images/apple_logo.png
```

---

## 🧪 Test de l'authentification

### Sur iOS

1. Lancez l'application : `flutter run`
2. Sur la page de login, cliquez sur le **bouton Apple** (à côté de Google)
3. Suivez le processus d'authentification Apple
4. Vous serez connecté et redirigé vers l'**écran de configuration du PIN** si c'est votre première connexion

### Sur Android

1. Lancez l'application : `flutter run`
2. Le processus est identique, mais utilise l'interface web d'Apple

---

## 🔐 Fonctionnalités implémentées

✅ Connexion avec Apple
✅ Configuration du compte Apple Developer
✅ Intégration Firebase
✅ Création automatique du profil pour les nouveaux utilisateurs
✅ Sauvegarde des données dans Firebase Realtime Database
✅ **Système de code PIN** :
  - Si c'est la première connexion → configuration du PIN à 4 chiffres
  - Si le PIN existe → demande du PIN pour connexion rapide
  - Même fonctionnement que Google Sign In
✅ Déconnexion Apple intégrée
✅ Gestion des erreurs
✅ Interface utilisateur responsive
✅ Bouton Apple à côté du bouton Google

---

## 📱 Structure du code

### AuthService (`lib/common/services/auth_service.dart`)

```dart
Future<User?> signInWithApple() async {
  // 1. Génère un nonce sécurisé
  // 2. Ouvre l'interface d'authentification Apple
  // 3. Obtient les credentials Apple (email, nom)
  // 4. Se connecte à Firebase avec ces credentials
  // 5. Crée/met à jour le profil dans la base de données
  // 6. Retourne l'utilisateur connecté
}
```

### LoginViewModel (`lib/features/auth/viewmodels/login_viewmodel.dart`)

```dart
Future<bool> signInWithApple() async {
  // Gère l'état de chargement et les erreurs
  // Appelle AuthService.signInWithApple()
  // Tracke l'événement de connexion (Analytics)
  // Retourne true si succès, false sinon
}
```

### LoginScreen (`lib/features/auth/views/login_screen.dart`)

- Boutons Google et Apple côte à côte
- Séparateur "OU"
- Navigation automatique :
  - Vers `/pin-setup` si première connexion
  - Vers `/pin-login` si PIN déjà configuré
  - Vers `/home` après validation du PIN

---

## 🔄 Flux d'authentification avec PIN

1. **Utilisateur clique sur le bouton Apple**
2. **Authentification Apple réussie**
3. **Vérification du PIN** :
   - ✅ **PIN existe** → Redirection vers `/pin-login` pour entrer le PIN
   - ❌ **Pas de PIN** → Redirection vers `/pin-setup` pour créer un PIN
4. **PIN validé** → Redirection vers `/home`

Ce flux est **identique** pour Google et Apple !

---

## 🐛 Dépannage

### Erreur : "Invalid Service ID"

**Solution** : Vérifiez que le Service ID est correctement configuré dans Apple Developer et Firebase

### Erreur : "Private Key invalid"

**Solution** : Assurez-vous de copier **tout le contenu** du fichier .p8, y compris les lignes `-----BEGIN PRIVATE KEY-----` et `-----END PRIVATE KEY-----`

### Le popup Apple ne s'ouvre pas

**Solution** : Vérifiez que Sign in with Apple est activé dans Xcode (Signing & Capabilities)

### Erreur sur Android

**Solution** : Assurez-vous que les Return URLs sont correctement configurées dans Apple Developer

---

## 📞 Besoin d'aide ?

Si vous rencontrez des problèmes, vérifiez :
1. App ID et Service ID créés dans Apple Developer ✓
2. Key créée et téléchargée ✓
3. Apple activé dans Firebase Auth ✓
4. Service ID, Team ID, Key ID et Private Key configurés dans Firebase ✓
5. Sign in with Apple capability ajoutée dans Xcode ✓
6. Dépendances installées (`flutter pub get`) ✓

Tout est prêt ! 🚀
