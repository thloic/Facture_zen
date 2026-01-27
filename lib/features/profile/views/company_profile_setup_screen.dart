import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/utils/responsive_utils.dart';
import '../../../common/utils/toast_utils.dart';
import '../models/user_profile_model.dart';
import '../viewmodels/company_profile_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Écran de configuration du profil entreprise
/// Affiché lors de la première connexion ou pour modifier le profil
class CompanyProfileSetupScreen extends StatefulWidget {
  final bool isOnboarding; // true = première config, false = modification

  const CompanyProfileSetupScreen({
    Key? key,
    this.isOnboarding = true,
  }) : super(key: key);

  @override
  State<CompanyProfileSetupScreen> createState() => _CompanyProfileSetupScreenState();
}

class _CompanyProfileSetupScreenState extends State<CompanyProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs de texte
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companySiretController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Si modification, charger les données existantes
    if (!widget.isOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingProfile();
      });
    }
  }

  Future<void> _loadExistingProfile() async {
    final viewModel = context.read<CompanyProfileViewModel>();
    await viewModel.loadProfile();

    if (viewModel.profile != null) {
      final profile = viewModel.profile!;
      _companyNameController.text = profile.companyName;
      _companyAddressController.text = profile.companyAddress;
      _companyPhoneController.text = profile.companyPhone ?? '';
      _companyEmailController.text = profile.companyEmail ?? '';
      _companySiretController.text = profile.companySiret ?? '';
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _companySiretController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final profile = UserProfile(
        userId: userId,
        companyName: _companyNameController.text.trim(),
        companyAddress: _companyAddressController.text.trim(),
        companyPhone: _companyPhoneController.text.trim().isEmpty
            ? null
            : _companyPhoneController.text.trim(),
        companyEmail: _companyEmailController.text.trim().isEmpty
            ? null
            : _companyEmailController.text.trim(),
        companySiret: _companySiretController.text.trim().isEmpty
            ? null
            : _companySiretController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final viewModel = context.read<CompanyProfileViewModel>();
      final success = await viewModel.saveProfile(profile);

      if (!mounted) return;

      if (success) {
        ToastUtils.showSuccess(context, 'Profil enregistré avec succès');
        
        // Si onboarding, retourner à l'écran précédent
        if (widget.isOnboarding) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pop(context);
        }
      } else {
        ToastUtils.showError(context, 'Erreur lors de la sauvegarde');
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde profil: $e');
      if (mounted) {
        ToastUtils.showError(context, 'Une erreur est survenue');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
        leading: widget.isOnboarding
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          widget.isOnboarding
              ? 'Configuration du profil'
              : 'Modifier le profil',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<CompanyProfileViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && widget.isOnboarding) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5B5FC7),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(responsive.horizontalPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isOnboarding) ...[
                    _buildWelcomeHeader(responsive),
                    SizedBox(height: responsive.getAdaptiveSpacing(32)),
                  ],

                  _buildTextField(
                    controller: _companyNameController,
                    label: 'Nom de l\'entreprise',
                    hint: 'Ex: SARL Martin',
                    icon: Icons.business,
                    isRequired: true,
                    responsive: responsive,
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(20)),

                  _buildTextField(
                    controller: _companyAddressController,
                    label: 'Adresse',
                    hint: 'Ex: 10 Rue du Commerce\\n69002 Lyon',
                    icon: Icons.location_on,
                    isRequired: true,
                    maxLines: 3,
                    responsive: responsive,
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(20)),

                  _buildTextField(
                    controller: _companyPhoneController,
                    label: 'Téléphone',
                    hint: '+33 6 12 34 56 78',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    responsive: responsive,
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(20)),

                  _buildTextField(
                    controller: _companyEmailController,
                    label: 'Email',
                    hint: 'contact@entreprise.fr',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    responsive: responsive,
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(20)),

                  _buildTextField(
                    controller: _companySiretController,
                    label: 'SIRET',
                    hint: '123 456 789 00025',
                    icon: Icons.badge,
                    keyboardType: TextInputType.number,
                    responsive: responsive,
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(40)),

                  _buildSaveButton(responsive),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(ResponsiveUtils responsive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF5B5FC7).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.business_center,
            size: 48,
            color: Color(0xFF5B5FC7),
          ),
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(24)),
        Text(
          'Bienvenue !',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(24),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(8)),
        Text(
          'Configurons votre profil entreprise pour personnaliser vos factures',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(14),
            color: const Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ResponsiveUtils responsive,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(14),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(8)),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF9CA3AF),
              fontSize: responsive.getAdaptiveTextSize(14),
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5B5FC7), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
          validator: validator ??
              (value) {
                if (isRequired && (value == null || value.trim().isEmpty)) {
                  return 'Ce champ est requis';
                }
                return null;
              },
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email optionnel
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email invalide';
    }

    return null;
  }

  Widget _buildSaveButton(ResponsiveUtils responsive) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B5FC7),
          disabledBackgroundColor: const Color(0xFF5B5FC7).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.isOnboarding ? 'Créer mon profil' : 'Enregistrer',
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
