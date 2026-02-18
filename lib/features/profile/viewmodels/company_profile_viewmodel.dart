import 'dart:io';
import 'package:facture_zen/features/profile/services/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_profile_model.dart';

/// ViewModel pour gérer le profil entreprise de l'utilisateur
class CompanyProfileViewModel extends ChangeNotifier {
  final ImageUploadService _imageUploadService = ImageUploadService();
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  // État du profil
  UserProfile? _profile;
  bool _isLoading = false;
  bool _isUploadingLogo = false;
  String? _errorMessage;
  
  // Gestion du logo
  File? _selectedLogoFile;
  String? _selectedLogoUrl;

  /// Constructeur
  CompanyProfileViewModel();

  // ============================================================================
  // GETTERS
  // ============================================================================

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isUploadingLogo => _isUploadingLogo;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasProfile => _profile != null;
  File? get selectedLogoFile => _selectedLogoFile;
  String? get selectedLogoUrl => _selectedLogoUrl;

  // ============================================================================
  // GESTION DU PROFIL
  // ============================================================================

  /// Charge le profil existant depuis Firebase
  /// Vérifie d'abord users/{uid}/profile, puis users/{uid} pour compatibilité
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📥 [COMPANY PROFILE VM] Chargement du profil...');
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // 1. D'abord chercher dans users/{uid}/profile (nouveau format)
      var snapshot = await _databaseRef
          .child('users')
          .child(userId)
          .child('profile')
          .get();

      if (!snapshot.exists) {
        debugPrint('📭 [COMPANY PROFILE VM] Pas de profil dans /profile, vérification racine...');
        
        // 2. Chercher dans users/{uid} directement (format inscription)
        snapshot = await _databaseRef
            .child('users')
            .child(userId)
            .get();
      }

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        _profile = UserProfile.fromMap(data, userId);
        
        // Si un logo existe déjà dans le profil, le définir comme logo actuel
        if (_profile?.companyLogo != null) {
          _selectedLogoUrl = _profile!.companyLogo;
          debugPrint('🖼️ [COMPANY PROFILE VM] Logo existant trouvé: $_selectedLogoUrl');
        }

