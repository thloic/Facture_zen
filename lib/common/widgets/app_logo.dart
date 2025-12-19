import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;

  const AppLogo({
    Key? key,
    this.fontSize = 28,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Facture',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5B5FC7),
              letterSpacing: 0.5,
            ),
          ),
          TextSpan(
            text: 'Zen',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF5B5FC7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}