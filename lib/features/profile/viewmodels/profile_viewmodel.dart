import 'package:flutter/foundation.dart';

class ProfileViewModel extends ChangeNotifier {
  // Services injectés
  // final AuthService _authService;
  // final UserService _userService;

  // Données utilisateur
  String? _userName;
  String? _userEmail;
  String? _userAvatarUrl;
  String? _userCompanyName;
  String? _userCompanyAddress;

  // État de la vue
  bool _isLoading = false;
  String? _errorMessage;

  // Getters pour exposer l'état à la View
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userAvatarUrl => _userAvatarUrl;
  String? get userCompanyName => _userCompanyName;
  String? get userCompanyAddress => _userCompanyAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // TODO: Injection des services
  // ProfileViewModel(this._authService, this._userService);

  /// Charge les informations du profil utilisateur
  Future<void> loadUserProfile() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // TODO: Récupérer les infos depuis Firebase/API
      // final user = await _userService.getCurrentUser();
      // _userName = user.name;
      // _userEmail = user.email;
      // _userAvatarUrl = user.avatarUrl;
      // _userCompanyName = user.companyName;
      // _userCompanyAddress = user.companyAddress;

      // Données de test pour le moment
      await Future.delayed(const Duration(seconds: 1));
      _userName = 'Maxine Watson';
      _userEmail = 'maxinewatson@gmail.com';
      _userAvatarUrl = null; // Pas d'image pour l'instant
      _userCompanyName = 'Watson Consulting';
      _userCompanyAddress = '123 Rue de la Paix, Paris';

      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Impossible de charger le profil';
      _setLoading(false);
      debugPrint('Erreur chargement profil: $e');
    }
  }

  /// Met à jour les informations du profil
  /// @param name Nouveau nom
  /// @param companyName Nouveau nom d'entreprise
  /// @param companyAddress Nouvelle adresse
  Future<bool> updateProfile({
    String? name,
    String? companyName,
    String? companyAddress,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // TODO: Mettre à jour dans Firebase/API
      // await _userService.updateUserProfile(
      //   name: name,
      //   companyName: companyName,
      //   companyAddress: companyAddress,
      // );

      // Simulation
      await Future.delayed(const Duration(seconds: 1));

      if (name != null) _userName = name;
      if (companyName != null) _userCompanyName = companyName;
      if (companyAddress != null) _userCompanyAddress = companyAddress;

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Impossible de mettre à jour le profil';
      _setLoading(false);
      debugPrint('Erreur mise à jour profil: $e');
      return false;
    }
  }

  /// Met à jour la photo de profil
  /// @param imagePath Chemin vers la nouvelle image
  Future<bool> updateAvatar(String imagePath) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // TODO: Upload de l'image et mise à jour
      // final uploadedUrl = await _userService.uploadAvatar(imagePath);
      // _userAvatarUrl = uploadedUrl;

      // Simulation
      await Future.delayed(const Duration(seconds: 2));
      _userAvatarUrl = imagePath;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Impossible de mettre à jour la photo';
      _setLoading(false);
      debugPrint('Erreur upload avatar: $e');
      return false;
    }
  }

  /// Déconnecte l'utilisateur
  Future<void> logout() async {
    try {
      // TODO: Déconnexion Firebase
      // await _authService.signOut();

      // Réinitialiser les données
      _userName = null;
      _userEmail = null;
      _userAvatarUrl = null;
      _userCompanyName = null;
      _userCompanyAddress = null;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors de la déconnexion';
      debugPrint('Erreur déconnexion: $e');
      notifyListeners();
    }
  }

  /// Supprime le compte utilisateur
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // TODO: Supprimer le compte Firebase
      // await _authService.deleteAccount();

      // Simulation
      await Future.delayed(const Duration(seconds: 2));

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Impossible de supprimer le compte';
      _setLoading(false);
      debugPrint('Erreur suppression compte: $e');
      return false;
    }
  }

  /// Change le mot de passe
  /// @param currentPassword Mot de passe actuel
  /// @param newPassword Nouveau mot de passe
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Validation
      if (newPassword.length < 6) {
        _errorMessage = 'Le mot de passe doit contenir au moins 6 caractères';
        _setLoading(false);
        return false;
      }

      // TODO: Changer le mot de passe Firebase
      // await _authService.updatePassword(currentPassword, newPassword);

      // Simulation
      await Future.delayed(const Duration(seconds: 1));

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Impossible de changer le mot de passe';
      _setLoading(false);
      debugPrint('Erreur changement mot de passe: $e');
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