// lib/features/subscription/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/subscription_view_model.dart';
import '../../../common/utils/responsive_utils.dart';

/// Écran d'abonnement (limite atteinte)
class SubscriptionScreen extends StatefulWidget {
  final int remainingInvoices;

  const SubscriptionScreen({
    Key? key,
    this.remainingInvoices = 0,
  }) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les offres au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionViewModel>().loadOfferings();
    });
  }

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
        child: Consumer<SubscriptionViewModel>(
          builder: (context, viewModel, child) {
            // Afficher un loader pendant le chargement initial
            if (viewModel.isLoading && viewModel.selectedPackage == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5B5FC7),
                ),
              );
            }

            // Afficher une erreur si le chargement a échoué
            if (viewModel.errorMessage != null && viewModel.selectedPackage == null) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(responsive.getAdaptiveSpacing(24)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: responsive.getAdaptiveSize(64),
                        color: Colors.red,
                      ),
                      SizedBox(height: responsive.getAdaptiveSpacing(16)),
                      Text(
                        viewModel.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(15),
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: responsive.getAdaptiveSpacing(24)),
                      ElevatedButton(
                        onPressed: () => viewModel.loadOfferings(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B5FC7),
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.getAdaptiveSpacing(32),
                            vertical: responsive.getAdaptiveSpacing(12),
                          ),
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
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
                      'Vous avez atteint la limite de ${widget.remainingInvoices} factures gratuites.\nPassez à Premium pour créer des factures illimitées !',
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

                    // Prix - Chargé dynamiquement depuis RevenueCat
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
                            viewModel.formattedPrice + viewModel.billingPeriod,
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

                    // Bouton S'abonner avec état de chargement
                    SizedBox(
                      width: double.infinity,
                      height: responsive.getAdaptiveHeight(54),
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : () => _handleSubscription(viewModel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B5FC7),
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: viewModel.isLoading
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                            : Text(
                          'S\'abonner maintenant',
                          style: TextStyle(
                            fontSize: responsive.getAdaptiveTextSize(16),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Afficher les erreurs d'achat
                    if (viewModel.errorMessage != null && viewModel.selectedPackage != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: responsive.getAdaptiveSpacing(12),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(responsive.getAdaptiveSpacing(12)),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: responsive.getAdaptiveSize(20),
                              ),
                              SizedBox(width: responsive.getAdaptiveSpacing(8)),
                              Expanded(
                                child: Text(
                                  viewModel.errorMessage!,
                                  style: TextStyle(
                                    fontSize: responsive.getAdaptiveTextSize(13),
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: responsive.getAdaptiveSpacing(12)),

                    // Bouton Restaurer les achats
                    TextButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _handleRestorePurchases(viewModel),
                      child: Text(
                        'Restaurer mes achats',
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(14),
                          color: viewModel.isLoading
                              ? Colors.grey
                              : const Color(0xFF5B5FC7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    SizedBox(height: responsive.getAdaptiveSpacing(8)),

                    // Lien Conditions
                    TextButton(
                      onPressed: () {
                        // TODO: Ouvrir les conditions d'utilisation
                      },
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
            );
          },
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

  Future<void> _handleSubscription(SubscriptionViewModel viewModel) async {
    final success = await viewModel.purchaseSubscription();

    if (!mounted) return;

    if (success) {
      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Abonnement activé avec succès !'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );

      // Attendre un peu pour que l'utilisateur voie le message
      await Future.delayed(const Duration(milliseconds: 800));

      // Fermer l'écran et retourner true pour indiquer le succès
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
    // Si échec, l'erreur est déjà affichée dans l'UI via viewModel.errorMessage
  }

  Future<void> _handleRestorePurchases(SubscriptionViewModel viewModel) async {
    final success = await viewModel.restorePurchases();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Achats restaurés avec succès !'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B81),
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  viewModel.errorMessage ?? 'Aucun achat à restaurer',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}