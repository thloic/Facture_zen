import 'package:flutter/foundation.dart';
import '../../../common/services/auth_service.dart';

/// ForgotPasswordViewModel
/// Gère la logique de réinitialisation du mot de passe
class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;

  ForgotPasswordViewModel({AuthService? authService})
    : _authService = authService ?? AuthService();

  /// Envoie un email de réinitialisation du mot de passe
  Future<bool> resetPassword(String email) async {
    _errorMessage = null;
    _successMessage = null;
    _setLoading(true);

    try {
      // Validation de l'email
      if (!_validateEmail(email)) {
        return false;
      }

      // Envoyer l'email de réinitialisation
      await _authService.resetPassword(email);

      _successMessage =
          'Un email de réinitialisation a été envoyé à $email. Vérifiez votre boîte de réception.';
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Valide le format de l'email
  bool _validateEmail(String email) {
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

    return true;
  }

  /// Vérifie si l'email est valide
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Efface les messages d'erreur et de succès
  void clearMessages() {
    if (_errorMessage != null || _successMessage != null) {
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();
    }
  }
}
