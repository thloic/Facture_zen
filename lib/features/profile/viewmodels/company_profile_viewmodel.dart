import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../services/firebase_profile_service.dart';

/// ViewModel pour gérer le profil entreprise de l'utilisateur
class CompanyProfileViewModel extends ChangeNotifier {
  final FirebaseProfileService _profileService;

  // État
  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasProfile => _profile != null;

  /// Constructeur avec injection du service
  CompanyProfileViewModel({FirebaseProfileService? profileService})
      : _profileService = profileService ?? FirebaseProfileService();

  /// Charge le profil utilisateur
  Future<void> loadProfile() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('📥 [COMPANY PROFILE VM] Chargement du profil...');
      
      _profile = await _profileService.getUserProfile();

      if (_profile != null) {
        debugPrint('✅ [COMPANY PROFILE VM] Profil chargé: ${_profile!.companyName}');
      } else {
        debugPrint('📭 [COMPANY PROFILE VM] Aucun profil trouvé');
      }

      _setLoading(false);
    } catch (e, stack) {
      debugPrint('❌ [COMPANY PROFILE VM] Erreur loadProfile: $e');
      debugPrint('Stack: $stack');
      _errorMessage = 'Impossible de charger le profil';
      _setLoading(false);
    }
  }

  /// Sauvegarde le profil complet
  Future<bool> saveProfile(UserProfile profile) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('💾 [COMPANY PROFILE VM] Sauvegarde profil: ${profile.companyName}');
      
      await _profileService.saveUserProfile(profile);
      _profile = profile;

      debugPrint('✅ [COMPANY PROFILE VM] Profil sauvegardé');
      _setLoading(false);
      return true;
    } catch (e, stack) {
      debugPrint('❌ [COMPANY PROFILE VM] Erreur saveProfile: $e');
      debugPrint('Stack: $stack');
      _errorMessage = 'Impossible de sauvegarder le profil';
      _setLoading(false);
      return false;
    }
  }

  /// Met à jour des champs spécifiques du profil
  Future<bool> updateFields(Map<String, dynamic> updates) async {
    try {
      debugPrint('🔧 [COMPANY PROFILE VM] Mise à jour: ${updates.keys.join(", ")}');
      
      await _profileService.updateProfile(updates);
      
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

  /// Vérifie si le profil existe
  Future<bool> checkProfileExists() async {
    try {
      debugPrint('🔍 [COMPANY PROFILE VM] Vérification existence profil...');
      
      final exists = await _profileService.hasProfile();
      
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
      
      await _profileService.createDefaultProfile();
      await loadProfile();

      debugPrint('✅ [COMPANY PROFILE VM] Profil par défaut créé');
    } catch (e) {
      debugPrint('❌ [COMPANY PROFILE VM] Erreur createDefaultProfile: $e');
      _errorMessage = 'Impossible de créer le profil';
      notifyListeners();
    }
  }

  /// Définit l'état de chargement
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Réinitialise les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
