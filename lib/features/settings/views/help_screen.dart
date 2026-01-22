import 'package:flutter/material.dart';
import '../../../common/utils/responsive_utils.dart';

/// Écran d'aide
class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

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
          'Aide',
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
          // Section FAQ
          Text(
            'Questions fréquentes',
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(18),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(16)),

          _buildFaqItem(
            question: 'Comment créer une facture par voix ?',
            answer: 'Appuyez sur le bouton "Générer une facture" sur l\'écran d\'accueil, puis enregistrez les détails de votre facture vocalement.',
            responsive: responsive,
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(12)),

          _buildFaqItem(
            question: 'Où puis-je voir mes factures ?',
            answer: 'Toutes vos factures sont disponibles dans la section "Factures récentes" ou en appuyant sur "Voir plus".',
            responsive: responsive,
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(12)),

          _buildFaqItem(
            question: 'Comment modifier mon profil ?',
            answer: 'Allez dans Profil > Infos du compte, puis cliquez sur "Modifier le profil".',
            responsive: responsive,
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(24)),

          // Section Contact
          Text(
            'Besoin d\'aide ?',
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(18),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(16)),

          _buildContactCard(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'support@facturezen.com',
            responsive: responsive,
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(12)),

          _buildContactCard(
            icon: Icons.phone_outlined,
            title: 'Téléphone',
            subtitle: '+33 1 23 45 67 89',
            responsive: responsive,
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
    required ResponsiveUtils responsive,
  }) {
    return Container(
      padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(16),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: responsive.getAdaptiveSpacing(8)),
          Text(
            answer,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(14),
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required ResponsiveUtils responsive,
  }) {
    return Container(
      padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E9F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF5B5FC7), size: 20),
          ),

          SizedBox(width: responsive.getAdaptiveSpacing(16)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(14),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(4)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(14),
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
