import 'package:flutter/material.dart';
import '../../../common/utils/responsive_utils.dart';

/// Écran de confidentialité
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

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
          'Confidentialité',
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
          // Introduction
          Container(
            padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E9F8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: Color(0xFF5B5FC7),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: responsive.getAdaptiveSpacing(12)),
                    Expanded(
                      child: Text(
                        'Politique de confidentialité',
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(18),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(12)),
                Text(
                  'Dernière mise à jour : Janvier 2026',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(12),
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(16)),

          // Sections de confidentialité
          _buildPrivacySection(
            title: 'Collecte des données',
            content: 'Nous collectons uniquement les informations nécessaires au fonctionnement de l\'application : nom, email, et informations de facturation.',
            responsive: responsive,
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(12)),

          _buildPrivacySection(
            title: 'Utilisation des données',
            content: 'Vos données sont utilisées exclusivement pour la création et la gestion de vos factures. Nous ne vendons ni ne partageons vos informations avec des tiers.',
            responsive: responsive,
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(12)),

          _buildPrivacySection(
            title: 'Sécurité',
            content: 'Toutes vos données sont chiffrées et stockées en toute sécurité sur nos serveurs. Nous utilisons les dernières technologies pour protéger vos informations.',
            responsive: responsive,
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(12)),

          _buildPrivacySection(
            title: 'Vos droits',
            content: 'Vous avez le droit d\'accéder, modifier ou supprimer vos données personnelles à tout moment. Contactez-nous pour exercer vos droits.',
            responsive: responsive,
          ),

          SizedBox(height: responsive.getAdaptiveSpacing(24)),

          // Bouton de contact
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contactez-nous à privacy@facturezen.com'),
                    backgroundColor: Color(0xFF5B5FC7),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5FC7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Nous contacter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection({
    required String title,
    required String content,
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
            title,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(16),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: responsive.getAdaptiveSpacing(8)),
          Text(
            content,
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
}
