import 'package:flutter/material.dart';
import '../../../common/utils/responsive_utils.dart';

/// Écran À propos
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'À propos',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(responsive.horizontalPadding),
        children: [
          // Logo et nom de l'app
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B5FC7),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B5FC7).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.description,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(16)),
                Text(
                  'Facture Zen',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(24),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(8)),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(14),
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(32)),

          // Description
          Container(
            padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'À propos de l\'application',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(16),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(8)),
                Text(
                  'Facture Zen est votre assistant de facturation intelligent. Créez des factures professionnelles par simple commande vocale et gérez votre activité en toute simplicité.',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(14),
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(16)),

          // Fonctionnalités
          Container(
            padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fonctionnalités',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(16),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(12)),
                _buildFeatureItem('✓', 'Création de factures par voix', responsive),
                _buildFeatureItem('✓', 'Gestion des clients', responsive),
                _buildFeatureItem('✓', 'Historique des factures', responsive),
                _buildFeatureItem('✓', 'Export PDF', responsive),
              ],
            ),
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(16)),

          // Contact
          Container(
            padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(16),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(12)),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Color(0xFF5B5FC7), size: 20),
                    SizedBox(width: responsive.getAdaptiveSpacing(8)),
                    Text(
                      'support@facturezen.com',
                      style: TextStyle(
                        fontSize: responsive.getAdaptiveTextSize(14),
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(8)),
                Row(
                  children: [
                    const Icon(Icons.language, color: Color(0xFF5B5FC7), size: 20),
                    SizedBox(width: responsive.getAdaptiveSpacing(8)),
                    Text(
                      'www.facturezen.com',
                      style: TextStyle(
                        fontSize: responsive.getAdaptiveTextSize(14),
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(24)),

          // Copyright
          Center(
            child: Text(
              '© 2026 Facture Zen. Tous droits réservés.',
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(12),
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String bullet, String text, ResponsiveUtils responsive) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.getAdaptiveSpacing(8)),
      child: Row(
        children: [
          Text(
            bullet,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(16),
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: responsive.getAdaptiveSpacing(8)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(14),
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
