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

              // Titre et instruction
              Text(
                _isConfirmationStep ? 'Confirmez votre code PIN' : 'Créez votre code PIN',
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(24),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              
              SizedBox(height: responsive.getAdaptiveSpacing(12)),

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

              SizedBox(height: responsive.getAdaptiveSpacing(48)),

              // Affichage des points du PIN
              _buildPinDisplay(responsive),

              if (_errorMessage != null) ...[
                SizedBox(height: responsive.getAdaptiveSpacing(16)),
                Text(
                  _errorMessage!,
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
            ],
          ),
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
  Widget _buildNumericKeypad(ResponsiveUtils responsive) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildKeypadButton('1', responsive),
        _buildKeypadButton('2', responsive),
        _buildKeypadButton('3', responsive),
        _buildKeypadButton('4', responsive),
        _buildKeypadButton('5', responsive),
        _buildKeypadButton('6', responsive),
        _buildKeypadButton('7', responsive),
        _buildKeypadButton('8', responsive),
        _buildKeypadButton('9', responsive),
        const SizedBox(), // Espace vide
        _buildKeypadButton('0', responsive),
        _buildDeleteButton(responsive),
      ],
    );
  }

  /// Widget - Bouton du clavier numérique
  Widget _buildKeypadButton(String digit, ResponsiveUtils responsive) {
    return Material(
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
                fontSize: responsive.getAdaptiveTextSize(28),
                fontWeight: FontWeight.w600,
                color: _isLoading ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget - Bouton effacer
  Widget _buildDeleteButton(ResponsiveUtils responsive) {
    return Material(
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
              size: responsive.getAdaptiveTextSize(28),
              color: _isLoading ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}
