import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/register_viewmodel.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/custom_text_field.dart';
import '../../../common/widgets/error_message.dart';
import '../../../common/widgets/app_logo.dart';
import '../../../common/utils/responsive_utils.dart';

/// RegisterScreen

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Gère la soumission du formulaire d'inscription via le ViewModel
  Future<void> _handleRegister() async {
    // Efface les erreurs précédentes
    context.read<RegisterViewModel>().clearError();

    final success = await context.read<RegisterViewModel>().register(
      companyName: _companyNameController.text,
      companyAddress: _companyAddressController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      // Navigation vers l'écran principal après succès
      // TODO: Remplacer par la route appropriée
      Navigator.pushReplacementNamed(context, '/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription réussie !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Navigation vers la page de connexion
  void _navigateToLogin() {
    // TODO: Implémenter la navigation
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    // Initialisation des utilitaires de responsivité
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
                    ),
                    child: Consumer<RegisterViewModel>(
                      builder: (context, viewModel, child) {
                        return Column(
                          children: [
                            SizedBox(height: responsive.getAdaptiveSpacing(32)),

                            // Logo et titre de l'application
                            AppLogo(
                              fontSize: responsive.getAdaptiveTextSize(28),
                            ),

                            SizedBox(height: responsive.getAdaptiveSpacing(60)),

                            // Message "Vous n'avez pas encore de compte"
                            _buildWelcomeMessage(responsive),

                            SizedBox(height: responsive.getAdaptiveSpacing(32)),

                            // Affichage du message d'erreur si présent
                            if (viewModel.hasError) ...[
                              ErrorMessage(message: viewModel.errorMessage!),
                              SizedBox(height: responsive.getAdaptiveSpacing(16)),
                            ],

                            // Champ Nom de l'entreprise
                            CustomTextField(
                              controller: _companyNameController,
                              hintText: 'Nom de votre entreprise',
                              prefixIcon: Icons.business_outlined,
                              keyboardType: TextInputType.text,
                              onChanged: (_) => viewModel.clearError(),
                            ),

                            SizedBox(height: responsive.getAdaptiveSpacing(16)),

                            // Champ Adresse de l'entreprise
                            CustomTextField(
                              controller: _companyAddressController,
                              hintText: 'Adresse de votre entreprise',
                              prefixIcon: Icons.location_on_outlined,
                              keyboardType: TextInputType.streetAddress,
                              onChanged: (_) => viewModel.clearError(),
                            ),

                            SizedBox(height: responsive.getAdaptiveSpacing(16)),

                            // Champ Email
                            CustomTextField(
                              controller: _emailController,
                              hintText: 'Email de votre entreprise',
                              prefixIcon: Icons.mail,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => viewModel.clearError(),
                            ),

                            SizedBox(height: responsive.getAdaptiveSpacing(16)),

                            // Champ Mot de passe
                            CustomTextField(
                              controller: _passwordController,
                              hintText: 'Entrez le mot de passe',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              onChanged: (_) => viewModel.clearError(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF6B7280),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),

                            SizedBox(height: responsive.getAdaptiveSpacing(16)),

                            // Champ Confirmation mot de passe
                            CustomTextField(
                              controller: _confirmPasswordController,
                              hintText: 'Confirmez le mot de passe',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscureConfirmPassword,
                              onChanged: (_) => viewModel.clearError(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF6B7280),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                              ),
                            ),

                            SizedBox(height: responsive.getAdaptiveSpacing(32)),

                            // Bouton d'inscription
                            PrimaryButton(
                              text: 'Inscription',
                              onPressed: _handleRegister,
                              isLoading: viewModel.isLoading,
                              height: responsive.getAdaptiveHeight(56),
                            ),

                            SizedBox(height: responsive.getAdaptiveSpacing(20)),

                            // Lien vers connexion
                            _buildLoginLink(responsive),

                            // Espacement flexible pour pousser le contenu vers le haut sur grands écrans
                            const Spacer(),
                            SizedBox(height: responsive.getAdaptiveSpacing(20)),
                          ],
                        );
                      },
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

  /// Widget - Message de bienvenue responsive
  Widget _buildWelcomeMessage(ResponsiveUtils responsive) {
    return Text(
      'Vous n\'avez pas encore\nde compte',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: responsive.getAdaptiveTextSize(18),
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1F2937),
        height: 1.4,
      ),
    );
  }

  /// Widget - Lien vers la page de connexion responsive
  Widget _buildLoginLink(ResponsiveUtils responsive) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Vous avez déjà un compte? ',
          style: TextStyle(
            color: const Color(0xFF6B7280),
            fontSize: responsive.getAdaptiveTextSize(14),
          ),
        ),
        TextButton(
          onPressed: _navigateToLogin,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Connectez vous',
            style: TextStyle(
              color: const Color(0xFF5B5FC7),
              fontSize: responsive.getAdaptiveTextSize(14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}