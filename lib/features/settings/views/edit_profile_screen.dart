import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/utils/responsive_utils.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';

/// Écran d'édition du profil
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialiser les champs avec les valeurs actuelles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ProfileViewModel>();
      _firstNameController.text = viewModel.firstName ?? '';
      _lastNameController.text = viewModel.lastName ?? '';
      _companyNameController.text = viewModel.companyName ?? '';
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
      body: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(responsive.horizontalPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF5B5FC7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: viewModel.userAvatarUrl != null
                                ? Image.network(
                                    viewModel.userAvatarUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B5FC7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(32)),

                  // Email (non modifiable)
                  Text(
                    'Email',
                    style: TextStyle(
                      fontSize: responsive.getAdaptiveTextSize(14),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: responsive.getAdaptiveSpacing(8)),
                  Container(
                    padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        SizedBox(width: responsive.getAdaptiveSpacing(12)),
                        Expanded(
                          child: Text(
                            viewModel.userEmail ?? 'email@example.com',
                            style: TextStyle(
                              fontSize: responsive.getAdaptiveTextSize(16),
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF9CA3AF),
                          size: 18,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(20)),

                  // Prénom
                  Text(
                    'Prénom',
                    style: TextStyle(
                      fontSize: responsive.getAdaptiveTextSize(14),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: responsive.getAdaptiveSpacing(8)),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Jean',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF5B5FC7),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF5B5FC7),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le prénom est requis';
                      }
                      if (value.trim().length < 2) {
                        return 'Le prénom doit contenir au moins 2 caractères';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(20)),

                  // Nom
                  Text(
                    'Nom',
                    style: TextStyle(
                      fontSize: responsive.getAdaptiveTextSize(14),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: responsive.getAdaptiveSpacing(8)),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Dupont',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF5B5FC7),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF5B5FC7),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom est requis';
                      }
                      if (value.trim().length < 2) {
                        return 'Le nom doit contenir au moins 2 caractères';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(20)),

                  // Nom de l'entreprise
                  Text(
                    'Nom de l\'entreprise',
                    style: TextStyle(
                      fontSize: responsive.getAdaptiveTextSize(14),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: responsive.getAdaptiveSpacing(8)),
                  TextFormField(
                    controller: _companyNameController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Mon Entreprise',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(
                        Icons.business_outlined,
                        color: Color(0xFF5B5FC7),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF5B5FC7),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom de l\'entreprise est requis';
                      }
                      if (value.trim().length < 2) {
                        return 'Le nom doit contenir au moins 2 caractères';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(40)),

                  // Bouton Enregistrer
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _saveProfile(context, viewModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B5FC7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: const Color(0xFF9CA3AF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Enregistrer les modifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(16)),

                  // Bouton Annuler
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(20)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveProfile(
    BuildContext context,
    ProfileViewModel viewModel,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final companyName = _companyNameController.text.trim();

    final success = await viewModel.updateProfile(
      firstName: firstName,
      lastName: lastName,
      companyName: companyName,
    );

    if (context.mounted) {
      if (success) {
        _showSuccessToast(context);
        // Attendre un peu avant de fermer pour que l'utilisateur voie le toast
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        _showErrorToast(
          context,
          viewModel.errorMessage ?? 'Erreur lors de la mise à jour',
        );
      }
    }
  }

  void _showSuccessToast(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Profil mis à jour avec succès',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _showErrorToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
