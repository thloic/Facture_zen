import 'package:flutter/material.dart';
import '../../../common/services/pin_service.dart';
import '../../../common/widgets/app_logo.dart';
import '../../../common/utils/responsive_utils.dart';

/// PinSetupScreen
/// Écran de configuration du code PIN à 4 chiffres
/// Affiché après la première inscription
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({Key? key}) : super(key: key);

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final PinService _pinService = PinService();
  
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmationStep = false;
  String? _errorMessage;
  bool _isLoading = false;

  /// Ajoute un chiffre au PIN
  void _addDigit(String digit) {
    if (_isLoading) return;

    setState(() {
      _errorMessage = null;
      
      if (_isConfirmationStep) {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
          
          // Vérifier automatiquement quand 4 chiffres sont entrés
          if (_confirmPin.length == 4) {
            _verifyAndSavePin();
          }
        }
      } else {
        if (_pin.length < 4) {
          _pin += digit;
          
          // Passer à la confirmation quand 4 chiffres sont entrés
          if (_pin.length == 4) {
            Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                _isConfirmationStep = true;
              });
            });
          }
        }
      }
    });
  }

  /// Efface le dernier chiffre
  void _removeDigit() {
    if (_isLoading) return;

    setState(() {
      _errorMessage = null;
      
      if (_isConfirmationStep) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  /// Vérifie et sauvegarde le PIN
  Future<void> _verifyAndSavePin() async {
    if (_pin != _confirmPin) {
      setState(() {
        _errorMessage = 'Les codes PIN ne correspondent pas';
        _confirmPin = '';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _pinService.savePin(_pin);
      
      if (success && mounted) {
        // PIN créé avec succès, rediriger vers l'accueil
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de la sauvegarde du PIN';
          _isLoading = false;
          _confirmPin = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Une erreur est survenue';
        _isLoading = false;
        _confirmPin = '';
      });
    }
  }

  /// Recommence la configuration du PIN
  void _restart() {
    setState(() {
      _pin = '';
      _confirmPin = '';
      _isConfirmationStep = false;
      _errorMessage = null;
    });
  }

  /// Passer cette étape (pour l'instant)
  void _skip() {
    Navigator.pushReplacementNamed(context, '/home');
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

                        // Titre et instruction
                        Text(
                          _isConfirmationStep ? 'Confirmez votre code PIN' : 'Créez votre code PIN',
                          style: TextStyle(
                            fontSize: responsive.getAdaptiveTextSize(22),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.01),

                        Text(
                          _isConfirmationStep
                              ? 'Entrez à nouveau votre code PIN'
                              : 'Vous pourrez vous connecter rapidement avec ce code',
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

                        // Bouton passer
                        if (!_isConfirmationStep)
                          TextButton(
                            onPressed: _skip,
                            child: Text(
                              'Passer pour l\'instant',
                              style: TextStyle(
                                color: const Color(0xFF6B7280),
                                fontSize: responsive.getAdaptiveTextSize(14),
                              ),
                            ),
                          ),

                        // Bouton recommencer (en mode confirmation)
                        if (_isConfirmationStep)
                          TextButton(
                            onPressed: _restart,
                            child: Text(
                              'Recommencer',
                              style: TextStyle(
                                color: const Color(0xFF5B5FC7),
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
    final currentPin = _isConfirmationStep ? _confirmPin : _pin;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < currentPin.length;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? const Color(0xFF5B5FC7) : Colors.transparent,
            border: Border.all(
              color: isFilled ? const Color(0xFF5B5FC7) : const Color(0xFFD1D5DB),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  /// Widget - Clavier numérique 3x4
  Widget _buildNumericKeypad(ResponsiveUtils responsive, double buttonSize) {
    final spacing = 12.0;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ligne 1: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('1', responsive, buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton('2', responsive, buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton('3', responsive, buttonSize),
          ],
        ),
        SizedBox(height: spacing),
        // Ligne 2: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('4', responsive, buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton('5', responsive, buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton('6', responsive, buttonSize),
          ],
        ),
        SizedBox(height: spacing),
        // Ligne 3: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('7', responsive, buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton('8', responsive, buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton('9', responsive, buttonSize),
          ],
        ),
        SizedBox(height: spacing),
        // Ligne 4: vide, 0, effacer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: buttonSize, height: buttonSize), // Espace vide
            SizedBox(width: spacing),
            _buildKeypadButton('0', responsive, buttonSize),
            SizedBox(width: spacing),
            _buildDeleteButton(responsive, buttonSize),
          ],
        ),
      ],
    );
  }

  /// Widget - Bouton du clavier numérique
  Widget _buildKeypadButton(String digit, ResponsiveUtils responsive, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : () => _addDigit(digit),
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
                  color: _isLoading ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget - Bouton effacer
  Widget _buildDeleteButton(ResponsiveUtils responsive, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _removeDigit,
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
                color: _isLoading ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
