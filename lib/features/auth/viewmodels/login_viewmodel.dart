import 'package:flutter/foundation.dart';

class LoginViewModel extends ChangeNotifier {

  // État de la vue
  bool _isLoading = false;
  String? _errorMessage;

  // Getters pour exposer l'état à la View
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // TODO: Injection du service d'authentification
  // LoginViewModel(this._authService);

  Future<bool> login(String email, String password) async {
    // Réinitialisation de l'état
    _errorMessage = null;
    _setLoading(true);

    try {
      // Validation côté client
      if (!_validateInputs(email, password)) {
        return false;
      }

      // TODO: Appel au service d'authentification Firebase
      // await _authService.signInWithEmailAndPassword(email, password);

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

  bool _validateInputs(String email, String password) {
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

    if (password.trim().isEmpty) {
      _errorMessage = 'Veuillez entrer votre mot de passe';
      _setLoading(false);
      return false;
    }

    if (password.length < 6) {
      _errorMessage = 'Le mot de passe doit contenir au moins 6 caractères';
      _setLoading(false);
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  String _handleAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('user-not-found')) {
      return 'Aucun compte trouvé avec cet email';
    } else if (errorString.contains('wrong-password')) {
      return 'Mot de passe incorrect';
    } else if (errorString.contains('invalid-email')) {
      return 'Format d\'email invalide';
    } else if (errorString.contains('user-disabled')) {
      return 'Ce compte a été désactivé';
    } else if (errorString.contains('too-many-requests')) {
      return 'Trop de tentatives. Réessayez plus tard';
    } else if (errorString.contains('network')) {
      return 'Erreur de connexion. Vérifiez votre internet';
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