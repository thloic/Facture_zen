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
  /// Vérifie d'abord dans users/{uid}/profile, puis dans users/{uid} pour compatibilité
  Future<bool> hasProfile() async {
    try {
      if (_currentUserId == null) {
        debugPrint('⚠️ [PROFILE] Aucun utilisateur connecté');
        return false;
      }

      debugPrint('🔍 [PROFILE] Vérification existence profil pour: $_currentUserId');

      // 1. D'abord vérifier dans users/{uid}/profile (nouveau format)
      var snapshot = await _database
          .child('users')
          .child(_currentUserId!)
          .child('profile')
          .get();

      if (!snapshot.exists) {
        debugPrint('📋 [PROFILE] Profil n\'existe pas dans users/{uid}/profile');
        
        // 2. Vérifier dans users/{uid} directement (ancien format - inscription)
        snapshot = await _database
            .child('users')
            .child(_currentUserId!)
            .get();
            
        if (!snapshot.exists) {
          debugPrint('📋 [PROFILE] Profil n\'existe pas non plus dans users/{uid}');
          return false;
        }
        debugPrint('📋 [PROFILE] Données trouvées dans users/{uid} (format inscription)');
      }

      debugPrint('📋 [PROFILE] Snapshot value type: ${snapshot.value.runtimeType}');
      debugPrint('📋 [PROFILE] Snapshot value: ${snapshot.value}');
      
      // Vérifier que c'est bien une Map (structure valide)
      if (snapshot.value is! Map) {
        debugPrint('⚠️ [PROFILE] Données profil invalides (type: ${snapshot.value.runtimeType})');
        debugPrint('⚠️ [PROFILE] Valeur reçue: ${snapshot.value}');
        debugPrint('🔧 [PROFILE] Données corrompues détectées, profil considéré comme absent');
        return false;
      }

      // Cast sécurisé
      Map<dynamic, dynamic> data;
      try {
        data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      } catch (castError) {
        debugPrint('❌ [PROFILE] Erreur cast Map: $castError');
        return false;
      }
      
      // Vérifier que le profil contient au moins les champs essentiels
      final hasCompanyName = data.containsKey('companyName') && 
                            data['companyName'] != null && 
                            data['companyName'].toString().isNotEmpty;
      
      debugPrint('📋 [PROFILE] Profil existe: $hasCompanyName');
      if (hasCompanyName) {
        debugPrint('   - companyName: ${data['companyName']}');
      }

      return hasCompanyName;
    } catch (e, stack) {
      debugPrint('❌ [PROFILE] Erreur hasProfile: $e');
      debugPrint('Stack trace: $stack');
      return false;
    }
  }

  /// Récupère le profil de l'utilisateur
  /// Cherche d'abord dans users/{uid}/profile, puis dans users/{uid} pour compatibilité
  Future<UserProfile?> getUserProfile() async {
    try {
      if (_currentUserId == null) {
        debugPrint('⚠️ [PROFILE SERVICE] Aucun utilisateur connecté');
        return null;
      }

      debugPrint('📥 [PROFILE SERVICE] Récupération profil pour: $_currentUserId');

      // 1. D'abord chercher dans users/{uid}/profile (nouveau format)
      var snapshot = await _database
          .child('users')
          .child(_currentUserId!)
          .child('profile')
          .get();

      debugPrint('📥 [PROFILE SERVICE] Snapshot profile exists: ${snapshot.exists}');

      if (!snapshot.exists) {
        // 2. Chercher dans users/{uid} directement (ancien format - inscription)
        debugPrint('📭 [PROFILE SERVICE] Pas de profil dans /profile, vérification racine...');
        snapshot = await _database
            .child('users')
            .child(_currentUserId!)
            .get();
            
        if (!snapshot.exists) {
          debugPrint('📭 [PROFILE SERVICE] Aucun profil trouvé dans Firebase');
          debugPrint('💡 [PROFILE SERVICE] L\'utilisateur doit configurer son profil entreprise');
          return null;
        }
        debugPrint('📥 [PROFILE SERVICE] Données trouvées dans users/{uid} (format inscription)');
      }

      debugPrint('📥 [PROFILE SERVICE] Snapshot value type: ${snapshot.value.runtimeType}');
      
      // Vérifier que les données sont bien une Map
      if (snapshot.value is! Map) {
        debugPrint('❌ [PROFILE SERVICE] Format de données invalide: ${snapshot.value.runtimeType}');
        debugPrint('   Valeur: ${snapshot.value}');
        return null;
      }
      
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
