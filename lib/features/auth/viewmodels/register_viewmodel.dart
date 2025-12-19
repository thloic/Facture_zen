import 'package:flutter/foundation.dart';


class RegisterViewModel extends ChangeNotifier {
  // Services injectés
  // final AuthService _authService;

  // État de la vue
  bool _isLoading = false;
  String? _errorMessage;

  // Getters pour exposer l'état à la View
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // TODO: Injection du service d'authentification
  // RegisterViewModel(this._authService);


  Future<bool> register({
    required String companyName,
    required String companyAddress,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // Réinitialisation de l'état
    _errorMessage = null;
    _setLoading(true);

    try {
      // Validation côté client
      if (!_validateInputs(
        companyName: companyName,
        companyAddress: companyAddress,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      )) {
        return false;
      }

      // TODO: Appel au service d'authentification Firebase

      // Simulation pour le moment
      await Future.delayed(const Duration(seconds: 2));

      _setLoading(false);
      return true;

    } catch (e) {
      _errorMessage = _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Valide toutes les entrées utilisateur
  /// @return true si toutes les entrées sont valides, false sinon
  bool _validateInputs({
    required String companyName,
    required String companyAddress,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    // Validation du nom de l'entreprise
    if (companyName.trim().isEmpty) {
      _errorMessage = 'Veuillez entrer le nom de votre entreprise';
      _setLoading(false);
      return false;
    }

    if (companyName.trim().length < 2) {
      _errorMessage = 'Le nom de l\'entreprise doit contenir au moins 2 caractères';
      _setLoading(false);
      return false;
    }

    // Validation de l'adresse de l'entreprise
    if (companyAddress.trim().isEmpty) {
      _errorMessage = 'Veuillez entrer l\'adresse de votre entreprise';
      _setLoading(false);
      return false;
    }

    if (companyAddress.trim().length < 5) {
      _errorMessage = 'L\'adresse doit être plus détaillée';
      _setLoading(false);
      return false;
    }

    // Validation de l'email
    if (email.trim().isEmpty) {
      _errorMessage = 'Veuillez entrer votre email';
      _setLoading(false);
      return false;
    }

    if (!_isValidEmail(email)) {
      _errorMessage = 'Format d\'email invalide';
      _setLoading(false);
      return false;
    }

    // Validation du mot de passe
    if (password.trim().isEmpty) {
      _errorMessage = 'Veuillez entrer un mot de passe';
      _setLoading(false);
      return false;
    }

    if (password.length < 6) {
      _errorMessage = 'Le mot de passe doit contenir au moins 6 caractères';
      _setLoading(false);
      return false;
    }

    // Validation de la force du mot de passe
    if (!_isStrongPassword(password)) {
      _errorMessage = 'Le mot de passe doit contenir au moins une lettre et un chiffre';
      _setLoading(false);
      return false;
    }

    // Validation de la confirmation du mot de passe
    if (confirmPassword.trim().isEmpty) {
      _errorMessage = 'Veuillez confirmer votre mot de passe';
      _setLoading(false);
      return false;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Les mots de passe ne correspondent pas';
      _setLoading(false);
      return false;
    }

    return true;
  }

  /// Vérifie si l'email a un format valide
  /// Regex simple pour validation basique
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Vérifie la force du mot de passe
  /// Doit contenir au moins une lettre et un chiffre
  bool _isStrongPassword(String password) {
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    return hasLetter && hasDigit;
  }


  String _handleAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('email-already-in-use')) {
      return 'Cet email est déjà utilisé';
    } else if (errorString.contains('invalid-email')) {
      return 'Format d\'email invalide';
    } else if (errorString.contains('weak-password')) {
      return 'Le mot de passe est trop faible';
    } else if (errorString.contains('network')) {
      return 'Erreur de connexion. Vérifiez votre internet';
    } else if (errorString.contains('too-many-requests')) {
      return 'Trop de tentatives. Réessayez plus tard';
    } else {
      return 'Une erreur est survenue. Veuillez réessayer';
    }
  }

  /// Modifie l'état de chargement et notifie les listeners
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Réinitialise le message d'erreur
  /// Utile pour effacer l'erreur quand l'utilisateur modifie les champs
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