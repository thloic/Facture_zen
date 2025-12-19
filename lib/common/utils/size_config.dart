import 'package:flutter/material.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  /// Initialise les dimensions de l'écran
  /// Doit être appelé dans le build de l'écran principal
  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    final safeAreaHorizontal = _mediaQueryData.padding.left +
        _mediaQueryData.padding.right;
    final safeAreaVertical = _mediaQueryData.padding.top +
        _mediaQueryData.padding.bottom;

    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;
  }

  /// Retourne un pourcentage de la largeur de l'écran
  static double widthPercent(double percent) {
    return blockSizeHorizontal * percent;
  }

  /// Retourne un pourcentage de la hauteur de l'écran
  static double heightPercent(double percent) {
    return blockSizeVertical * percent;
  }
}