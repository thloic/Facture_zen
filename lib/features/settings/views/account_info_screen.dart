import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/utils/responsive_utils.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';
import 'edit_profile_screen.dart';

/// Écran des informations du compte
class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({Key? key}) : super(key: key);

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
          'Infos du compte',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          return ListView(
            padding: EdgeInsets.all(responsive.horizontalPadding),
            children: [
              // Avatar
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF5B5FC7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: viewModel.userAvatarUrl != null
                        ? Image.network(
                            viewModel.userAvatarUrl!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(24)),

              // Informations du compte
              _buildInfoCard(
                label: 'Prénom',
                value: viewModel.firstName ?? 'Non renseigné',
                icon: Icons.person_outline,
                responsive: responsive,
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              _buildInfoCard(
                label: 'Nom',
                value: viewModel.lastName ?? 'Non renseigné',
                icon: Icons.person_outline,
                responsive: responsive,
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              _buildInfoCard(
                label: 'Email',
                value: viewModel.userEmail ?? 'Non renseigné',
                icon: Icons.email_outlined,
                responsive: responsive,
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              _buildInfoCard(
                label: 'Entreprise',
                value: viewModel.companyName ?? 'Non renseignée',
                icon: Icons.business_outlined,
                responsive: responsive,
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(24)),

              // Bouton Modifier
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
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
                    'Modifier le profil',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
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
                  label,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(12),
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(4)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(16),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
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