        debugPrint('✅ [COMPANY PROFILE VM] Profil chargé: ${_profile!.companyName}');
      } else {
        debugPrint('📭 [COMPANY PROFILE VM] Aucun profil trouvé');
        _profile = null;
      }
    } catch (e, stack) {
      debugPrint('❌ [COMPANY PROFILE VM] Erreur loadProfile: $e');
      debugPrint('Stack: $stack');
      _errorMessage = 'Impossible de charger le profil';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sauvegarde le profil complet AVEC gestion du logo
  Future<bool> saveProfile(UserProfile profile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('💾 [COMPANY PROFILE VM] Sauvegarde profil: ${profile.companyName}');
      
      String? finalLogoUrl = profile.companyLogo;

      // ===== ÉTAPE 1: Upload du nouveau logo si sélectionné =====
      if (_selectedLogoFile != null) {
        debugPrint('📤 [COMPANY PROFILE VM] Upload du nouveau logo...');
        
        _isUploadingLogo = true;
        notifyListeners();

        try {
          // Upload du logo vers Firebase Storage
          finalLogoUrl = await _imageUploadService.uploadCompanyLogo(
            imageFile: _selectedLogoFile!,
            userId: profile.userId,
          );

          if (finalLogoUrl != null) {
            debugPrint('✅ [COMPANY PROFILE VM] Logo uploadé: $finalLogoUrl');
            
            // Supprimer l'ancien logo s'il existe et est différent
            if (profile.companyLogo != null && 
                profile.companyLogo != finalLogoUrl &&
                profile.companyLogo!.isNotEmpty) {
              debugPrint('🗑️ [COMPANY PROFILE VM] Suppression ancien logo: ${profile.companyLogo}');
              await _imageUploadService.deleteCompanyLogo(profile.companyLogo!);
            }
          } else {
            debugPrint('❌ [COMPANY PROFILE VM] Échec upload logo');
            _errorMessage = 'Erreur lors de l\'upload du logo';
            _isUploadingLogo = false;
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (uploadError) {
          debugPrint('❌ [COMPANY PROFILE VM] Erreur upload logo: $uploadError');
          _errorMessage = 'Erreur lors de l\'upload du logo';
          _isUploadingLogo = false;
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _isUploadingLogo = false;
        notifyListeners();
      }

      // ===== ÉTAPE 2: Créer le profil avec l'URL du logo =====
      final updatedProfile = profile.copyWith(
        companyLogo: finalLogoUrl,
        updatedAt: DateTime.now(),
      );

      // ===== ÉTAPE 3: Sauvegarder dans Firebase Database =====
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _databaseRef
          .child('users')
          .child(userId)
          .child('profile')
          .set(updatedProfile.toMap());

      _profile = updatedProfile;
      _selectedLogoUrl = finalLogoUrl;
      _selectedLogoFile = null; // Reset le fichier temporaire
      
      debugPrint('✅ [COMPANY PROFILE VM] Profil sauvegardé avec succès');
      return true;
    } catch (e, stack) {
      debugPrint('❌ [COMPANY PROFILE VM] Erreur saveProfile: $e');
      debugPrint('Stack: $stack');
      _errorMessage = 'Erreur lors de la sauvegarde';
      return false;
    } finally {
      _isLoading = false;
      _isUploadingLogo = false;
      notifyListeners();
    }
  }

  /// Met à jour des champs spécifiques du profil
  Future<bool> updateFields(Map<String, dynamic> updates) async {
    try {
      debugPrint('🔧 [COMPANY PROFILE VM] Mise à jour: ${updates.keys.join(", ")}');
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Ajouter la date de mise à jour
      updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await _databaseRef
          .child('users')
          .child(userId)
          .child('profile')
          .update(updates);
      
      // Recharger le profil après la mise à jour
      await loadProfile();

      debugPrint('✅ [COMPANY PROFILE VM] Champs mis à jour');
      return true;
    } catch (e, stack) {
      debugPrint('❌ [COMPANY PROFILE VM] Erreur updateFields: $e');
      debugPrint('Stack: $stack');
      _errorMessage = 'Impossible de mettre à jour le profil';
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // GESTION DU LOGO
  // ============================================================================

  /// Sélectionne un logo (appelé depuis l'UI via LogoPickerWidget)
  void selectLogo(File imageFile) {
    debugPrint('🖼️ [COMPANY PROFILE VM] Logo sélectionné: ${imageFile.path}');
    _selectedLogoFile = imageFile;
    // Ne pas effacer _selectedLogoUrl pour garder l'ancien logo visible si besoin
    notifyListeners();
  }

  /// Supprime le logo sélectionné (avant sauvegarde)
  void removeLogo() {
    debugPrint('🗑️ [COMPANY PROFILE VM] Suppression logo sélectionné');
    _selectedLogoFile = null;
    _selectedLogoUrl = null;
    notifyListeners();
  }

  /// Supprime complètement le logo de l'entreprise (après sauvegarde)
  Future<bool> deleteLogo() async {
    if (_profile?.companyLogo == null && _selectedLogoUrl == null) {
      debugPrint('⚠️ [COMPANY PROFILE VM] Aucun logo à supprimer');
      return false;
    }

    try {
      debugPrint('🗑️ [COMPANY PROFILE VM] Suppression du logo...');
      
      final logoUrl = _profile?.companyLogo ?? _selectedLogoUrl;
      
      if (logoUrl != null && logoUrl.isNotEmpty) {
        // Supprimer de Firebase Storage
        final deleted = await _imageUploadService.deleteCompanyLogo(logoUrl);
        
        if (deleted) {
          debugPrint('✅ [COMPANY PROFILE VM] Logo supprimé du Storage');
          
          // Mettre à jour le profil sans le logo
          if (_profile != null) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId == null) {
              throw Exception('Utilisateur non connecté');
            }

            await _databaseRef
                .child('users')
                .child(userId)
                .child('profile')
                .update({
              'companyLogo': null,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            });

            _profile = _profile!.copyWith(
              companyLogo: null,
              updatedAt: DateTime.now(),
            );
            
            debugPrint('✅ [COMPANY PROFILE VM] Profil mis à jour sans logo');
          }
        }
        
        _selectedLogoUrl = null;
        _selectedLogoFile = null;
        notifyListeners();
        
        return deleted;
      }
      
      return false;
    } catch (e, stack) {
      debugPrint('❌ [COMPANY PROFILE VM] Erreur deleteLogo: $e');
      debugPrint('Stack: $stack');
      _errorMessage = 'Impossible de supprimer le logo';
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // UTILITAIRES
  // ============================================================================

  /// Vérifie si le profil existe
  Future<bool> checkProfileExists() async {
    try {
      debugPrint('🔍 [COMPANY PROFILE VM] Vérification existence profil...');
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return false;
      }

      final snapshot = await _databaseRef
          .child('users')
          .child(userId)
          .child('profile')
          .get();
      
      final exists = snapshot.exists;
      debugPrint('📋 [COMPANY PROFILE VM] Profil existe: $exists');
      return exists;
    } catch (e) {
      debugPrint('❌ [COMPANY PROFILE VM] Erreur checkProfileExists: $e');
      return false;
    }
  }

  /// Crée un profil par défaut
  Future<void> createDefaultProfile() async {
    try {
      debugPrint('🆕 [COMPANY PROFILE VM] Création profil par défaut');
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final defaultProfile = UserProfile(
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _databaseRef
          .child('users')
          .child(userId)
          .child('profile')
          .set(defaultProfile.toMap());
      
      await loadProfile();

      debugPrint('✅ [COMPANY PROFILE VM] Profil par défaut créé');
    } catch (e, stack) {
      debugPrint('❌ [COMPANY PROFILE VM] Erreur createDefaultProfile: $e');
      debugPrint('Stack: $stack');
      _errorMessage = 'Impossible de créer le profil';
      notifyListeners();
    }
  }

  /// Réinitialise les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Réinitialise complètement le ViewModel
  void reset() {
    _profile = null;
    _isLoading = false;
    _isUploadingLogo = false;
    _errorMessage = null;
    _selectedLogoFile = null;
    _selectedLogoUrl = null;
    notifyListeners();
  }
}