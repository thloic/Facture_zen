import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/login_viewmodel.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/custom_text_field.dart';
import '../../../common/widgets/error_message.dart';
import '../../../common/widgets/app_logo.dart';
import '../../../common/utils/responsive_utils.dart';

/// LoginScreen
/// Page d'authentification de l'application FactureZen
/// Permet à l'utilisateur de se connecter via email et mot de passe
/// Respecte l'architecture MVVM - cette classe est la View
/// Design 100% responsive et adaptatif à toutes les tailles d'écran
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Gère la soumission du formulaire via le ViewModel
  Future<void> _handleLogin() async {
    // Efface les erreurs précédentes quand l'utilisateur retente
    context.read<LoginViewModel>().clearError();

    final success = await context.read<LoginViewModel>().login(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      // Navigation vers l'écran principal après succès
      // TODO: Remplacer par la route appropriée
      Navigator.pushReplacementNamed(context, '/home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connexion réussie !'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
                    child: Consumer<LoginViewModel>(
                      builder: (context, viewModel, child) {
                        return Column(
                          children: [
                            SizedBox(height: responsive.getAdaptiveSpacing(32)),

                            // Logo et titre de l'application
                            AppLogo(
                              fontSize: responsive.getAdaptiveTextSize(28),
                            ),

                            SizedBox(height: responsive.getAdaptiveSpacing(80)),

                            // Message "Vous n'êtes pas encore connectés"
                            _buildWelcomeMessage(responsive),

                            SizedBox(height: responsive.getAdaptiveSpacing(40)),

                            // Affichage du message d'erreur si présent
                            if (viewModel.hasError) ...[
                              ErrorMessage(message: viewModel.errorMessage!),
                              SizedBox(height: responsive.getAdaptiveSpacing(16)),
                            ],

                            // Champ email
                            CustomTextField(
                              controller: _emailController,
                              hintText: 'Nom d\'utilisateur',
                              prefixIcon: Icons.person_outline,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => viewModel.clearError(),
                            ),

                            SizedBox(height: responsive.getAdaptiveSpacing(16)),

                            // Champ mot de passe
                            CustomTextField(
                              controller: _passwordController,
                              hintText: 'Entrez votre mot de passe',
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

                            SizedBox(height: responsive.getAdaptiveSpacing(12)),

                            // Lien "Mot de passe oublié"
                            _buildForgotPasswordLink(responsive),

                            SizedBox(height: responsive.getAdaptiveSpacing(32)),

                            // Bouton de connexion
                            PrimaryButton(
                              text: 'Connexion',
                              onPressed: _handleLogin,
                              isLoading: viewModel.isLoading,
                              height: responsive.getAdaptiveHeight(56),
                            ),

                            SizedBox(height: responsive.getAdaptiveSpacing(24)),

                            // Lien inscription
                            _buildSignupLink(responsive),

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
      'Vous n\'êtes pas encore\nconnectés',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: responsive.getAdaptiveTextSize(18),
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1F2937),
        height: 1.4,
      ),
    );
  }

  /// Widget - Lien mot de passe oublié responsive
  Widget _buildForgotPasswordLink(ResponsiveUtils responsive) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: Navigation vers la page de récupération de mot de passe
          // Navigator.pushNamed(context, '/forgot-password');
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Mot de passe oublié ?',
          style: TextStyle(
            color: const Color(0xFF5B5FC7),
            fontSize: responsive.getAdaptiveTextSize(14),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Widget - Lien vers la page d'inscription responsive
  Widget _buildSignupLink(ResponsiveUtils responsive) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Vous n\'avez pas de compte? ',
          style: TextStyle(
            color: const Color(0xFF6B7280),
            fontSize: responsive.getAdaptiveTextSize(14),
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Navigation vers la page d'inscription
            Navigator.pushNamed(context, '/register');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Inscrivez vous',
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