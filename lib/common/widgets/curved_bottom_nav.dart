import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

/// Bottom Navigation Bar personnalisée avec effet curved
class CurvedBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CurvedBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: currentIndex,
      height: 65,
      backgroundColor: Colors.transparent,
      color: const Color(0xFFF9FAFB), // Gris clair du design
      buttonBackgroundColor: const Color(0xFF5B5FC7),
      animationDuration: const Duration(milliseconds: 300),
      items: const [
        Icon(Icons.home_outlined, size: 28, color: Color(0xFF6B7280)),
        Icon(Icons.receipt_long_outlined, size: 28, color: Colors.white),
        Icon(Icons.history_outlined, size: 28, color: Color(0xFF6B7280)),
        Icon(Icons.person_outline, size: 28, color: Color(0xFF6B7280)),
      ],
      onTap: onTap,
    );
  }
}