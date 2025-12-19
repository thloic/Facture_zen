import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../../common/widgets/feature_card.dart';
import '../../../common/widgets/invoice_card.dart';
import '../../../common/widgets/curved_bottom_nav.dart';

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
      bottomNavigationBar: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return CurvedBottomNav(
            currentIndex: viewModel.currentPageIndex,
            onTap: (index) {
              viewModel.setCurrentPage(index);
            },
          );
        },
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
            child: Icon(
              Icons.person,
              color: const Color(0xFFEF4444),
              size: screenWidth * 0.07,
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
              ],
            ),
          ),

          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_outlined,
                  color: const Color(0xFF1F2937),
                  size: screenWidth * 0.065,
                ),
              ),
              Positioned(
                right: screenWidth * 0.025,
                top: screenWidth * 0.025,
                child: Container(
                  width: screenWidth * 0.02,
                  height: screenWidth * 0.02,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
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

          Container(
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
        ],
      ),
    );
  }

  Widget _buildFeatureCards(double screenHeight) {
    return SizedBox(
      height: screenHeight * 0.20,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          FeatureCard(
            title: 'Faites facilement vos factures et devis juste en parlant',
            buttonText: 'Générer une facture',
            icon: Icons.description_outlined,
            backgroundColor: const Color(0xFF6B8AFF),
            onTap: () {},
          ),

          const SizedBox(width: 16),

          FeatureCard(
            title: 'Créez des factures en illimité en vous abonnant',
            buttonText: 'Abonnement',
            icon: Icons.workspace_premium_outlined,
            backgroundColor: const Color(0xFFFF9F66),
            onTap: () {},
          ),

          const SizedBox(width: 16),

          FeatureCard(
            title: 'Devis',
            buttonText: 'Créer un devis',
            icon: Icons.request_quote_outlined,
            backgroundColor: const Color(0xFF6B8AFF),
            onTap: () {},
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
                onPressed: () {},
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

          ...viewModel.recentInvoices.map((invoice) {
            return InvoiceCard(
              invoice: invoice,
              onTap: () {},
            );
          }).toList(),
        ],
      ),
    );
  }
}