import 'package:flutter/material.dart';
import '../../../common/utils/responsive_utils.dart';

/// Écran d'abonnement (limite atteinte)
class SubscriptionScreen extends StatelessWidget {
  final int remainingInvoices;

  const SubscriptionScreen({
    Key? key,
    this.remainingInvoices = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
              vertical: responsive.getAdaptiveSpacing(20),
            ),
            child: Column(
              children: [
                SizedBox(height: responsive.getAdaptiveSpacing(20)),

                // Icône Premium
                Container(
                  width: responsive.getAdaptiveSize(90),
                  height: responsive.getAdaptiveSize(90),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(45),
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    size: responsive.getAdaptiveSize(55),
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: responsive.getAdaptiveSpacing(24)),

                // Titre
                Text(
                  'Passez à Premium',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(26),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: responsive.getAdaptiveSpacing(12)),

                // Message
                Text(
                  'Vous avez atteint la limite de 3 factures gratuites.\nPassez à Premium pour créer des factures illimitées !',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(15),
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: responsive.getAdaptiveSpacing(32)),

                // Avantages Premium
                _buildFeature(
                  Icons.check_circle,
                  'Factures illimitées',
                  responsive,
                ),
                _buildFeature(
                  Icons.check_circle,
                  'Tous les templates',
                  responsive,
                ),
                _buildFeature(
                  Icons.check_circle,
                  'Export PDF illimité',
                  responsive,
                ),
                _buildFeature(
                  Icons.check_circle,
                  'Historique complet',
                  responsive,
                ),
                _buildFeature(
                  Icons.check_circle,
                  'Support prioritaire',
                  responsive,
                ),

                SizedBox(height: responsive.getAdaptiveSpacing(32)),

                // Prix
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(responsive.getAdaptiveSpacing(20)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B5FC7), Color(0xFF9C9FE8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '9,99€ /mois',
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(28),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: responsive.getAdaptiveSpacing(6)),
                      Text(
                        'Annulez à tout moment',
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(13),
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: responsive.getAdaptiveSpacing(20)),

                // Bouton S'abonner
                SizedBox(
                  width: double.infinity,
                  height: responsive.getAdaptiveHeight(54),
                  child: ElevatedButton(
                    onPressed: () {
                      _showComingSoon(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B5FC7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'S\'abonner maintenant',
                      style: TextStyle(
                        fontSize: responsive.getAdaptiveTextSize(16),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: responsive.getAdaptiveSpacing(12)),

                // Lien Conditions
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Voir les conditions d\'utilisation',
                    style: TextStyle(
                      fontSize: responsive.getAdaptiveTextSize(13),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                SizedBox(height: responsive.getAdaptiveSpacing(16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text, ResponsiveUtils responsive) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.getAdaptiveSpacing(14)),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF10B981),
            size: responsive.getAdaptiveSize(22),
          ),
          SizedBox(width: responsive.getAdaptiveSpacing(12)),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(15),
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bientôt disponible'),
        content: const Text(
          'Le système de paiement sera bientôt intégré.\n\nPour tester, vous pouvez activer Premium manuellement depuis Firebase Console.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}