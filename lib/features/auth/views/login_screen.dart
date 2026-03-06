import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../viewmodels/login_viewmodel.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/custom_text_field.dart';
import '../../../common/widgets/app_logo.dart';
import '../../../common/utils/responsive_utils.dart';
import '../../../common/utils/toast_utils.dart';
import '../../../common/services/pin_service.dart';
import 'forgot_password_screen.dart';

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

    if (!mounted) return;

    if (success) {
      ToastUtils.show(context, message: 'Connexion réussie !', isError: false);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      final error = context.read<LoginViewModel>().errorMessage ?? 'Erreur de connexion';
      ToastUtils.show(context, message: error, isError: true);
    }
  }

  /// Gère la connexion avec Google
  Future<void> _handleGoogleSignIn() async {
    context.read<LoginViewModel>().clearError();

    final success = await context.read<LoginViewModel>().signInWithGoogle();

    if (!mounted) return;

    if (success) {
      ToastUtils.show(context, message: 'Connexion avec Google réussie !', isError: false);
      
      // Vérifier si un PIN est configuré
      final pinService = PinService();
      final hasPin = await pinService.hasPin();
      
      if (hasPin) {
        // PIN déjà configuré, demander le PIN pour sécurité
        Navigator.pushReplacementNamed(context, '/pin-login');
      } else {
        // Première connexion Google, configurer le PIN
        debugPrint('🔐 Première connexion Google - Redirection vers configuration PIN');
        Navigator.pushReplacementNamed(context, '/pin-setup');
      }
    } else {
      final error = context.read<LoginViewModel>().errorMessage ?? 'Erreur de connexion Google';
      ToastUtils.show(context, message: error, isError: true);
    }
  }

  /// Gère la connexion avec Apple
  Future<void> _handleAppleSignIn() async {
    context.read<LoginViewModel>().clearError();

    final success = await context.read<LoginViewModel>().signInWithApple();

    if (!mounted) return;

    if (success) {
      ToastUtils.show(context, message: 'Connexion avec Apple réussie !', isError: false);
      
      // Vérifier si un PIN est configuré
      final pinService = PinService();
      final hasPin = await pinService.hasPin();
      
      if (hasPin) {
        // PIN déjà configuré, demander le PIN pour sécurité
        Navigator.pushReplacementNamed(context, '/pin-login');
      } else {
        // Première connexion Apple, configurer le PIN
        debugPrint('🔐 Première connexion Apple - Redirection vers configuration PIN');
        Navigator.pushReplacementNamed(context, '/pin-setup');
      }
    } else {
      final error = context.read<LoginViewModel>().errorMessage ?? 'Erreur de connexion Apple';
      ToastUtils.show(context, message: error, isError: true);
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

                            SizedBox(height: responsive.getAdaptiveSpacing(60)),

                            // Message "Vous n'êtes pas encore connectés"
                            _buildWelcomeMessage(responsive),

                            SizedBox(height: responsive.getAdaptiveSpacing(32)),

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
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
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

                            // Séparateur "OU"
                            _buildOrDivider(responsive),

                            SizedBox(height: responsive.getAdaptiveSpacing(24)),

                            // Boutons de connexion sociale (Google et Apple)
                            _buildSocialSignInButtons(responsive, viewModel),

                            const Spacer(),

                            // Lien inscription
                            _buildSignupLink(responsive),

                            SizedBox(height: responsive.getAdaptiveSpacing(24)),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ForgotPasswordScreen(),
            ),
          );
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

  /// Widget - Séparateur "OU"
  Widget _buildOrDivider(ResponsiveUtils responsive) {
    return Row(
      children: [
        Expanded(child: Divider(color: const Color(0xFFE5E7EB), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.getAdaptiveSpacing(16),
          ),
          child: Text(
            'OU',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: responsive.getAdaptiveTextSize(14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: const Color(0xFFE5E7EB), thickness: 1)),
      ],
    );
  }

  /// Widget - Boutons de connexion sociale (Google et Apple côte à côte)
  Widget _buildSocialSignInButtons(
    ResponsiveUtils responsive,
    LoginViewModel viewModel,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouton Google
        GestureDetector(
          onTap: viewModel.isLoading ? null : _handleGoogleSignIn,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Image.asset(
              'assets/images/icons8-google-48.png',
              height: 32,
              width: 32,
            ),
          ),
        ),
        
        // Bouton Apple (visible seulement sur iOS)
        if (Platform.isIOS) ...[SizedBox(width: responsive.getAdaptiveSpacing(20)),
        
        GestureDetector(
          onTap: viewModel.isLoading ? null : _handleAppleSignIn,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.apple,
              size: 32,
              color: Color(0xFF000000),
            ),
          ),
        ),],
      ],
    );
  }
}
