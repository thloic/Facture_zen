import 'package:flutter/foundation.dart';
import '../../../common/services/auth_service.dart';

/// RegisterViewModel
/// Gère l'état et la logique de présentation de l'écran d'inscription
/// Respecte l'architecture MVVM - cette classe est le ViewModel
/// Utilise Provider pour la gestion d'état
class RegisterViewModel extends ChangeNotifier {
  // Service d'authentification injecté
  final AuthService _authService;

  // État de la vue
  bool _isLoading = false;
  String? _errorMessage;

  // Getters pour exposer l'état à la View
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Constructeur avec injection du service
  RegisterViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  /// Tente d'inscrire l'utilisateur avec ses informations
  /// Gère la logique métier de validation et d'enregistrement
  /// @param firstName Le prénom de l'utilisateur
  /// @param lastName Le nom de l'utilisateur
  /// @param email L'adresse email de l'utilisateur
  /// @param password Le mot de passe de l'utilisateur
  /// @param confirmPassword La confirmation du mot de passe
  /// @return true si l'inscription réussit, false sinon
  Future<bool> register({
    required String firstName,
    required String lastName,
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
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      )) {
        return false;
      }

      // Appel au service d'authentification Firebase
      final user = await _authService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (user != null) {
        debugPrint('✅ Inscription réussie pour: ${user.email}');
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Échec de l\'inscription';
        _setLoading(false);
        return false;
      }

    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      debugPrint('❌ Erreur inscription: $e');
      return false;
    }
  }

  /// Valide toutes les entrées utilisateur
  /// @return true si toutes les entrées sont valides, false sinon
  bool _validateInputs({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    // Validation du prénom
    if (firstName.trim().isEmpty) {
      _errorMessage = 'Veuillez entrer votre prénom';
      _setLoading(false);
      return false;
    }

    if (firstName.trim().length < 2) {
      _errorMessage = 'Le prénom doit contenir au moins 2 caractères';
      _setLoading(false);
      return false;
    }

    // Validation du nom
    if (lastName.trim().isEmpty) {
      _errorMessage = 'Veuillez entrer votre nom';
      _setLoading(false);
      return false;
    }

    if (lastName.trim().length < 2) {
      _errorMessage = 'Le nom doit contenir au moins 2 caractères';
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