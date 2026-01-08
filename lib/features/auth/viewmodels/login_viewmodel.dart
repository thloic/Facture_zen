import 'package:flutter/foundation.dart';
import '../../../common/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  LoginViewModel({AuthService? authService})
    : _authService = authService ?? AuthService();

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    _setLoading(true);

    try {
      if (!_validateInputs(email, password)) {
        return false;
      }

      final user = await _authService.signIn(email: email, password: password);

      if (user != null) {
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Échec de la connexion';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
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

    return true;
  }

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

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Connexion avec Google
  Future<bool> signInWithGoogle() async {
    _errorMessage = null;
    _setLoading(true);

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null) {
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Connexion Google annulée';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
}
