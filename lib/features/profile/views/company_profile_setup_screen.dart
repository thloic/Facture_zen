import 'package:facture_zen/features/profile/widget/logo_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/utils/responsive_utils.dart';
import '../../../common/utils/toast_utils.dart';
import '../models/user_profile_model.dart';
import '../viewmodels/company_profile_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

/// Écran de configuration du profil entreprise - Version Premium
/// Design Thinking: Progressive Disclosure + Clear Visual Hierarchy
class CompanyProfileSetupScreen extends StatefulWidget {
  final bool isOnboarding;

  const CompanyProfileSetupScreen({
    Key? key,
    this.isOnboarding = true,
  }) : super(key: key);

  @override
  State<CompanyProfileSetupScreen> createState() => _CompanyProfileSetupScreenState();
}

class _CompanyProfileSetupScreenState extends State<CompanyProfileSetupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers - Identification
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companySiretController = TextEditingController();
  final _companySirenController = TextEditingController();
  final _companyLegalFormController = TextEditingController();
  final _companyCapitalController = TextEditingController();
  final _companyTvaNumberController = TextEditingController();
  
  // Controllers - Paiement
  final _ibanController = TextEditingController();
  final _bicController = TextEditingController();
  final _paymentDelayController = TextEditingController();
  final _penaltyRateController = TextEditingController();
  
  // Controllers - Mentions
  final _insuranceCompanyController = TextEditingController();
  final _insurancePolicyController = TextEditingController();
  final _approvedAssociationController = TextEditingController();

  // Options
  bool _isAutoEntrepreneur = false;
  bool _isArtisan = false;
  bool _hasTVA = true;
  
  bool _isSaving = false;

  // Section expansion states
  bool _identificationExpanded = true;
  bool _paymentExpanded = false;
  bool _legalExpanded = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
    
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
      _companyNameController.text = profile.companyName ?? '';
      _companyAddressController.text = profile.companyAddress ?? '';
      _companyPhoneController.text = profile.companyPhone ?? '';
      _companyEmailController.text = profile.companyEmail ?? '';
      _companySiretController.text = profile.companySiret ?? '';
      _companySirenController.text = profile.companySiren ?? '';
      _companyLegalFormController.text = profile.companyLegalForm ?? '';
      _companyCapitalController.text = profile.companyCapital ?? '';
      _companyTvaNumberController.text = profile.companyTvaNumber ?? '';
      _ibanController.text = profile.iban ?? '';
      _bicController.text = profile.bic ?? '';
      _paymentDelayController.text = profile.paymentDelay ?? '';
      _penaltyRateController.text = profile.penaltyRate ?? '';
      _insuranceCompanyController.text = profile.insuranceCompany ?? '';
      _insurancePolicyController.text = profile.insurancePolicy ?? '';
      _approvedAssociationController.text = profile.approvedAssociation ?? '';
      
      setState(() {
        _isAutoEntrepreneur = profile.isAutoEntrepreneur ?? false;
        _isArtisan = profile.isArtisan ?? false;
        _hasTVA = profile.hasTVA ?? true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _companySiretController.dispose();
    _companySirenController.dispose();
    _companyLegalFormController.dispose();
    _companyCapitalController.dispose();
    _companyTvaNumberController.dispose();
    _ibanController.dispose();
    _bicController.dispose();
    _paymentDelayController.dispose();
    _penaltyRateController.dispose();
    _insuranceCompanyController.dispose();
    _insurancePolicyController.dispose();
    _approvedAssociationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ToastUtils.showError(context, 'Veuillez vérifier les informations');
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
        companyName: _companyNameController.text.trim().isEmpty ? null : _companyNameController.text.trim(),
        companyAddress: _companyAddressController.text.trim().isEmpty ? null : _companyAddressController.text.trim(),
        companyPhone: _companyPhoneController.text.trim().isEmpty ? null : _companyPhoneController.text.trim(),
        companyEmail: _companyEmailController.text.trim().isEmpty ? null : _companyEmailController.text.trim(),
        companySiret: _companySiretController.text.trim().isEmpty ? null : _companySiretController.text.trim(),
        companySiren: _companySirenController.text.trim().isEmpty ? null : _companySirenController.text.trim(),
        companyLegalForm: _companyLegalFormController.text.trim().isEmpty ? null : _companyLegalFormController.text.trim(),
        companyCapital: _companyCapitalController.text.trim().isEmpty ? null : _companyCapitalController.text.trim(),
        companyTvaNumber: _companyTvaNumberController.text.trim().isEmpty ? null : _companyTvaNumberController.text.trim(),
        iban: _ibanController.text.trim().isEmpty ? null : _ibanController.text.trim(),
        bic: _bicController.text.trim().isEmpty ? null : _bicController.text.trim(),
        paymentDelay: _paymentDelayController.text.trim().isEmpty ? null : _paymentDelayController.text.trim(),
        penaltyRate: _penaltyRateController.text.trim().isEmpty ? null : _penaltyRateController.text.trim(),
        insuranceCompany: _insuranceCompanyController.text.trim().isEmpty ? null : _insuranceCompanyController.text.trim(),
        insurancePolicy: _insurancePolicyController.text.trim().isEmpty ? null : _insurancePolicyController.text.trim(),
        approvedAssociation: _approvedAssociationController.text.trim().isEmpty ? null : _approvedAssociationController.text.trim(),
        isAutoEntrepreneur: _isAutoEntrepreneur,
        isArtisan: _isArtisan,
        hasTVA: _hasTVA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final viewModel = context.read<CompanyProfileViewModel>();
      final success = await viewModel.saveProfile(profile);

      if (!mounted) return;

      if (success) {
        ToastUtils.showSuccess(context, '✓ Profil enregistré avec succès');
        
        await Future.delayed(const Duration(milliseconds: 500));
        
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(responsive),
      body: Consumer<CompanyProfileViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && widget.isOnboarding) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF5B5FC7),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: responsive.getAdaptiveSpacing(16)),
                  Text(
                    'Chargement de votre profil...',
                    style: TextStyle(
                      fontSize: responsive.getAdaptiveTextSize(14),
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
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

                          // Logo Picker
                          _buildLogoPicker(responsive, viewModel),
                          SizedBox(height: responsive.getAdaptiveSpacing(24)),

                          // Progress indicator
                          _buildProgressIndicator(responsive),
                          SizedBox(height: responsive.getAdaptiveSpacing(24)),

                          // Section 1: Identification
                          _buildCollapsibleSection(
                            title: 'Identification',
                            subtitle: 'Informations de votre entreprise',
                            icon: Icons.business_rounded,
                            isExpanded: _identificationExpanded,
                            completionRate: _calculateIdentificationCompletion(),
                            onToggle: () {
                              setState(() => _identificationExpanded = !_identificationExpanded);
                            },
                            responsive: responsive,
                            child: _buildIdentificationFields(responsive),
                          ),

                          SizedBox(height: responsive.getAdaptiveSpacing(16)),

                          // Section 2: Paiement
                          _buildCollapsibleSection(
                            title: 'Paiement',
                            subtitle: 'Coordonnées bancaires et conditions',
                            icon: Icons.payment_rounded,
                            isExpanded: _paymentExpanded,
                            completionRate: _calculatePaymentCompletion(),
                            onToggle: () {
                              setState(() => _paymentExpanded = !_paymentExpanded);
                            },
                            responsive: responsive,
                            child: _buildPaymentFields(responsive),
                          ),

                          SizedBox(height: responsive.getAdaptiveSpacing(16)),

                          // Section 3: Mentions légales
                          _buildCollapsibleSection(
                            title: 'Mentions légales',
                            subtitle: 'Statuts et obligations spécifiques',
                            icon: Icons.gavel_rounded,
                            isExpanded: _legalExpanded,
                            completionRate: _calculateLegalCompletion(),
                            onToggle: () {
                              setState(() => _legalExpanded = !_legalExpanded);
                            },
                            responsive: responsive,
                            child: _buildLegalFields(responsive),
                          ),

                          SizedBox(height: responsive.getAdaptiveSpacing(32)),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Fixed bottom button
                _buildBottomBar(responsive),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ResponsiveUtils responsive) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: widget.isOnboarding
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
      title: Text(
        widget.isOnboarding ? 'Configuration du profil' : 'Modifier le profil',
        style: TextStyle(
          fontSize: responsive.getAdaptiveTextSize(18),
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1F2937),
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFE5E7EB),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.getAdaptiveSpacing(24)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B5FC7), Color(0xFF7C7FD8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B5FC7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: responsive.getAdaptiveSpacing(16)),
          Text(
            'Bienvenue ! 👋',
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(26),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: responsive.getAdaptiveSpacing(8)),
          Text(
            'Créons ensemble votre profil entreprise pour des factures professionnelles et conformes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(14),
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          SizedBox(height: responsive.getAdaptiveSpacing(16)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Tous les champs sont facultatifs',
                    style: TextStyle(
                      fontSize: responsive.getAdaptiveTextSize(11),
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPicker(ResponsiveUtils responsive, CompanyProfileViewModel viewModel) {
    return LogoPickerWidget(
      selectedImage: viewModel.selectedLogoFile,
      existingLogoUrl: viewModel.selectedLogoUrl,
      isUploading: viewModel.isUploadingLogo,
      onImageSelected: (File file) {
        viewModel.selectLogo(file);
      },
      onImageRemoved: () {
        viewModel.removeLogo();
      },
    );
  }

  Widget _buildProgressIndicator(ResponsiveUtils responsive) {
    final overallCompletion = _calculateOverallCompletion();
    
    return Container(
      padding: EdgeInsets.all(responsive.getAdaptiveSpacing(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progression du profil',
                      style: TextStyle(
                        fontSize: responsive.getAdaptiveTextSize(14),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: responsive.getAdaptiveSpacing(4)),
                    Text(
                      'Complétez votre profil à votre rythme',
                      style: TextStyle(
                        fontSize: responsive.getAdaptiveTextSize(12),
                        color: const Color(0xFF6B7280),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCompletionColor(overallCompletion).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${overallCompletion.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(14),
                    fontWeight: FontWeight.bold,
                    color: _getCompletionColor(overallCompletion),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.getAdaptiveSpacing(12)),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: overallCompletion / 100,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(_getCompletionColor(overallCompletion)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isExpanded,
    required double completionRate,
    required VoidCallback onToggle,
    required ResponsiveUtils responsive,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? const Color(0xFF5B5FC7).withOpacity(0.3) : const Color(0xFFE5E7EB),
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: const Color(0xFF5B5FC7).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B5FC7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF5B5FC7),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: responsive.getAdaptiveSpacing(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: responsive.getAdaptiveTextSize(16),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: responsive.getAdaptiveSpacing(4)),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: responsive.getAdaptiveTextSize(12),
                                  color: const Color(0xFF6B7280),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: responsive.getAdaptiveSpacing(4)),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getCompletionColor(completionRate).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${completionRate.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: responsive.getAdaptiveTextSize(10),
                                    fontWeight: FontWeight.w600,
                                    color: _getCompletionColor(completionRate),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: responsive.getAdaptiveSpacing(8)),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF6B7280),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    children: [
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      Padding(
                        padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
                        child: child,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentificationFields(ResponsiveUtils responsive) {
    return Column(
      children: [
        _buildModernTextField(
          controller: _companyNameController,
          label: 'Nom de l\'entreprise',
          hint: 'Ex: SARL Martin Consulting',
          icon: Icons.business_rounded,
          responsive: responsive,
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(16)),
        
        _buildModernTextField(
          controller: _companyAddressController,
          label: 'Adresse complète',
          hint: 'Ex: 10 Rue du Commerce, 69002 Lyon',
          icon: Icons.location_on_rounded,
          maxLines: 3,
          responsive: responsive,
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(16)),
        
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _companySirenController,
                label: 'SIREN',
                hint: '123 456 789',
                icon: Icons.numbers_rounded,
                keyboardType: TextInputType.number,
                responsive: responsive,
              ),
            ),
            SizedBox(width: responsive.getAdaptiveSpacing(12)),
            Expanded(
              child: _buildModernTextField(
                controller: _companySiretController,
                label: 'SIRET',
                hint: '123 456 789 00025',
                icon: Icons.qr_code_rounded,
                keyboardType: TextInputType.number,
                responsive: responsive,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(16)),
        
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _companyLegalFormController,
                label: 'Forme juridique',
                hint: 'Ex: SARL, SAS',
                icon: Icons.account_balance_rounded,
                responsive: responsive,
              ),
            ),
            SizedBox(width: responsive.getAdaptiveSpacing(12)),
            Expanded(
              child: _buildModernTextField(
                controller: _companyCapitalController,
                label: 'Capital',
                hint: 'Ex: 10 000 €',
                icon: Icons.euro_rounded,
                keyboardType: TextInputType.number,
                responsive: responsive,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(16)),
        
        _buildModernTextField(
          controller: _companyTvaNumberController,
          label: 'Numéro de TVA',
          hint: 'Ex: FR 12 345678901',
          icon: Icons.receipt_long_rounded,
          responsive: responsive,
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(16)),
        
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _companyPhoneController,
                label: 'Téléphone',
                hint: '+33 6 12 34 56 78',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                responsive: responsive,
              ),
            ),
            SizedBox(width: responsive.getAdaptiveSpacing(12)),
            Expanded(
              child: _buildModernTextField(
                controller: _companyEmailController,
                label: 'Email',
                hint: 'contact@voxin-app.com',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                responsive: responsive,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentFields(ResponsiveUtils responsive) {
    return Column(
      children: [
        _buildModernTextField(
          controller: _ibanController,
          label: 'IBAN',
          hint: 'Ex: FR76 1234 5678 9012 3456 7890 123',
          icon: Icons.account_balance_wallet_rounded,
          responsive: responsive,
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(16)),
        
        _buildModernTextField(
          controller: _bicController,
          label: 'BIC / SWIFT',
          hint: 'Ex: BNPAFRPPXXX',
          icon: Icons.account_balance_rounded,
          responsive: responsive,
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(16)),
        
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _paymentDelayController,
                label: 'Délai de paiement',
                hint: 'Ex: 30 jours',
                icon: Icons.schedule_rounded,
                responsive: responsive,
              ),
            ),
            SizedBox(width: responsive.getAdaptiveSpacing(12)),
            Expanded(
              child: _buildModernTextField(
                controller: _penaltyRateController,
                label: 'Taux de pénalité',
                hint: 'Ex: 10%',
                icon: Icons.percent_rounded,
                keyboardType: TextInputType.number,
                responsive: responsive,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegalFields(ResponsiveUtils responsive) {
    return Column(
      children: [
        _buildModernSwitchTile(
          title: 'Auto-entrepreneur',
          subtitle: 'TVA non applicable, art. 293 B du CGI',
          icon: Icons.person_rounded,
          value: _isAutoEntrepreneur,
          onChanged: (value) {
            setState(() {
              _isAutoEntrepreneur = value;
              if (value) _hasTVA = false;
            });
          },
          responsive: responsive,
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(12)),
        
        _buildModernSwitchTile(
          title: 'Artisan',
          subtitle: 'Assurance décennale obligatoire',
          icon: Icons.construction_rounded,
          value: _isArtisan,
          onChanged: (value) {
            setState(() => _isArtisan = value);
          },
          responsive: responsive,
        ),
        
        if (_isArtisan) ...[
          SizedBox(height: responsive.getAdaptiveSpacing(16)),
          _buildModernTextField(
            controller: _insuranceCompanyController,
            label: 'Compagnie d\'assurance',
            hint: 'Ex: AXA Assurances',
            icon: Icons.shield_rounded,
            responsive: responsive,
          ),
          SizedBox(height: responsive.getAdaptiveSpacing(16)),
          _buildModernTextField(
            controller: _insurancePolicyController,
            label: 'Numéro de police',
            hint: 'Ex: Police n° 123456789',
            icon: Icons.description_rounded,
            maxLines: 2,
            responsive: responsive,
          ),
        ],
        
        SizedBox(height: responsive.getAdaptiveSpacing(12)),
        
        _buildModernTextField(
          controller: _approvedAssociationController,
          label: 'Association agréée (optionnel)',
          hint: 'Nom de l\'association',
          icon: Icons.verified_rounded,
          responsive: responsive,
        ),
        
        if (!_isAutoEntrepreneur) ...[
          SizedBox(height: responsive.getAdaptiveSpacing(12)),
          _buildModernSwitchTile(
            title: 'Soumis à la TVA',
            subtitle: 'Collecte et facturation de la TVA',
            icon: Icons.assignment_turned_in_rounded,
            value: _hasTVA,
            onChanged: (value) {
              setState(() => _hasTVA = value);
            },
            responsive: responsive,
          ),
        ],
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ResponsiveUtils responsive,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(13),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(14),
            color: const Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF9CA3AF),
              fontSize: responsive.getAdaptiveTextSize(14),
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(icon, color: const Color(0xFF5B5FC7), size: 22),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              borderSide: const BorderSide(color: Color(0xFF5B5FC7), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildModernSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ResponsiveUtils responsive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? const Color(0xFF5B5FC7).withOpacity(0.05) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFF5B5FC7).withOpacity(0.3) : const Color(0xFFE5E7EB),
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? const Color(0xFF5B5FC7).withOpacity(0.1) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? const Color(0xFF5B5FC7) : const Color(0xFF6B7280),
              size: 20,
            ),
          ),
          SizedBox(width: responsive.getAdaptiveSpacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(14),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(12),
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF5B5FC7),
            activeTrackColor: const Color(0xFF5B5FC7).withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B5FC7),
              disabledBackgroundColor: const Color(0xFF5B5FC7).withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: const Color(0xFF5B5FC7).withOpacity(0.3),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.isOnboarding ? 'Créer mon profil' : 'Enregistrer les modifications',
                          style: TextStyle(
                            fontSize: responsive.getAdaptiveTextSize(16),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Completion calculation helpers
  double _calculateIdentificationCompletion() {
    int filled = 0;
    int total = 9;
    
    if (_companyNameController.text.isNotEmpty) filled++;
    if (_companyAddressController.text.isNotEmpty) filled++;
    if (_companySirenController.text.isNotEmpty) filled++;
    if (_companySiretController.text.isNotEmpty) filled++;
    if (_companyLegalFormController.text.isNotEmpty) filled++;
    if (_companyCapitalController.text.isNotEmpty) filled++;
    if (_companyTvaNumberController.text.isNotEmpty) filled++;
    if (_companyPhoneController.text.isNotEmpty) filled++;
    if (_companyEmailController.text.isNotEmpty) filled++;
    
    return (filled / total) * 100;
  }

  double _calculatePaymentCompletion() {
    int filled = 0;
    int total = 4;
    
    if (_ibanController.text.isNotEmpty) filled++;
    if (_bicController.text.isNotEmpty) filled++;
    if (_paymentDelayController.text.isNotEmpty) filled++;
    if (_penaltyRateController.text.isNotEmpty) filled++;
    
    return (filled / total) * 100;
  }

  double _calculateLegalCompletion() {
    int filled = 0;
    int total = 5;
    
    if (_isAutoEntrepreneur || _hasTVA) filled++;
    if (_isArtisan) filled++;
    if (_insuranceCompanyController.text.isNotEmpty && _isArtisan) filled++;
    if (_insurancePolicyController.text.isNotEmpty && _isArtisan) filled++;
    if (_approvedAssociationController.text.isNotEmpty) filled++;
    
    return (filled / total) * 100;
  }

  double _calculateOverallCompletion() {
    return (_calculateIdentificationCompletion() + 
            _calculatePaymentCompletion() + 
            _calculateLegalCompletion()) / 3;
  }

  Color _getCompletionColor(double completion) {
    if (completion < 30) return const Color(0xFFEF4444); // Rouge
    if (completion < 70) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFF10B981); // Vert
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email invalide';
    }

    return null;
  }
}