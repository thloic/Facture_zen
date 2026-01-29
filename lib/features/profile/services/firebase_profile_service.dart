import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';

/// Service Firebase pour la gestion du profil utilisateur
class FirebaseProfileService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Récupère l'utilisateur actuel
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Vérifie si l'utilisateur a un profil configuré
  Future<bool> hasProfile() async {
    try {
      if (_currentUserId == null) {
        debugPrint('⚠️ [PROFILE] Aucun utilisateur connecté');
        return false;
      }

      debugPrint('🔍 [PROFILE] Vérification existence profil pour: $_currentUserId');

      final snapshot = await _database
          .child('users')
          .child(_currentUserId!)
          .child('profile')
          .get();

      final exists = snapshot.exists;
      debugPrint('📋 [PROFILE] Profil existe: $exists');

      return exists;
    } catch (e) {
      debugPrint('❌ [PROFILE] Erreur hasProfile: $e');
      return false;
    }
  }

  /// Récupère le profil de l'utilisateur
  Future<UserProfile?> getUserProfile() async {
    try {
      if (_currentUserId == null) {
        debugPrint('⚠️ [PROFILE SERVICE] Aucun utilisateur connecté');
        return null;
      }

      debugPrint('📥 [PROFILE SERVICE] Récupération profil pour: $_currentUserId');

      final snapshot = await _database
          .child('users')
          .child(_currentUserId!)
          .child('profile')
          .get();

      debugPrint('📥 [PROFILE SERVICE] Snapshot exists: ${snapshot.exists}');

      if (!snapshot.exists) {
        debugPrint('📭 [PROFILE SERVICE] Aucun profil trouvé dans Firebase');
        debugPrint('💡 [PROFILE SERVICE] L\'utilisateur doit configurer son profil entreprise');
        return null;
      }

      debugPrint('📥 [PROFILE SERVICE] Snapshot value type: ${snapshot.value.runtimeType}');
      final data = snapshot.value as Map<dynamic, dynamic>;
      debugPrint('📥 [PROFILE SERVICE] Données brutes: $data');
      
      final profile = UserProfile.fromMap(data, _currentUserId!);

      debugPrint('✅ [PROFILE SERVICE] Profil chargé avec succès:');
      debugPrint('   - companyName: "${profile.companyName}"');
      debugPrint('   - companyAddress: "${profile.companyAddress}"');
      debugPrint('   - companyPhone: "${profile.companyPhone}"');
      debugPrint('   - companyEmail: "${profile.companyEmail}"');
      debugPrint('   - companySiret: "${profile.companySiret}"');
      
      return profile;
    } catch (e, stack) {
      debugPrint('❌ [PROFILE SERVICE] Erreur getUserProfile: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  /// Crée ou met à jour le profil utilisateur
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      debugPrint('💾 [PROFILE] Sauvegarde profil: ${profile.companyName}');

      // Mettre à jour la date de modification
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());

      await _database
          .child('users')
          .child(_currentUserId!)
          .child('profile')
          .set(updatedProfile.toMap());

      debugPrint('✅ [PROFILE] Profil sauvegardé avec succès');
    } catch (e, stack) {
      debugPrint('❌ [PROFILE] Erreur saveUserProfile: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  /// Met à jour partiellement le profil
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      debugPrint('🔧 [PROFILE] Mise à jour partielle du profil');

      // Ajouter la date de mise à jour
      updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await _database
          .child('users')
          .child(_currentUserId!)
          .child('profile')
          .update(updates);

      debugPrint('✅ [PROFILE] Profil mis à jour');
    } catch (e, stack) {
      debugPrint('❌ [PROFILE] Erreur updateProfile: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  /// Crée un profil initial avec des valeurs par défaut
  Future<void> createDefaultProfile() async {
    try {
      if (_currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      debugPrint('🆕 [PROFILE] Création profil par défaut');

      final defaultProfile = UserProfile(
        userId: _currentUserId!,
        companyName: 'Mon Entreprise',
        companyAddress: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await saveUserProfile(defaultProfile);
      debugPrint('✅ [PROFILE] Profil par défaut créé');
    } catch (e) {
      debugPrint('❌ [PROFILE] Erreur createDefaultProfile: $e');
      rethrow;
    }
  }

  


}
