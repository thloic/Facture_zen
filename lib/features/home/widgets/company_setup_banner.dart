import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';
import '../../profile/views/company_profile_setup_screen.dart';

/// Widget - Banner pour configurer l'entreprise
/// Affiché uniquement si les informations entreprise ne sont pas configurées
class CompanySetupBanner extends StatefulWidget {
  const CompanySetupBanner({Key? key}) : super(key: key);

  @override
  State<CompanySetupBanner> createState() => _CompanySetupBannerState();
}

class _CompanySetupBannerState extends State<CompanySetupBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadBannerDismissedState();
    
    // Animation de clignotement
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  /// Charger l'état du banner (caché ou non)
  Future<void> _loadBannerDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bannerDismissed = prefs.getBool('company_setup_banner_dismissed') ?? false;
    });
  }

  /// Marquer le banner comme caché
  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('company_setup_banner_dismissed', true);
    setState(() {
      _bannerDismissed = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<ProfileViewModel>(
      builder: (context, profileViewModel, child) {
        // Vérifier si le banner a été caché manuellement
        if (_bannerDismissed) {
          return const SizedBox.shrink();
        }

        // Vérifier si l'entreprise n'est pas configurée
        final companyName = profileViewModel.companyName;
        // On considère l'entreprise non configurée si l'adresse est non renseignée ou par défaut 
        // OU si le nom de l'entreprise est "Entreprise" (valeur par défaut)
        final isConfigured = companyName != null && 
                            companyName.isNotEmpty && 
                            companyName != 'Entreprise' && 
                            profileViewModel.userCompanyAddress != null && 
                            profileViewModel.userCompanyAddress != 'Adresse non renseignée' &&
                            profileViewModel.userCompanyAddress!.isNotEmpty;

        debugPrint('🏢 Banner check - Company: $companyName, IsConfigured: $isConfigured');

        // Si déjà configuré, ne rien afficher avec un SizedBox.shrink (espace vide)
        if (isConfigured) {
          return const SizedBox.shrink();
        }

        // Afficher le banner de configuration avec animation
        return FadeTransition(
          opacity: _opacityAnimation,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.055),
            child: InkWell(
              onTap: () async {
                // Cacher le banner dès que l'utilisateur clique
                await _dismissBanner();
                
                // Naviguer vers la page de configuration
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyProfileSetupScreen(isOnboarding: false),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B5FC7), Color(0xFF7C7FDC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B5FC7).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.025),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business_outlined,
                        color: Colors.white,
                        size: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configurez votre entreprise',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.01),
                          Text(
                            'Ajoutez vos informations pour vos factures',
                            style: TextStyle(
                              fontSize: screenWidth * 0.032,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: screenWidth * 0.045,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}