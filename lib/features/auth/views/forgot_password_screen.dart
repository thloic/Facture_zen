import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/custom_text_field.dart';
import '../../../common/widgets/error_message.dart';
import '../../../common/widgets/app_logo.dart';
import '../../../common/utils/responsive_utils.dart';

/// ForgotPasswordScreen
/// Écran de réinitialisation du mot de passe
/// Permet à l'utilisateur de recevoir un email pour réinitialiser son mot de passe
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Gère l'envoi de l'email de réinitialisation
  Future<void> _handleResetPassword() async {
    // Efface les messages précédents
    context.read<ForgotPasswordViewModel>().clearMessages();

    final success = await context.read<ForgotPasswordViewModel>().resetPassword(
      _emailController.text,
    );

    if (success && mounted) {
      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de réinitialisation envoyé !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Attendre 2 secondes puis revenir à l'écran de login
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.horizontalPadding,
                      ),
                      child: Consumer<ForgotPasswordViewModel>(
                        builder: (context, viewModel, child) {
                          return Column(
                            children: [
                              SizedBox(
                                height: responsive.getAdaptiveSpacing(32),
                              ),

                              // Logo et titre
                              AppLogo(
                                fontSize: responsive.getAdaptiveTextSize(28),
                              ),

                              SizedBox(
                                height: responsive.getAdaptiveSpacing(60),
                              ),

                              // Titre principal
                              _buildTitle(responsive),

                              SizedBox(
                                height: responsive.getAdaptiveSpacing(16),
                              ),

                              // Description
                              _buildDescription(responsive),

                              SizedBox(
                                height: responsive.getAdaptiveSpacing(40),
                              ),

                              // Message d'erreur
                              if (viewModel.hasError) ...[
                                ErrorMessage(message: viewModel.errorMessage!),
                                SizedBox(
                                  height: responsive.getAdaptiveSpacing(16),
                                ),
                              ],

                              // Message de succès
                              if (viewModel.hasSuccess) ...[
                                _buildSuccessMessage(
                                  viewModel.successMessage!,
                                  responsive,
                                ),
                                SizedBox(
                                  height: responsive.getAdaptiveSpacing(16),
                                ),
                              ],

                              // Champ email
                              CustomTextField(
                                controller: _emailController,
                                hintText: 'Entrez votre email',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (_) => viewModel.clearMessages(),
                              ),

                              SizedBox(
                                height: responsive.getAdaptiveSpacing(32),
                              ),

                              // Bouton d'envoi
                              PrimaryButton(
                                text: 'Envoyer le lien',
                                onPressed: _handleResetPassword,
                                isLoading: viewModel.isLoading,
                                height: responsive.getAdaptiveHeight(56),
                              ),

                              SizedBox(
                                height: responsive.getAdaptiveSpacing(24),
                              ),

                              // Lien retour à la connexion
                              _buildBackToLoginLink(responsive),

                              const Spacer(),
                              SizedBox(
                                height: responsive.getAdaptiveSpacing(20),
                              ),
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

  /// Widget - Titre principal
  Widget _buildTitle(ResponsiveUtils responsive) {
    return Text(
      'Mot de passe oublié ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: responsive.getAdaptiveTextSize(24),
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
      ),
    );
  }

  /// Widget - Description
  Widget _buildDescription(ResponsiveUtils responsive) {
    return Text(
      'Entrez votre email et nous vous enverrons\nun lien pour réinitialiser votre mot de passe',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: responsive.getAdaptiveTextSize(14),
        color: const Color(0xFF6B7280),
        height: 1.5,
      ),
    );
  }

  /// Widget - Message de succès
  Widget _buildSuccessMessage(String message, ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF16A34A),
            size: 20,
          ),
          SizedBox(width: responsive.getAdaptiveSpacing(12)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: const Color(0xFF16A34A),
                fontSize: responsive.getAdaptiveTextSize(14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget - Lien retour à la connexion
  Widget _buildBackToLoginLink(ResponsiveUtils responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.arrow_back,
          color: const Color(0xFF5B5FC7),
          size: responsive.getAdaptiveTextSize(16),
        ),
        SizedBox(width: responsive.getAdaptiveSpacing(8)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Retour à la connexion',
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
