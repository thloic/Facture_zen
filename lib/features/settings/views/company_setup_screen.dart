import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/widgets/app_logo.dart';
import '../../../common/widgets/custom_text_field.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/utils/responsive_utils.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';

/// CompanySetupScreen
/// Écran de configuration des informations de l'entreprise
/// Affiché après la configuration du PIN (ou si PIN skippé)
class CompanySetupScreen extends StatefulWidget {
  const CompanySetupScreen({Key? key}) : super(key: key);

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();
  
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    super.dispose();
  }

  /// Sauvegarde les informations de l'entreprise
  Future<void> _saveCompanyInfo() async {
    final companyName = _companyNameController.text.trim();
    final companyAddress = _companyAddressController.text.trim();

    // Validation
    if (companyName.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer le nom de votre entreprise';
      });
      return;
    }

    if (companyName.length < 2) {
      setState(() {
        _errorMessage = 'Le nom de l\'entreprise doit contenir au moins 2 caractères';
      });
      return;
    }

    if (companyAddress.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer l\'adresse de votre entreprise';
      });
      return;
    }

    if (companyAddress.length < 5) {
      setState(() {
        _errorMessage = 'L\'adresse doit être plus détaillée';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Utiliser le ProfileViewModel pour mettre à jour les données
      final profileViewModel = context.read<ProfileViewModel>();
      
      final success = await profileViewModel.updateProfile(
        companyName: companyName,
        // companyAddress: companyAddress,
      );

      if (success && mounted) {        // Recharger le profil pour mettre à jour le banner
        await profileViewModel.loadUserProfile();
                // Succès - rediriger vers l'accueil
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de la sauvegarde';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Une erreur est survenue';
        _isLoading = false;
      });
    }
  }

  /// Passer cette étape
  void _skip() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

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
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        // Logo
                        AppLogo(fontSize: responsive.getAdaptiveTextSize(24)),
                        
                        SizedBox(height: responsive.getAdaptiveSpacing(48)),

                        // Titre
                        Text(
                          'Informations de votre entreprise',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: responsive.getAdaptiveTextSize(24),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        
                        SizedBox(height: responsive.getAdaptiveSpacing(12)),

                        Text(
                          'Ces informations apparaîtront sur vos factures',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: responsive.getAdaptiveTextSize(14),
                            color: const Color(0xFF6B7280),
                          ),
                        ),

                        SizedBox(height: responsive.getAdaptiveSpacing(48)),

                        // Message d'erreur
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: responsive.getAdaptiveSpacing(16)),
                        ],

                        // Champ Nom de l'entreprise
                        CustomTextField(
                          controller: _companyNameController,
                          hintText: 'Nom de votre entreprise',
                          prefixIcon: Icons.business_outlined,
                          keyboardType: TextInputType.text,
                          onChanged: (_) => setState(() => _errorMessage = null),
                        ),

                        SizedBox(height: responsive.getAdaptiveSpacing(16)),

                        // Champ Adresse de l'entreprise
                        CustomTextField(
                          controller: _companyAddressController,
                          hintText: 'Adresse de votre entreprise',
                          prefixIcon: Icons.location_on_outlined,
                          keyboardType: TextInputType.streetAddress,
                          onChanged: (_) => setState(() => _errorMessage = null),
                        ),

                        SizedBox(height: responsive.getAdaptiveSpacing(32)),

                        // Bouton Enregistrer
                        PrimaryButton(
                          text: 'Enregistrer',
                          onPressed: _saveCompanyInfo,
                          isLoading: _isLoading,
                          height: responsive.getAdaptiveHeight(56),
                        ),

                        SizedBox(height: responsive.getAdaptiveSpacing(16)),

                        // Bouton Passer
                        TextButton(
                          onPressed: _isLoading ? null : _skip,
                          child: Text(
                            'Passer pour l\'instant',
                            style: TextStyle(
                              color: const Color(0xFF6B7280),
                              fontSize: responsive.getAdaptiveTextSize(14),
                            ),
                          ),
                        ),

                        const Spacer(),
                        SizedBox(height: responsive.getAdaptiveSpacing(20)),
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
}
