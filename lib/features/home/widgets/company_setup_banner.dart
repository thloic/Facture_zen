import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';

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

  @override
  void initState() {
    super.initState();
    // Animation de clignotement
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        // Vérifier si l'entreprise n'est pas configurée
        final companyName = profileViewModel.companyName;
        final companyAddress = profileViewModel.userCompanyAddress;

        debugPrint('🏢 Banner check - Company: $companyName, Address: $companyAddress');

        // Si déjà configuré, ne rien afficher
        if ((companyName != null && companyName.isNotEmpty) && 
            (companyAddress != null && companyAddress.isNotEmpty)) {
          return const SizedBox.shrink();
        }

        // Afficher le banner de configuration avec animation
        return FadeTransition(
          opacity: _opacityAnimation,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.055),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/company-setup');
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