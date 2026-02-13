import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../common/models/user_model.dart';
import '../../../common/services/auth_service.dart';
import '../../../common/services/pin_service.dart';
import '../../invoicing/services/subscription_sync_service.dart';

/// ProfileViewModel
/// Gère l'état et la logique du profil utilisateur
/// Respecte l'architecture MVVM - cette classe est le ViewModel
class ProfileViewModel extends ChangeNotifier {
  // Services injectés
  final AuthService _authService;
  final SubscriptionSyncService _subscriptionService = SubscriptionSyncService();

  // Données utilisateur
  UserModel? _currentUser;
  String? _userAvatarUrl;

  // ✅ NOUVEAU : Données d'abonnement
  SubscriptionPlan? _currentPlan;
  bool _isLoadingPlan = false;

  // État de la vue
  bool _isLoading = false;
  String? _errorMessage;

  // Getters pour exposer l'état à la View
  String? get userName => _currentUser?.companyName ?? 'Utilisateur';
  String? get userEmail => _currentUser?.email;
  String? get userAvatarUrl => _userAvatarUrl;
  String? get userCompanyName => _currentUser?.companyName;
  String? get companyName => _currentUser?.companyName;
  String? get firstName => _currentUser?.firstName;
  String? get lastName => _currentUser?.lastName;
  String? get userCompanyAddress => _currentUser?.companyAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  User? get firebaseUser => _authService.currentUser;

  // ✅ NOUVEAU : Getters pour l'abonnement
  SubscriptionPlan? get currentPlan => _currentPlan;
  bool get isLoadingPlan => _isLoadingPlan;

  /// Constructeur avec injection du service
  ProfileViewModel({AuthService? authService})
      : _authService = authService ?? AuthService() {
    // Charger automatiquement le profil au démarrage
    loadUserProfile();
    // ✅ NOUVEAU : Charger le plan d'abonnement
    _loadSubscriptionPlan();
  }

  /// ✅ NOUVEAU : Charge le plan d'abonnement actuel
  Future<void> _loadSubscriptionPlan() async {
    _isLoadingPlan = true;
    notifyListeners();

    try {
      debugPrint('🔄 Chargement du plan d\'abonnement...');

      // Synchroniser le statut avec RevenueCat
      await _subscriptionService.syncSubscriptionStatus();

      // Récupérer le plan actuel
      _currentPlan = await _subscriptionService.getCurrentPlan();

      debugPrint('✅ Plan chargé: ${_currentPlan?.name}');
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement du plan: $e');
      // En cas d'erreur, utiliser le plan gratuit par défaut
      _currentPlan = SubscriptionSyncService.PLAN_LIMITS['zen_gratuit'];
    } finally {
      _isLoadingPlan = false;
      notifyListeners();
    }
  }

  /// ✅ NOUVEAU : Rafraîchir le plan (à appeler après un changement d'abonnement)
  Future<void> refreshSubscriptionPlan() async {
    debugPrint('🔄 Rafraîchissement du plan...');
    await _loadSubscriptionPlan();
  }

  /// Charge les informations du profil utilisateur depuis Firebase
  Future<void> loadUserProfile() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('🔥 Chargement du profil utilisateur...');

      // Récupérer l'utilisateur Firebase Auth actuel
      final user = _authService.currentUser;

      if (user == null) {
        _errorMessage = 'Aucun utilisateur connecté';
        _setLoading(false);
        
        debugPrint('❌ Aucun utilisateur connecté');
        return;
      }

      debugPrint('✅ Utilisateur Firebase Auth: ${user.uid}');
      debugPrint('📧 Email: ${user.email}');

      // Récupérer les données depuis Realtime Database
      final userData = await _authService.getUserData(user.uid);

