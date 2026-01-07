import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../routes/app_routes.dart';

/// CurvedBottomNav
/// Bottom Navigation Bar personnalisée avec effet curved
/// Gère automatiquement la navigation entre les écrans principaux
class CurvedBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CurvedBottomNav({
    Key? key,
    required this.currentIndex,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: currentIndex,
      height: 65,
      backgroundColor: Colors.transparent,
      color: const Color(0xFFE5E7EB), // Gris plus visible
      buttonBackgroundColor: const Color(0xFF5B5FC7),
      animationDuration: const Duration(milliseconds: 300),
      items: [
        // Accueil
        Icon(
          Icons.home_outlined,
          size: 28,
          color: currentIndex == 0 ? Colors.white : const Color(0xFF6B7280),
        ),
        // Facture
        Icon(
          Icons.receipt_long_outlined,
          size: 28,
          color: currentIndex == 1 ? Colors.white : const Color(0xFF6B7280),
        ),
        // Historique
        Icon(
          Icons.history_outlined,
          size: 28,
          color: currentIndex == 2 ? Colors.white : const Color(0xFF6B7280),
        ),
        // Profil
        Icon(
          Icons.person_outline,
          size: 28,
          color: currentIndex == 3 ? Colors.white : const Color(0xFF6B7280),
        ),
      ],
      onTap: (index) {
        // Appeler le callback personnalisé si fourni
        if (onTap != null) {
          onTap!(index);
        } else {
          // Navigation automatique par défaut
          _navigateToScreen(context, index);
        }
      },
    );
  }

  /// Navigation automatique vers les écrans correspondants
  void _navigateToScreen(BuildContext context, int index) {
    // Ne pas naviguer si on est déjà sur l'écran
    if (index == currentIndex) return;

    switch (index) {
      case 0:
      // Accueil - TODO: Créer HomeScreen
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
      // Facture
        Navigator.pushNamed(context, '/record');
        break;
      case 2:
      // Historique
        Navigator.pushNamed(context, '/historiqueInvoicing');
        break;
      case 3:
      // Profil
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }
}