import 'package:flutter/material.dart';

/// Carte de fonctionnalité responsive
/// S'adapte automatiquement à toutes les tailles d'écran
class FeatureCard extends StatelessWidget {
  final String title;
  final String buttonText;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  const FeatureCard({
    Key? key,
    required this.title,
    required this.buttonText,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calcul responsive de la largeur (60% de l'écran)
    final cardWidth = screenWidth * 0.60;
    // Hauteur fixe proportionnelle
    final cardHeight = screenHeight * 0.20;

    return Container(
      width: cardWidth,
      height: cardHeight,
      padding: EdgeInsets.all(screenWidth * 0.045), // Padding proportionnel
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône avec fond semi-transparent
          Container(
            padding: EdgeInsets.all(screenWidth * 0.028),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: screenWidth * 0.065,
            ),
          ),

          SizedBox(height: cardHeight * 0.08),

          // Titre avec hauteur flexible
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.037,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const Spacer(),

          // Bouton d'action
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.035,
                vertical: screenHeight * 0.008,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  color: backgroundColor,
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}