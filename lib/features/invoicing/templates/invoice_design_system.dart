import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InvoiceDesignSystem {
  // BorderRadius
  static const BorderRadius borderRadius = BorderRadius.all(Radius.circular(20));
  static const double borderRadiusValue = 20.0;

  // BoxShadow
  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  // Palette de couleurs
  static const Color primary = Color(0xFF5B5FC7);
  static const Color accent = Color(0xFF10B981);
  static const Color background = Color(0xFFF9FAFB);
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color amountColor = Color(0xFF111827);

  // Typographie
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static TextStyle body = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  static TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
  static TextStyle amount = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: amountColor,
    letterSpacing: -0.5,
  );
  static TextStyle amountTotal = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: accent,
    letterSpacing: -1,
  );
}
