// ========================================
// Fichier: lib/common/services/auth_service.dart
// ========================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../revenue_cat_util.dart' as revenue_cat;


/// AuthService
/// Service d'authentification Firebase
/// Gère l'inscription, la connexion et la déconnexion
class AuthService {
  // Instances Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Récupère l'utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  /// Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Vérifie si un utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  /// Inscription avec email et mot de passe
  /// @param email L'adresse email
  /// @param password Le mot de passe (sera automatiquement hashé par Firebase Auth)
  /// @param firstName Le prénom de l'utilisateur
  /// @param lastName Le nom de l'utilisateur
  /// @return L'utilisateur créé ou null en cas d'erreur
  Future<User?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      debugPrint('🔥 Tentative d\'inscription pour: $email');

      // Créer le compte Firebase Auth
      // ⚠️ Firebase Auth hash AUTOMATIQUEMENT le mot de passe de manière sécurisée
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        debugPrint('✅ Compte Firebase Auth créé: ${user.uid}');

        // Sauvegarder les informations supplémentaires dans Realtime Database
        // ⚠️ JAMAIS stocker le mot de passe ici, même hashé !
        try {
          await _database.child('users').child(user.uid).set({
            'email': email,
            'firstName': firstName,
            'lastName': lastName,
            'companyName': 'Entreprise',
            'companyAddress': 'Adresse non renseignée',
            'isPremium': false,
            'createdAt': ServerValue.timestamp,
            'updatedAt': ServerValue.timestamp,
          });
          debugPrint(
            '✅ Données utilisateur sauvegardées dans Realtime Database',
          );
        } catch (dbError) {
          debugPrint('❌ Erreur sauvegarde dans Realtime Database: $dbError');
          // L'utilisateur est créé dans Auth mais pas dans Database
          // Tu peux décider de supprimer le compte Auth ou le laisser
          throw Exception(
            'Votre compte a été créé mais certaines informations n\'ont pas pu être enregistrées. Veuillez contacter le support.',
          );
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Erreur inscription: $e');
      throw Exception('Impossible de créer votre compte pour le moment. Veuillez réessayer ou contacter le support si le problème persiste.');
    }
  }

  /// Connexion avec email et mot de passe
  /// @param email L'adresse email
  /// @param password Le mot de passe
  /// @return L'utilisateur connecté ou null en cas d'erreur
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔥 Tentative de connexion pour: $email');

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        debugPrint('✅ Connexion Firebase Auth réussie: ${user.uid}');

        // Mettre à jour la date de dernière connexion
        try {
          await _database.child('users').child(user.uid).update({
            'lastLoginAt': ServerValue.timestamp,
          });
          debugPrint('✅ Date de connexion mise à jour');
        } catch (dbError) {
          debugPrint('⚠️ Impossible de mettre à jour lastLoginAt: $dbError');
          // Ce n'est pas critique, on continue
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Erreur connexion: $e');
      throw Exception('Impossible de vous connecter pour le moment. Veuillez vérifier vos identifiants et réessayer.');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      // Déconnecter RevenueCat en premier
      try {
        await revenue_cat.login(null);
        debugPrint('✅ RevenueCat logged out');
      } catch (e) {
        debugPrint('⚠️ Failed to logout RevenueCat: $e');
        // Non-bloquant: on continue même si RevenueCat échoue
      }
      
      // Déconnecter Firebase Auth
      try {
        await _auth.signOut();
        debugPrint('✅ Firebase Auth logged out');
      } catch (e) {
        debugPrint('⚠️ Failed to logout Firebase: $e');
        // Non-bloquant: on continue même si Firebase échoue
      }

      // Déconnecter Google Sign In
      try {
        await _googleSignIn.signOut();
        debugPrint('✅ Google Sign In logged out');
      } catch (e) {
        debugPrint('⚠️ Failed to logout Google: $e');
        // Non-bloquant: on continue même si Google échoue
      }

      debugPrint('✅ Déconnexion réussie');
    } catch (e) {
      debugPrint('❌ Erreur déconnexion: $e');
      throw Exception('Impossible de vous déconnecter. Veuillez fermer et rouvrir l\'application.');
    }
  }

  /// Connexion avec Google
  /// @return L'utilisateur connecté ou null en cas d'erreur
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('🔥 Tentative de connexion avec Google');

      // Déclencher le flux d'authentification Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('⚠️ Connexion Google annulée par l\'utilisateur');
        return null;
      }

      debugPrint('✅ Utilisateur Google sélectionné: ${googleUser.email}');

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Créer les credentials Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Se connecter à Firebase avec les credentials Google
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        debugPrint('✅ Connexion Firebase réussie: ${user.uid}');

        // Vérifier si c'est un nouvel utilisateur
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          debugPrint('🆕 Nouvel utilisateur, création du profil...');

          // Créer le profil dans Realtime Database pour les nouveaux utilisateurs
          try {
            await _database.child('users').child(user.uid).set({
              'email': user.email ?? '',
              'companyName': user.displayName ?? 'Entreprise',
              'companyAddress': 'Adresse non renseignée',
              'avatarUrl': user.photoURL,
              'createdAt': ServerValue.timestamp,
              'updatedAt': ServerValue.timestamp,
              'authProvider': 'google',
            });
            debugPrint('✅ Profil créé dans Realtime Database');
          } catch (dbError) {
            debugPrint('❌ Erreur création profil: $dbError');
          }
        } else {
          // Mettre à jour la date de dernière connexion pour les utilisateurs existants
          try {
            await _database.child('users').child(user.uid).update({
              'lastLoginAt': ServerValue.timestamp,
            });
            debugPrint('✅ Date de connexion mise à jour');
          } catch (dbError) {
            debugPrint('⚠️ Impossible de mettre à jour lastLoginAt: $dbError');
          }
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Erreur connexion Google: $e');
      throw Exception(
        'Impossible de vous connecter avec Google. Vérifiez votre connexion internet et réessayez.',
      );
    }
  }

  /// Génère un nonce aléatoire sécurisé pour Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Retourne le SHA256 hash d'un string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Connexion avec Apple
  /// @return L'utilisateur connecté ou null en cas d'erreur
  Future<User?> signInWithApple() async {
    try {
      debugPrint('🍎 Tentative de connexion avec Apple');

      // Générer un nonce pour la sécurité
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      debugPrint('🔐 Nonce généré (SHA256): $nonce');
      debugPrint('🔐 Nonce brut (pour Firebase): $rawNonce');

      // Déclencher le flux d'authentification Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      debugPrint('✅ Credentials Apple reçus');
      debugPrint('📱 identityToken: ${appleCredential.identityToken}');
      debugPrint('📱 authorizationCode: ${appleCredential.authorizationCode}');
      debugPrint('📱 email: ${appleCredential.email}');

      // Vérifier que nous avons un identityToken valide
      if (appleCredential.identityToken == null) {
        debugPrint(
          '❌ identityToken is null - Apple credentials incomplete',
        );
        throw Exception(
          'Unable to retrieve Apple authentication token. Please try again.',
        );
      }

      // Créer les credentials Firebase
      debugPrint('🔄 Création des credentials Firebase...');
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken!,
        rawNonce: rawNonce,
      );
      debugPrint('✅ Credentials Firebase créés');

      // Se connecter à Firebase avec les credentials Apple
      debugPrint('🔐 Authentification auprès de Firebase...');
      final UserCredential userCredential = await _auth.signInWithCredential(
        oauthCredential,
      );
      final user = userCredential.user;

      if (user != null) {
        debugPrint('✅ Connexion Firebase réussie: ${user.uid}');

        // Vérifier si c'est un nouvel utilisateur
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          debugPrint('🆕 Nouvel utilisateur Apple, création du profil...');

          // Récupérer le nom depuis Apple (peut être null si l'utilisateur refuse)
          String displayName = user.displayName ?? '';
          if (displayName.isEmpty &&
              appleCredential.givenName != null &&
              appleCredential.familyName != null) {
            displayName =
                '${appleCredential.givenName} ${appleCredential.familyName}';
          }

          // Créer le profil dans Realtime Database pour les nouveaux utilisateurs
          try {
            await _database.child('users').child(user.uid).set({
              'email': user.email ?? appleCredential.email ?? '',
              'companyName': displayName.isNotEmpty
                  ? displayName
                  : 'Entreprise',
              'companyAddress': 'Adresse non renseignée',
              'createdAt': ServerValue.timestamp,
              'updatedAt': ServerValue.timestamp,
              'authProvider': 'apple',
            });
            debugPrint('✅ Profil créé dans Realtime Database');
          } catch (dbError) {
            debugPrint('❌ Erreur création profil: $dbError');
          }
        } else {
          // Mettre à jour la date de dernière connexion pour les utilisateurs existants
          try {
            await _database.child('users').child(user.uid).update({
              'lastLoginAt': ServerValue.timestamp,
            });
            debugPrint('✅ Date de connexion mise à jour');
          } catch (dbError) {
            debugPrint('⚠️ Impossible de mettre à jour lastLoginAt: $dbError');
          }
        }
      }

      return user;
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('❌ Erreur Apple Sign In: ${e.code} - ${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('⚠️ Connexion Apple annulée par l\'utilisateur');
        return null;
      }
      throw Exception(
        'Impossible de vous connecter avec Apple. Veuillez réessayer.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      debugPrint('📋 Détails erreur: ${e.toString()}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Erreur connexion Apple: $e');
      throw Exception(
        'Impossible de vous connecter avec Apple. Vérifiez votre connexion internet et réessayez.',
      );
    }
  }

  /// Récupère les informations de l'utilisateur depuis Realtime Database
  /// @param userId L'ID de l'utilisateur
  /// @return Les données de l'utilisateur
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      debugPrint('🔥 Récupération des données pour: $userId');
      final snapshot = await _database.child('users').child(userId).get();

      if (snapshot.exists) {
        debugPrint('✅ Données utilisateur récupérées');
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        debugPrint('⚠️ Aucune donnée trouvée pour cet utilisateur');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération données: $e');
      return null;
    }
  }

  /// Met à jour les informations de l'utilisateur
  /// @param userId L'ID de l'utilisateur
  /// @param data Les données à mettre à jour
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = ServerValue.timestamp;
      await _database.child('users').child(userId).update(data);
      debugPrint('✅ Données utilisateur mises à jour');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour données: $e');
      throw Exception('Impossible de sauvegarder vos modifications. Vérifiez votre connexion internet et réessayez.');
    }
  }

  /// Réinitialisation du mot de passe
  /// @param email L'adresse email
  Future<void> resetPassword(String email) async {
    try {
      debugPrint(
        '🔥 Tentative d\'envoi email de réinitialisation pour: $email',
      );
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Email de réinitialisation envoyé à $email');
      debugPrint('📧 Vérifiez votre boîte mail (y compris les spams)');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur réinitialisation: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Erreur inconnue: $e');
      throw Exception('Impossible d\'envoyer l\'email de réinitialisation. Vérifiez que l\'adresse email est correcte et réessayez.');
    }
  }

  /// Supprime le compte utilisateur
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Supprimer les données de la base de données
        await _database.child('users').child(user.uid).remove();

        // Supprimer le compte Firebase Auth
        await user.delete();

        debugPrint('✅ Compte supprimé');
      }
    } catch (e) {
      debugPrint('❌ Erreur suppression compte: $e');
      throw Exception('Impossible de supprimer votre compte. Cette action nécessite une connexion récente. Déconnectez-vous, reconnectez-vous puis réessayez.');
    }
  }

  /// Transforme les exceptions Firebase en messages compréhensibles
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      // Erreurs liées au mot de passe
      case 'weak-password':
        return 'Le mot de passe est trop faible. Utilisez au moins 6 caractères avec des lettres et des chiffres.';
      case 'wrong-password':
        return 'Le mot de passe que vous avez saisi est incorrect. Veuillez réessayer.';
      
      // Erreurs liées à l'email
      case 'email-already-in-use':
        return 'Cette adresse email est déjà utilisée. Connectez-vous ou utilisez une autre adresse.';
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide. Vérifiez qu\'elle est au bon format (exemple@email.com).';
      
      // Erreurs liées au compte
      case 'user-not-found':
        return 'Aucun compte n\'existe avec cette adresse email. Vérifiez l\'email ou créez un nouveau compte.';
      case 'user-disabled':
        return 'Votre compte a été désactivé. Contactez le support pour plus d\'informations.';
      
      // Erreurs de sécurité
      case 'too-many-requests':
        return 'Trop de tentatives de connexion. Veuillez patienter quelques minutes avant de réessayer.';
      case 'operation-not-allowed':
        return 'Cette méthode de connexion n\'est pas activée. Contactez le support.';
      
      // Erreurs de réseau
      case 'network-request-failed':
        return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet et réessayez.';
      
      // Erreurs de session
      case 'requires-recent-login':
        return 'Cette action nécessite une connexion récente. Veuillez vous déconnecter et vous reconnecter.';
      case 'expired-action-code':
        return 'Ce lien a expiré. Demandez un nouveau lien de réinitialisation.';
      case 'invalid-action-code':
        return 'Le lien est invalide ou a déjà été utilisé. Demandez un nouveau lien.';
      
      // Erreurs liées aux informations d'identification
      case 'invalid-credential':
        return 'Les informations de connexion sont invalides ou ont expiré. Veuillez réessayer.';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec cette adresse email mais avec une autre méthode de connexion.';
      
      // Erreurs de validation
      case 'missing-email':
        return 'Veuillez saisir une adresse email.';
      case 'missing-password':
        return 'Veuillez saisir un mot de passe.';
      case 'invalid-verification-code':
        return 'Le code de vérification est invalide. Veuillez réessayer.';
      case 'invalid-verification-id':
        return 'La session de vérification a expiré. Veuillez recommencer.';
      
      // Erreur par défaut
      default:
        return 'Une erreur inattendue s\'est produite. Veuillez réessayer. Si le problème persiste, contactez le support.';
    }
  }
}
