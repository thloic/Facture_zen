import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/custom_text_field.dart';
import '../../../common/widgets/error_message.dart';
import '../../../common/utils/responsive_utils.dart';

/// EditProfileScreen
/// Écran pour modifier les informations du profil
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Remplir les champs avec les données actuelles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ProfileViewModel>();
      _companyNameController.text = viewModel.userCompanyName ?? '';
      _companyAddressController.text = viewModel.userCompanyAddress ?? '';
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    super.dispose();
  }

  /// Sauvegarde les modifications
  Future<void> _saveProfile() async {
    final viewModel = context.read<ProfileViewModel>();

    final success = await viewModel.updateProfile(
      companyName: _companyNameController.text,
      companyAddress: _companyAddressController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Color(0xFF5B5FC7),
        ),
      );
      Navigator.pop(context);
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
        title: Text(
          'Modifier le profil',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<ProfileViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              child: Column(
                children: [
                  SizedBox(height: responsive.getAdaptiveSpacing(24)),

                  // Afficher le message d'erreur si présent
                  if (viewModel.hasError) ...[
                    ErrorMessage(message: viewModel.errorMessage!),
                    SizedBox(height: responsive.getAdaptiveSpacing(16)),
                  ],

                  // Email (non modifiable)
                  _buildInfoRow('Email', viewModel.userEmail ?? '', responsive),

                  SizedBox(height: responsive.getAdaptiveSpacing(24)),

                  // Nom de l'entreprise
                  CustomTextField(
                    controller: _companyNameController,
                    hintText: 'Nom de l\'entreprise',
                    prefixIcon: Icons.business_outlined,
                    onChanged: (_) => viewModel.clearError(),
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(16)),

                  // Adresse de l'entreprise
                  CustomTextField(
                    controller: _companyAddressController,
                    hintText: 'Adresse de l\'entreprise',
                    prefixIcon: Icons.location_on_outlined,
                    onChanged: (_) => viewModel.clearError(),
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(32)),

                  // Bouton sauvegarder
                  PrimaryButton(
                    text: 'Sauvegarder',
                    onPressed: _saveProfile,
                    isLoading: viewModel.isLoading,
                    height: responsive.getAdaptiveHeight(56),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Widget - Ligne d'information non modifiable
  Widget _buildInfoRow(String label, String value, ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.email_outlined,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
          SizedBox(width: responsive.getAdaptiveSpacing(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(12),
                    color: const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(4)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(15),
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}