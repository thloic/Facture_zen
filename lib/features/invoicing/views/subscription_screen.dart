// lib/features/subscription/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/subscription_view_model.dart';
import '../../../common/utils/responsive_utils.dart';
import '../services/revenue_cat_service.dart' show Package;

/// Écran d'abonnement amélioré (limite atteinte)
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
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionViewModel>().loadOfferings();
    });
  }

  // ✅ Fonction pour mapper les noms des offres selon l'ID RevenueCat
  String _getDisplayPlanName(String productId, String originalTitle) {
    switch (productId) {
      case 'zen-basic-monthly':
        return 'ESSENTIEL';
      case 'zen-pro-monthly':
        return 'PRO';
      case 'zen-entreprise-monthly':
        return 'ILLIMITÉ';
      default:
        return originalTitle;
    }
  }

  // ✅ Fonction pour mapper les descriptions
  String _getDisplayDescription(String productId, String originalDescription) {
    switch (productId) {
      case 'zen-basic-monthly':
        return '200 factures / mois';
      case 'zen-pro-monthly':
        return '500 factures / mois';
      case 'zen-entreprise-monthly':
        return 'Factures illimitées';
      default:
        return originalDescription;
    }
  }

  // ✅ Fonction pour mapper les badges
  String _getDisplayBadge(String productId, String originalBadge) {
    switch (productId) {
      case 'zen-basic-monthly':
        return 'ESSENTIEL';
      case 'zen-pro-monthly':
        return 'PRO';
      case 'zen-entreprise-monthly':
        return 'ILLIMITÉ';
      default:
        return originalBadge;
    }
  }

  // ✅ Fonction pour déterminer si c'est l'offre populaire
  bool _isPopular(String productId) {
    // Par exemple, l'offre PRO est populaire
    return productId == 'zen-pro-monthly';
  }

  // ✅ Fonction pour les couleurs des badges
  Color _getBadgeColor(String productId) {
    switch (productId) {
      case 'zen-basic-monthly':
        return const Color(0xFF10B981); // Vert
      case 'zen-pro-monthly':
        return const Color(0xFF5B5FC7); // Violet
      case 'zen-entreprise-monthly':
        return const Color(0xFFF59E0B); // Orange
      default:
        return const Color(0xFF9CA3AF); // Gris
    }
  }

  // ✅ Fonction pour les fonctionnalités détaillées
  List<String> _getFeatures(String productId) {
    switch (productId) {
      case 'zen-basic-monthly':
        return [
          '✓ 200 factures par mois',
          '✓ 3 modèles de facture',
          '✓ Transcription vocale IA',
          '✓ Export PDF instantané',
          '✓ Chatbot assistance 24/7',
          '✓ Historique de vos factures',
        ];
      case 'zen-pro-monthly':
        return [
          '✓ 500 factures par mois',
          '✓ 5 modèles de facture',
          '✓ Transcription vocale IA',
          '✓ Export PDF instantané',
          '✓ Chatbot assistance 24/7',
          '✓ Historique de vos factures',
          '✓ Support prioritaire',
        ];
      case 'zen-entreprise-monthly':
        return [
          '✓ Factures illimitées',
          '✓ Modèles de facture illimités',
          '✓ Transcription vocale IA',
          '✓ Export PDF instantané',
          '✓ Chatbot assistance 24/7',
          '✓ Historique de vos factures',
          '✓ Support prioritaire 7j/7',
          '✓ API personnalisée',
        ];
      default:
        return [
          '✓ Factures incluses',
          '✓ Support inclus',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choisissez votre offre',
          style: TextStyle(color: Color(0xFF1F2937)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<SubscriptionViewModel>(
          builder: (context, viewModel, child) {
            // Afficher un loader pendant le chargement initial
            if (viewModel.isLoading && viewModel.allPackages == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF5B5FC7),
                    ),
                    SizedBox(height: responsive.getAdaptiveSpacing(16)),
                    Text(
                      'Chargement des offres...',
                      style: TextStyle(
                        fontSize: responsive.getAdaptiveTextSize(14),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Afficher une erreur si le chargement a échoué
            if (viewModel.errorMessage != null && viewModel.allPackages == null) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(responsive.getAdaptiveSpacing(24)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: responsive.getAdaptiveSize(64),
                        color: Colors.red.shade400,
                      ),
                      SizedBox(height: responsive.getAdaptiveSpacing(16)),
                      Text(
                        viewModel.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(15),
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: responsive.getAdaptiveSpacing(24)),
                      ElevatedButton.icon(
                        onPressed: () => viewModel.loadOfferings(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B5FC7),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.getAdaptiveSpacing(32),
                            vertical: responsive.getAdaptiveSpacing(14),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final packages = viewModel.allPackages ?? [];

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                  vertical: responsive.getAdaptiveSpacing(16),
                ),
                child: Column(
                  children: [
                    // Icône Premium avec animation
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: responsive.getAdaptiveSize(85),
                        height: responsive.getAdaptiveSize(85),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(42.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.workspace_premium,
                          size: responsive.getAdaptiveSize(48),
                          color: Colors.white,
                        ),
                      ),
                    ),

                    SizedBox(height: responsive.getAdaptiveSpacing(20)),

                    // Titre
                    Text(
                      'Passez à Premium',
                      style: TextStyle(
                        fontSize: responsive.getAdaptiveTextSize(26),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: responsive.getAdaptiveSpacing(10)),

                    // Message avec meilleur formatage
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.getAdaptiveSpacing(16),
                        vertical: responsive.getAdaptiveSpacing(12),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: responsive.getAdaptiveSize(20),
                          ),
                          SizedBox(width: responsive.getAdaptiveSpacing(8)),
                          Flexible(
                            child: Text(
                              'Limite de 3 factures atteinte',
                              style: TextStyle(
                                fontSize: responsive.getAdaptiveTextSize(14),
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: responsive.getAdaptiveSpacing(28)),

                    // Liste des offres avec accordions améliorés
                    if (packages.isEmpty)
                      Container(
                        padding: EdgeInsets.all(responsive.getAdaptiveSpacing(32)),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: responsive.getAdaptiveSize(48),
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: responsive.getAdaptiveSpacing(12)),
                            Text(
                              'Aucune offre disponible',
                              style: TextStyle(
                                fontSize: responsive.getAdaptiveTextSize(14),
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...packages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final package = entry.value;
                        final isSelected = viewModel.isPackageSelected(package);
                        final isExpanded = _expandedIndex == index;
                        final productId = package.identifier;

                        return _buildSubscriptionCard(
                          package: package,
                          productId: productId,
                          index: index,
                          isSelected: isSelected,
                          isExpanded: isExpanded,
                          responsive: responsive,
                          viewModel: viewModel,
                          screenWidth: screenWidth,
                        );
                      }).toList(),

                    SizedBox(height: responsive.getAdaptiveSpacing(28)),

                    // Bouton S'abonner amélioré
                    Container(
                      width: double.infinity,
                      height: responsive.getAdaptiveHeight(56),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: viewModel.selectedPackage != null &&
                            !viewModel.isLoading
                            ? [
                          BoxShadow(
                            color: const Color(0xFF5B5FC7).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                            : [],
                      ),
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading ||
                            viewModel.selectedPackage == null
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
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_open,
                              size: responsive.getAdaptiveSize(18),
                            ),
                            SizedBox(
                                width: responsive.getAdaptiveSpacing(6)),
                            Flexible(
                              child: Text(
                                'S\'abonner maintenant',
                                style: TextStyle(
                                  fontSize:
                                  responsive.getAdaptiveTextSize(14),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Afficher les erreurs d'achat
                    if (viewModel.errorMessage != null &&
                        viewModel.selectedPackage != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: responsive.getAdaptiveSpacing(16),
                        ),
                        child: Container(
                          padding:
                          EdgeInsets.all(responsive.getAdaptiveSpacing(14)),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: responsive.getAdaptiveSize(22),
                              ),
                              SizedBox(
                                  width: responsive.getAdaptiveSpacing(10)),
                              Expanded(
                                child: Text(
                                  viewModel.errorMessage!,
                                  style: TextStyle(
                                    fontSize:
                                    responsive.getAdaptiveTextSize(13),
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: responsive.getAdaptiveSpacing(16)),

                    // Bouton Restaurer les achats
                    TextButton.icon(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _handleRestorePurchases(viewModel),
                      icon: Icon(
                        Icons.restore,
                        size: responsive.getAdaptiveSize(18),
                      ),
                      label: Text(
                        'Restaurer mes achats',
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: viewModel.isLoading
                            ? Colors.grey
                            : const Color(0xFF5B5FC7),
                      ),
                    ),

                    SizedBox(height: responsive.getAdaptiveSpacing(4)),

                    // Lien Conditions
                    TextButton(
                      onPressed: () {
                        // TODO: Ouvrir les conditions d'utilisation
                      },
                      child: Text(
                        'Conditions d\'utilisation et politique de confidentialité',
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(12),
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: responsive.getAdaptiveSpacing(12)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required Package package,
    required String productId,
    required int index,
    required bool isSelected,
    required bool isExpanded,
    required ResponsiveUtils responsive,
    required SubscriptionViewModel viewModel,
    required double screenWidth,
  }) {
    final price = viewModel.getPackagePrice(package);
    final billingPeriod = viewModel.getPackageBillingPeriod(package);
    
    // ✅ Utiliser les noms d'affichage personnalisés
    final displayName = _getDisplayPlanName(productId, '');
    final displayDescription = _getDisplayDescription(productId, '');
    final displayBadge = _getDisplayBadge(productId, '');
    final isPopular = _isPopular(productId);
    final badgeColor = _getBadgeColor(productId);
    final features = _getFeatures(productId);

    // Calculer les tailles adaptatives pour éviter les overflow
    final cardPadding = responsive.getAdaptiveSpacing(14);
    final availableWidth = screenWidth - (responsive.horizontalPadding * 2);

    return Padding(
      padding: EdgeInsets.only(bottom: responsive.getAdaptiveSpacing(14)),
      child: GestureDetector(
        onTap: () {
          setState(() {
            viewModel.selectPackage(package);
            _expandedIndex = isExpanded ? null : index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5B5FC7)
                  : Colors.grey.shade300,
              width: isSelected ? 2.5 : 1,
            ),
            borderRadius: BorderRadius.circular(18),
            color: isSelected
                ? const Color(0xFF5B5FC7).withOpacity(0.06)
                : Colors.white,
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFF5B5FC7).withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ]
                : [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: [
              // En-tête de la carte
              Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Radio button
                        Container(
                          width: responsive.getAdaptiveSize(24),
                          height: responsive.getAdaptiveSize(24),
                          margin: EdgeInsets.only(
                            top: responsive.getAdaptiveSpacing(2),
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF5B5FC7)
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                            child: Container(
                              width: responsive.getAdaptiveSize(12),
                              height: responsive.getAdaptiveSize(12),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF5B5FC7),
                              ),
                            ),
                          )
                              : null,
                        ),

                        SizedBox(width: responsive.getAdaptiveSpacing(12)),

                        // Infos principales (flexible pour éviter overflow)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badges
                              Wrap(
                                spacing: responsive.getAdaptiveSpacing(6),
                                runSpacing: responsive.getAdaptiveSpacing(6),
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                      responsive.getAdaptiveSpacing(8),
                                      vertical:
                                      responsive.getAdaptiveSpacing(5),
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      displayBadge,
                                      style: TextStyle(
                                        fontSize: responsive
                                            .getAdaptiveTextSize(10),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isPopular)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                        responsive.getAdaptiveSpacing(8),
                                        vertical:
                                        responsive.getAdaptiveSpacing(5),
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD700),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size:
                                            responsive.getAdaptiveSize(11),
                                            color: Colors.white,
                                          ),
                                          SizedBox(
                                              width: responsive
                                                  .getAdaptiveSpacing(3)),
                                          Flexible(
                                            child: Text(
                                              'POPULAIRE',
                                              style: TextStyle(
                                                fontSize: responsive
                                                    .getAdaptiveTextSize(9),
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(
                                  height: responsive.getAdaptiveSpacing(10)),
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: responsive.getAdaptiveTextSize(20),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937),
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(
                                  height: responsive.getAdaptiveSpacing(5)),
                              Text(
                                displayDescription,
                                style: TextStyle(
                                  fontSize: responsive.getAdaptiveTextSize(12),
                                  color: Colors.grey.shade600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: responsive.getAdaptiveSpacing(12)),

                        // Prix (colonne fixe)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              price,
                              style: TextStyle(
                                fontSize: responsive.getAdaptiveTextSize(20),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5B5FC7),
                              ),
                            ),
                            Text(
                              billingPeriod,
                              style: TextStyle(
                                fontSize: responsive.getAdaptiveTextSize(11),
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        // Icône d'expansion
                        Padding(
                          padding: EdgeInsets.only(
                            left: responsive.getAdaptiveSpacing(8),
                          ),
                          child: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey.shade600,
                            size: responsive.getAdaptiveSize(24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Contenu détaillé (accordion)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    cardPadding,
                    0,
                    cardPadding,
                    cardPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        color: Colors.grey.shade300,
                        height: 1,
                      ),
                      SizedBox(
                          height: responsive.getAdaptiveSpacing(14)),
                      ...features.map(
                            (feature) => Padding(
                              padding: EdgeInsets.only(
                                bottom: responsive.getAdaptiveSpacing(10),
                              ),
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: responsive.getAdaptiveTextSize(13),
                                  color: const Color(0xFF1F2937),
                                  height: 1.4,
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubscription(SubscriptionViewModel viewModel) async {
    final success = await viewModel.purchaseSubscription();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Abonnement activé avec succès !',
                  style: TextStyle(
                    fontSize: ResponsiveUtils(context).getAdaptiveTextSize(14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _handleRestorePurchases(SubscriptionViewModel viewModel) async {
    final success = await viewModel.restorePurchases();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Achats restaurés avec succès !',
                  style: TextStyle(
                    fontSize: ResponsiveUtils(context).getAdaptiveTextSize(14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  viewModel.errorMessage ?? 'Aucun achat à restaurer',
                  style: TextStyle(
                    fontSize: ResponsiveUtils(context).getAdaptiveTextSize(14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}