      if (userData != null) {
        _currentUser = UserModel.fromJson(user.uid, userData);
        debugPrint('✅ Profil chargé avec succès');
        debugPrint('👤 Nom entreprise: ${_currentUser?.companyName}');
        debugPrint('📍 Adresse: ${_currentUser?.companyAddress}');
      } else {
        debugPrint(
          '⚠️ Aucune donnée dans Realtime Database pour cet utilisateur',
        );
        // Créer un UserModel minimal avec les infos de Firebase Auth
        _currentUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          companyName: 'Entreprise',
          companyAddress: 'Adresse non renseignée',
          createdAt: DateTime.now(),
        );
      }

      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Impossible de charger le profil';
      _setLoading(false);
      debugPrint('❌ Erreur chargement profil: $e');
    }
  }

  /// Met à jour les informations du profil
  /// @param companyName Nouveau nom d'entreprise
  /// @param companyAddress Nouvelle adresse d'entreprise
  /// @param firstName Nouveau prénom
  /// @param lastName Nouveau nom
  Future<bool> updateProfile({
    String? companyName,
    String? companyAddress,
    String? firstName,
    String? lastName,
  }) async {
    if (_currentUser == null) {
      _errorMessage = 'Aucun utilisateur connecté';
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('🔥 Mise à jour du profil...');

      // Préparer les données à mettre à jour
      final Map<String, dynamic> updateData = {};

      if (companyName != null && companyName.isNotEmpty) {
        updateData['companyName'] = companyName;
      }

      if (companyAddress != null && companyAddress.isNotEmpty) {
        updateData['companyAddress'] = companyAddress;
      }

      if (firstName != null && firstName.isNotEmpty) {
        updateData['firstName'] = firstName;
      }

      if (lastName != null && lastName.isNotEmpty) {
        updateData['lastName'] = lastName;
      }

      if (updateData.isEmpty) {
        _errorMessage = 'Aucune modification à enregistrer';
        _setLoading(false);
        return false;
      }

      // Mettre à jour dans Firebase Realtime Database
      await _authService.updateUserData(_currentUser!.uid, updateData);

      // Mettre à jour le modèle local
      _currentUser = _currentUser!.copyWith(
        companyName: companyName ?? _currentUser!.companyName,
        companyAddress: companyAddress ?? _currentUser!.companyAddress,
        firstName: firstName ?? _currentUser!.firstName,
        lastName: lastName ?? _currentUser!.lastName,
      );

      debugPrint('✅ Profil mis à jour avec succès');
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Impossible de mettre à jour le profil';
      _setLoading(false);
      debugPrint('❌ Erreur mise à jour profil: $e');
      return false;
    }
  }

  /// Met à jour la photo de profil
  /// @param imagePath Chemin vers la nouvelle image
  Future<bool> updateAvatar(String imagePath) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // TODO: Upload vers Firebase Storage
      // final uploadedUrl = await _storageService.uploadAvatar(imagePath);
      // _userAvatarUrl = uploadedUrl;

      // Simulation pour le moment
      await Future.delayed(const Duration(seconds: 2));
      _userAvatarUrl = imagePath;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Impossible de mettre à jour la photo';
      _setLoading(false);
      debugPrint('❌ Erreur upload avatar: $e');
      return false;
    }
  }

  /// Déconnecte l'utilisateur
  Future<void> logout() async {
    try {
      debugPrint('🔥 Déconnexion en cours...');

      // NE PAS supprimer le PIN - il reste pour les prochaines connexions
      // Le PIN permet de se reconnecter rapidement sans email/password

      // Réinitialiser les tentatives échouées du PIN
      final pinService = PinService();
      await pinService.resetFailedAttempts();

      // Déconnexion Firebase
      await _authService.signOut();

      // Réinitialiser les données locales
      _currentUser = null;
      _userAvatarUrl = null;
      _currentPlan = null;

      debugPrint('✅ Déconnexion réussie (PIN conservé)');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors de la déconnexion';
      debugPrint('❌ Erreur déconnexion: $e');
      notifyListeners();
    }
  }

  /// Supprime le compte utilisateur
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('🔥 Suppression du compte...');

      // Supprimer le compte Firebase
      await _authService.deleteAccount();

      // Réinitialiser les données
      _currentUser = null;
      _userAvatarUrl = null;
      _currentPlan = null;

      debugPrint('✅ Compte supprimé');
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Impossible de supprimer le compte';
      _setLoading(false);
      debugPrint('❌ Erreur suppression compte: $e');
      return false;
    }
  }

  /// Change le mot de passe
  /// @param currentPassword Mot de passe actuel
  /// @param newPassword Nouveau mot de passe
  Future<bool> changePassword(
      String currentPassword,
      String newPassword,
      ) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Validation
      if (newPassword.length < 6) {
        _errorMessage = 'Le mot de passe doit contenir au moins 6 caractères';
        _setLoading(false);
        return false;
      }

      debugPrint('🔥 Changement du mot de passe...');

      // Récupérer l'utilisateur actuel
      final user = _authService.currentUser;
      if (user == null || user.email == null) {
        _errorMessage = 'Utilisateur non connecté';
        _setLoading(false);
        return false;
      }

      // Réauthentifier l'utilisateur avec le mot de passe actuel
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await user.updatePassword(newPassword);

      debugPrint('✅ Mot de passe changé avec succès');
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _errorMessage = 'Mot de passe actuel incorrect';
      } else {
        _errorMessage = 'Impossible de changer le mot de passe';
      }
      _setLoading(false);
      debugPrint('❌ Erreur changement mot de passe: ${e.code}');
      return false;
    } catch (e) {
      _errorMessage = 'Impossible de changer le mot de passe';
      _setLoading(false);
      debugPrint('❌ Erreur changement mot de passe: $e');
      return false;
    }
  }

  /// Modifie l'état de chargement et notifie les listeners
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Réinitialise le message d'erreur
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Nettoyage lors de la destruction du ViewModel
  @override
  void dispose() {
    super.dispose();
  }
}