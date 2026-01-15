import 'package:flutter/material.dart';
import '../../../common/services/pin_service.dart';
import '../../../common/services/auth_service.dart';
import '../../../common/widgets/app_logo.dart';
import '../../../common/utils/responsive_utils.dart';

/// PinLoginScreen
/// Écran de connexion par code PIN à 4 chiffres
/// Utilisé pour les connexions rapides après configuration
class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({Key? key}) : super(key: key);

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final PinService _pinService = PinService();
  final AuthService _authService = AuthService();
  
  String _pin = '';
  String? _errorMessage;
  bool _isLoading = false;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _loadFailedAttempts();
  }

  /// Charge le nombre de tentatives échouées
  Future<void> _loadFailedAttempts() async {
    final attempts = await _pinService.getFailedAttempts();
    setState(() {
      _failedAttempts = attempts;
    });
  }

  /// Ajoute un chiffre au PIN
  void _addDigit(String digit) {
    if (_isLoading || _failedAttempts >= 3) return;

    setState(() {
      _errorMessage = null;
      
      if (_pin.length < 4) {
        _pin += digit;
        
        // Vérifier automatiquement quand 4 chiffres sont entrés
        if (_pin.length == 4) {
          _verifyPin();
        }
      }
    });
  }

  /// Efface le dernier chiffre
  void _removeDigit() {
    if (_isLoading) return;

    setState(() {
      _errorMessage = null;
      
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  /// Vérifie le PIN et connecte l'utilisateur
  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    try {
      final isValid = await _pinService.verifyPin(_pin);
      
      if (isValid) {
        // PIN correct - réinitialiser les tentatives
        await _pinService.resetFailedAttempts();
        
        // Vérifier que l'utilisateur est toujours connecté à Firebase
        if (_authService.isAuthenticated && mounted) {
          // Rediriger vers l'accueil
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Session Firebase expirée, rediriger vers login
          setState(() {
            _errorMessage = 'Session expirée, veuillez vous reconnecter';
            _isLoading = false;
            _pin = '';
          });
          
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        }
      } else {
        // PIN incorrect
        await _pinService.incrementFailedAttempts();
        final attempts = await _pinService.getFailedAttempts();
        
        setState(() {
          _failedAttempts = attempts;
          _isLoading = false;
          _pin = '';
          
          if (_failedAttempts >= 3) {
            _errorMessage = 'Trop de tentatives. Utilisez votre email et mot de passe.';
          } else {
            _errorMessage = 'Code PIN incorrect (${3 - _failedAttempts} tentative${3 - _failedAttempts > 1 ? 's' : ''} restante${3 - _failedAttempts > 1 ? 's' : ''})';
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Une erreur est survenue';
        _isLoading = false;
        _pin = '';
      });
    }
  }

  /// Rediriger vers la connexion par email/password
  void _usePasswordLogin() async {
    // Réinitialiser les tentatives échouées
    await _pinService.resetFailedAttempts();
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.horizontalPadding,
            vertical: 24,
          ),
          child: Column(
            children: [
              // Logo
              AppLogo(fontSize: responsive.getAdaptiveTextSize(24)),
              
              SizedBox(height: responsive.getAdaptiveSpacing(48)),

              // Titre
              Text(
                'Entrez votre code PIN',
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(24),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              
              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              Text(
                'Entrez votre code à 4 chiffres',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(14),
                  color: const Color(0xFF6B7280),
                ),
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(48)),

              // Affichage des points du PIN
              _buildPinDisplay(responsive),

              if (_errorMessage != null) ...[
                SizedBox(height: responsive.getAdaptiveSpacing(16)),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFEF4444),
                    fontSize: responsive.getAdaptiveTextSize(14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              SizedBox(height: responsive.getAdaptiveSpacing(48)),

              // Clavier numérique
              Expanded(
                child: _buildNumericKeypad(responsive),
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(24)),

              // Bouton "Utiliser le mot de passe"
              TextButton(
                onPressed: _usePasswordLogin,
                child: Text(
                  _failedAttempts >= 3 
                      ? 'Connexion par email et mot de passe'
                      : 'Code PIN oublié ?',
                  style: TextStyle(
                    color: _failedAttempts >= 3 
                        ? const Color(0xFFEF4444) 
                        : const Color(0xFF5B5FC7),
                    fontSize: responsive.getAdaptiveTextSize(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget - Affichage des 4 points du PIN
  Widget _buildPinDisplay(ResponsiveUtils responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _pin.length;
        final hasError = _errorMessage != null;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled 
                ? (hasError ? const Color(0xFFEF4444) : const Color(0xFF5B5FC7))
                : Colors.transparent,
            border: Border.all(
              color: isFilled
                  ? (hasError ? const Color(0xFFEF4444) : const Color(0xFF5B5FC7))
                  : const Color(0xFFD1D5DB),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  /// Widget - Clavier numérique 3x4
  Widget _buildNumericKeypad(ResponsiveUtils responsive) {
    final isDisabled = _isLoading || _failedAttempts >= 3;
    
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildKeypadButton('1', responsive, isDisabled),
        _buildKeypadButton('2', responsive, isDisabled),
        _buildKeypadButton('3', responsive, isDisabled),
        _buildKeypadButton('4', responsive, isDisabled),
        _buildKeypadButton('5', responsive, isDisabled),
        _buildKeypadButton('6', responsive, isDisabled),
        _buildKeypadButton('7', responsive, isDisabled),
        _buildKeypadButton('8', responsive, isDisabled),
        _buildKeypadButton('9', responsive, isDisabled),
        const SizedBox(), // Espace vide
        _buildKeypadButton('0', responsive, isDisabled),
        _buildDeleteButton(responsive, isDisabled),
      ],
    );
  }

  /// Widget - Bouton du clavier numérique
  Widget _buildKeypadButton(String digit, ResponsiveUtils responsive, bool isDisabled) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : () => _addDigit(digit),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(28),
                fontWeight: FontWeight.w600,
                color: isDisabled ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget - Bouton effacer
  Widget _buildDeleteButton(ResponsiveUtils responsive, bool isDisabled) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : _removeDigit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: responsive.getAdaptiveTextSize(28),
              color: isDisabled ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}
