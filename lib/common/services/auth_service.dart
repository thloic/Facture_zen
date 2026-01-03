// ========================================
// Fichier: lib/common/services/auth_service.dart
// ========================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// AuthService
/// Service d'authentification Firebase
/// Gère l'inscription, la connexion et la déconnexion
class AuthService {
  // Instances Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Récupère l'utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  /// Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Vérifie si un utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  /// Inscription avec email et mot de passe
  /// @param email L'adresse email
  /// @param password Le mot de passe (sera automatiquement hashé par Firebase Auth)
  /// @param companyName Le nom de l'entreprise
  /// @param companyAddress L'adresse de l'entreprise
  /// @return L'utilisateur créé ou null en cas d'erreur
  Future<User?> signUp({
    required String email,
    required String password,
    required String companyName,
    required String companyAddress,
  }) async {
    try {
      debugPrint('🔥 Tentative d\'inscription pour: $email');

      // Créer le compte Firebase Auth
      // ⚠️ Firebase Auth hash AUTOMATIQUEMENT le mot de passe de manière sécurisée
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        debugPrint('✅ Compte Firebase Auth créé: ${user.uid}');

        // Sauvegarder les informations supplémentaires dans Realtime Database
        // ⚠️ JAMAIS stocker le mot de passe ici, même hashé !
        try {
          await _database.child('users').child(user.uid).set({
            'email': email,
            'companyName': companyName,
            'companyAddress': companyAddress,
            'createdAt': ServerValue.timestamp,
            'updatedAt': ServerValue.timestamp,
          });
          debugPrint('✅ Données utilisateur sauvegardées dans Realtime Database');
        } catch (dbError) {
          debugPrint('❌ Erreur sauvegarde dans Realtime Database: $dbError');
          // L'utilisateur est créé dans Auth mais pas dans Database
          // Tu peux décider de supprimer le compte Auth ou le laisser
          throw Exception('Compte créé mais données non sauvegardées. Erreur: $dbError');
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Erreur inscription: $e');
      throw Exception('Une erreur est survenue lors de l\'inscription: $e');
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

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

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
      throw Exception('Une erreur est survenue lors de la connexion: $e');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('✅ Déconnexion réussie');
    } catch (e) {
      debugPrint('❌ Erreur déconnexion: $e');
      throw Exception('Une erreur est survenue lors de la déconnexion');
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
      throw Exception('Impossible de mettre à jour les données: $e');
    }
  }

  /// Réinitialisation du mot de passe
  /// @param email L'adresse email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Email de réinitialisation envoyé');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur réinitialisation: ${e.code}');
      throw _handleAuthException(e);
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
      throw Exception('Impossible de supprimer le compte');
    }
  }

  /// Transforme les exceptions Firebase en messages compréhensibles
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Format d\'email invalide';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'operation-not-allowed':
        return 'Opération non autorisée';
      case 'network-request-failed':
        return 'Erreur de connexion. Vérifiez votre internet';
      default:
        return 'Une erreur est survenue: ${e.message}';
    }
  }
}