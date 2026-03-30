import 'package:facture_zen/common/providers/premium_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../notifications/viewmodels/notification_viewmodel.dart';
import '../../../common/widgets/feature_card.dart';
import '../../../common/widgets/invoice_card.dart';
import '../../../common/widgets/curved_bottom_nav.dart';
import '../widgets/company_setup_banner.dart';

/// HomeScreen - 100% Fidèle au Design
/// Responsive et adaptatif à tous les écrans
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadInitialData();
      context.read<NotificationViewModel>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5B5FC7),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.02),

                        _buildHeader(viewModel, screenWidth),

                        SizedBox(height: screenHeight * 0.025),

                        // Banner de configuration entreprise
                        const CompanySetupBanner(),

                        SizedBox(height: screenHeight * 0.025),

                        _buildSearchBar(viewModel, screenWidth),

                        SizedBox(height: screenHeight * 0.025),

                        _buildFeatureCards(screenHeight),

                        SizedBox(height: screenHeight * 0.03),

                        _buildRecentInvoicesSection(viewModel, screenWidth),

                        SizedBox(height: screenHeight * 0.1),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const CurvedBottomNav(
        currentIndex: 0,
      ),
    );
  }

  Widget _buildHeader(HomeViewModel viewModel, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.055),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '👤',
                style: TextStyle(fontSize: screenWidth * 0.07),
              ),
            ),
          ),

          SizedBox(width: screenWidth * 0.03),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue',
                  style: TextStyle(
                    fontSize: screenWidth * 0.033,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: screenWidth * 0.005),
                Text(
                  viewModel.userProfile?.fullName ?? 'Utilisateur',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                    Consumer<PremiumProvider>(
                      builder: (context, premium, _) {
                        if (premium.isPremium) {
                          return Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B5FC7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF5B5FC7).withOpacity(0.3)),
                            ),
                            child: Text(
                              premium.planName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5B5FC7),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
              ],
            ),
          ),

          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                icon: Icon(
                  Icons.notifications_outlined,
                  color: const Color(0xFF1F2937),
                  size: screenWidth * 0.065,
                ),
              ),
              Consumer<NotificationViewModel>(
                builder: (context, notificationViewModel, _) {
                  final unreadCount = notificationViewModel.unreadCount;
                  
                  if (unreadCount == 0) {
                    return const SizedBox.shrink();
                  }
                  
                  return Positioned(
                    right: screenWidth * 0.02,
                    top: screenWidth * 0.02,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: screenWidth * 0.045,
                        minHeight: screenWidth * 0.045,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.025,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(HomeViewModel viewModel, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.055),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: viewModel.updateSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Recherchez une facture',
                  hintStyle: TextStyle(
                    color: const Color(0xFF9CA3AF),
                    fontSize: screenWidth * 0.035,
                  ),
                  border: InputBorder.none,
                  icon: Icon(
                    Icons.search,
                    color: const Color(0xFF9CA3AF),
                    size: screenWidth * 0.05,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenWidth * 0.035,
                  ),
                ),
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
          ),

          SizedBox(width: screenWidth * 0.03),

          GestureDetector(
            onTap: () => _showSortMenu(context, viewModel, screenWidth),
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tune,
                color: const Color(0xFF1F2937),
                size: screenWidth * 0.055,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortMenu(BuildContext context, HomeViewModel viewModel, double screenWidth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.055,
          vertical: screenWidth * 0.05,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                Icon(
                  Icons.sort,
                  color: const Color(0xFF1F2937),
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.03),
                Text(
                  'Trier par',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.05),
            
            // Option: Date
            _buildSortOption(
              context,
              viewModel,
              screenWidth,
              icon: Icons.calendar_today,
              title: 'Date',
              subtitle: 'Plus récentes en premier',
              value: 'date',
              isSelected: viewModel.sortBy == 'date',
            ),
            
            SizedBox(height: screenWidth * 0.03),
            
            // Option: Nom
            _buildSortOption(
              context,
              viewModel,
              screenWidth,
              icon: Icons.sort_by_alpha,
              title: 'Nom',
              subtitle: 'Ordre alphabétique',
              value: 'name',
              isSelected: viewModel.sortBy == 'name',
            ),
            
            SizedBox(height: screenWidth * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    HomeViewModel viewModel,
    double screenWidth, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        viewModel.setSortBy(value);
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B5FC7).withOpacity(0.1) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B5FC7) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.025),
              decoration: BoxDecoration(
                color: isSelected 
                  ? const Color(0xFF5B5FC7) 
                  : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                size: screenWidth * 0.05,
              ),
            ),
            SizedBox(width: screenWidth * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF5B5FC7),
                size: screenWidth * 0.055,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCards(double screenHeight) {
    return SizedBox(
      height: screenHeight * 0.22,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          FeatureCard(
            title: 'Créez vos factures par voix',
            buttonText: 'Générer une facture',
            icon: Icons.description_outlined,
            backgroundColor: const Color(0xFF6B8AFF),
            onTap: () {
              Navigator.pushNamed(context, '/record');
            },
          ),

          const SizedBox(width: 16),

          FeatureCard(
            title: 'Factures illimitées',
            buttonText: 'Abonnement',
            icon: Icons.workspace_premium_outlined,
            backgroundColor: const Color(0xFFFF9F66),
            onTap: () async {
              final subscribed = await Navigator.pushNamed(
                context,
                '/subscription-screen',
              );
              if (subscribed == true && mounted) {
                // Rafraîchir les données du home (limite factures, etc.)
                context.read<HomeViewModel>().loadInitialData();
              }
            },
          ),

          const SizedBox(width: 16),

          FeatureCard(
            title: 'Créer un devis professionnel',
            buttonText: 'Créer un devis',
            icon: Icons.request_quote_outlined,
            backgroundColor: const Color(0xFF6B8AFF),
            onTap: () {
              Navigator.pushNamed(context, '/record');
            },

          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoicesSection(HomeViewModel viewModel, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.055),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Factures récentes',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/historiqueInvoicing');
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      'Voir plus',
                      style: TextStyle(
                        color: const Color(0xFF5B5FC7),
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Icon(
                      Icons.arrow_forward,
                      color: const Color(0xFF5B5FC7),
                      size: screenWidth * 0.04,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: screenWidth * 0.04),

          ...viewModel.filteredInvoices.map((invoice) {
            return InvoiceCard(
              invoice: invoice,
              onTap: () {
                // Naviguer vers la page historique
                Navigator.pushNamed(context, '/historiqueInvoicing');
              },
            );
          }).toList(),

          if (viewModel.filteredInvoices.isEmpty && viewModel.searchQuery.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.1),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: screenWidth * 0.15,
                      color: const Color(0xFF9CA3AF),
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    Text(
                      'Aucune facture trouvée',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}