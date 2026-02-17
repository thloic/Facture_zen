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
          // Rediriger vers l'accueil en supprimant tout l'historique
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          // Session Firebase expirée, rediriger vers login
          setState(() {
            _errorMessage = 'Session expirée, veuillez vous reconnecter';
            _isLoading = false;
            _pin = '';
          });
          
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculer la taille des boutons en fonction de l'écran
    final keypadWidth = (screenWidth - responsive.horizontalPadding * 2).clamp(200.0, 300.0);
    final buttonSize = (keypadWidth - 32) / 3; // 3 colonnes avec espacement

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.horizontalPadding,
                      vertical: screenHeight * 0.02,
                    ),
                    child: Column(
                      children: [
                        // Logo
                        AppLogo(fontSize: responsive.getAdaptiveTextSize(24)),
                        
                        SizedBox(height: screenHeight * 0.04),

                        // Titre
                        Text(
                          'Entrez votre code PIN',
                          style: TextStyle(
                            fontSize: responsive.getAdaptiveTextSize(22),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.01),

                        Text(
                          'Entrez votre code à 4 chiffres',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: responsive.getAdaptiveTextSize(14),
                            color: const Color(0xFF6B7280),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.04),

                        // Affichage des points du PIN
                        _buildPinDisplay(responsive),

                        if (_errorMessage != null) ...[
                          SizedBox(height: screenHeight * 0.02),
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

                        SizedBox(height: screenHeight * 0.04),

                        // Clavier numérique centré avec taille fixe
                        Center(
                          child: SizedBox(
                            width: keypadWidth,
                            child: _buildNumericKeypad(responsive, buttonSize),
                          ),
                        ),

                        const Spacer(),

                        SizedBox(height: screenHeight * 0.02),

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
                        
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
  Widget _buildNumericKeypad(ResponsiveUtils responsive, double buttonSize) {
    final isDisabled = _isLoading || _failedAttempts >= 3;
    final spacing = 12.0;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ligne 1: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('1', responsive, isDisabled, buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton('2', responsive, isDisabled, buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton('3', responsive, isDisabled, buttonSize),
          ],
        ),
        SizedBox(height: spacing),
        // Ligne 2: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('4', responsive, isDisabled, buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton('5', responsive, isDisabled, buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton('6', responsive, isDisabled, buttonSize),
          ],
        ),
        SizedBox(height: spacing),
        // Ligne 3: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('7', responsive, isDisabled, buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton('8', responsive, isDisabled, buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton('9', responsive, isDisabled, buttonSize),
          ],
        ),
        SizedBox(height: spacing),
        // Ligne 4: vide, 0, effacer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: buttonSize, height: buttonSize), // Espace vide
            SizedBox(width: spacing),
            _buildKeypadButton('0', responsive, isDisabled, buttonSize),
            SizedBox(width: spacing),
            _buildDeleteButton(responsive, isDisabled, buttonSize),
          ],
        ),
      ],
    );
  }

  /// Widget - Bouton du clavier numérique
  Widget _buildKeypadButton(String digit, ResponsiveUtils responsive, bool isDisabled, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
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
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget - Bouton effacer
  Widget _buildDeleteButton(ResponsiveUtils responsive, bool isDisabled, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
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
                size: size * 0.4,
                color: isDisabled ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
