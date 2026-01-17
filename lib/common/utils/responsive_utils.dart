import 'package:flutter/material.dart';

class ResponsiveUtils {
  final BuildContext context;

  ResponsiveUtils(this.context);

  /// Largeur de l'écran
  double get screenWidth => MediaQuery.of(context).size.width;

  /// Hauteur de l'écran
  double get screenHeight => MediaQuery.of(context).size.height;

  /// Hauteur sans les zones système (status bar, notch, etc.)
  double get safeHeight => MediaQuery.of(context).size.height -
      MediaQuery.of(context).padding.top -
      MediaQuery.of(context).padding.bottom;

  /// Retourne true si c'est un petit écran (< 360dp)
  bool get isSmallScreen => screenWidth < 360;

  /// Retourne true si c'est un écran moyen (360-400dp)
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 400;

  /// Retourne true si c'est un grand écran (>= 400dp)
  bool get isLargeScreen => screenWidth >= 400;

  /// Padding horizontal adaptatif
  /// Petit écran: 20, Moyen: 24, Grand: 28
  double get horizontalPadding {
    if (isSmallScreen) return 20.0;
    if (isMediumScreen) return 24.0;
    return 28.0;
  }

  /// Adapte la taille du texte selon l'écran
  double getAdaptiveTextSize(double baseSize) {
    if (isSmallScreen) return baseSize * 0.9;
    if (isLargeScreen) return baseSize * 1.05;
    return baseSize;
  }

  /// Adapte l'espacement selon l'écran
  double getAdaptiveSpacing(double baseSpacing) {
    if (isSmallScreen) return baseSpacing * 0.8;
    if (isLargeScreen) return baseSpacing * 1.1;
    return baseSpacing;
  }

  /// Adapte la hauteur des éléments selon l'écran
  double getAdaptiveHeight(double baseHeight) {
    if (isSmallScreen) return baseHeight * 0.9;
    return baseHeight;
  }

  /// ✅ MÉTHODE MANQUANTE : Adapte les tailles génériques (icônes, conteneurs, etc.)
  double getAdaptiveSize(double baseSize) {
    if (isSmallScreen) return baseSize * 0.85;
    if (isLargeScreen) return baseSize * 1.1;
    return baseSize;
  }
}