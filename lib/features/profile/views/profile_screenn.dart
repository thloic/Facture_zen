import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/widgets/curved_bottom_nav.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../../../common/utils/responsive_utils.dart';
import '../../auth/views/login_screen.dart';
import 'dart:math' as math;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      body: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              // Background avec dégradé et motifs SVG
              _buildBackground(context),

              // Contenu principal
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: responsive.getAdaptiveSpacing(20)),

                    // Titre "Profil"
                    Text(
                      'Profil',
                      style: TextStyle(
                        fontSize: responsive.getAdaptiveTextSize(20),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: responsive.getAdaptiveSpacing(40)),

                    // Avatar et nom
                    _buildUserAvatar(viewModel, responsive),

                    SizedBox(height: responsive.getAdaptiveSpacing(40)),

                    // Carte blanche avec les options
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.horizontalPadding,
                            vertical: responsive.getAdaptiveSpacing(24),
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: Icons.person_outline,
                                label: 'Infos du compte',
                                iconColor: const Color(0xFF5B5FC7),
                                iconBgColor: const Color(0xFFE8E9F8),
                                onTap: () => _navigateToAccountInfo(context),
                                responsive: responsive,
                              ),
                              SizedBox(
                                height: responsive.getAdaptiveSpacing(12),
                              ),
                              _buildMenuItem(
                                icon: Icons.settings_outlined,
                                label: 'Paramètres',
                                iconColor: const Color(0xFF5B5FC7),
                                iconBgColor: const Color(0xFFE8E9F8),
                                onTap: () => _navigateToSettings(context),
                                responsive: responsive,
                              ),
                              SizedBox(
                                height: responsive.getAdaptiveSpacing(12),
                              ),
                              _buildMenuItem(
                                icon: Icons.logout,
                                label: 'Déconnexion',
                                iconColor: const Color(0xFFEF4444),
                                iconBgColor: const Color(0xFFFFE5E5),
                                onTap: () => _confirmLogout(context, viewModel),
                                responsive: responsive,
                                isDestructive: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const CurvedBottomNav(
        currentIndex: 3, // Index 3 = Profil
      ),
    );
  }

  /// Widget - Background avec dégradé violet et motifs SVG
  Widget _buildBackground(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B7FE8), Color(0xFF5B5FC7)],
        ),
      ),
      child: CustomPaint(
        painter: ProfileBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }

  /// Widget - Avatar et nom de l'utilisateur
  Widget _buildUserAvatar(
    ProfileViewModel viewModel,
    ResponsiveUtils responsive,
  ) {
    return Column(
      children: [
        // Avatar circulaire
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
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
                ? Image.network(viewModel.userAvatarUrl!, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFF5B5FC7),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        SizedBox(height: responsive.getAdaptiveSpacing(16)),

        // Nom de l'utilisateur
        Text(
          viewModel.userName ?? 'Utilisateur',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(20),
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Widget - Item de menu
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
    required ResponsiveUtils responsive,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.getAdaptiveSpacing(16),
            vertical: responsive.getAdaptiveSpacing(16),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Row(
            children: [
              // Icône avec background coloré
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),

              SizedBox(width: responsive.getAdaptiveSpacing(16)),

              // Label
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(16),
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1F2937),
                  ),
                ),
              ),

              // Flèche
              Icon(
                Icons.chevron_right,
                color: const Color(0xFF9CA3AF),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigation vers les infos du compte
  void _navigateToAccountInfo(BuildContext context) {
    // TODO: Navigation
    // NavigationHelper.navigateTo(context, AppRoutes.accountInfo);
  }

  /// Navigation vers les paramètres
  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  /// Confirmation de déconnexion
  void _confirmLogout(BuildContext context, ProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Fermer la boîte de dialogue

              // Effectuer la déconnexion
              await viewModel.logout();

              // Naviguer vers l'écran de login et supprimer toute la pile de navigation
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false, // Supprime toutes les routes précédentes
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter pour les motifs SVG du background
class ProfileBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Dessiner plusieurs lignes courbes aléatoires
    final random = math.Random(
      42,
    ); // Seed fixe pour avoir toujours le même motif

    for (int i = 0; i < 8; i++) {
      final path = Path();
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;

      path.moveTo(startX, startY);

      // Créer une courbe de Bézier
      final controlX1 = random.nextDouble() * size.width;
      final controlY1 = random.nextDouble() * size.height;
      final controlX2 = random.nextDouble() * size.width;
      final controlY2 = random.nextDouble() * size.height;
      final endX = random.nextDouble() * size.width;
      final endY = random.nextDouble() * size.height;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, endX, endY);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// SettingsScreen
/// Écran des paramètres détaillés
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
          'Paramètres',
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
              // En-tête utilisateur
              _buildUserHeader(viewModel, responsive),

              SizedBox(height: responsive.getAdaptiveSpacing(24)),

              // Options de paramètres
              _buildSettingsMenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                iconColor: const Color(0xFF5B5FC7),
                iconBgColor: const Color(0xFFE8E9F8),
                onTap: () {},
                responsive: responsive,
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              _buildSettingsMenuItem(
                icon: Icons.help_outline,
                label: 'Aide',
                iconColor: const Color(0xFF5B5FC7),
                iconBgColor: const Color(0xFFE8E9F8),
                onTap: () {},
                responsive: responsive,
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              _buildSettingsMenuItem(
                icon: Icons.lock_outline,
                label: 'Confidentialité',
                iconColor: const Color(0xFF5B5FC7),
                iconBgColor: const Color(0xFFE8E9F8),
                onTap: () {},
                responsive: responsive,
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              _buildSettingsMenuItem(
                icon: Icons.info_outline,
                label: 'À propos',
                iconColor: const Color(0xFF5B5FC7),
                iconBgColor: const Color(0xFFE8E9F8),
                onTap: () {},
                responsive: responsive,
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              _buildSettingsMenuItem(
                icon: Icons.logout,
                label: 'Déconnexion',
                iconColor: const Color(0xFFEF4444),
                iconBgColor: const Color(0xFFFFE5E5),
                onTap: () => _confirmLogout(context, viewModel),
                responsive: responsive,
                isDestructive: true,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Widget - En-tête avec avatar et email
  Widget _buildUserHeader(
    ProfileViewModel viewModel,
    ResponsiveUtils responsive,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF5B5FC7),
            ),
            child: ClipOval(
              child: viewModel.userAvatarUrl != null
                  ? Image.network(viewModel.userAvatarUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.person, size: 25, color: Colors.white),
            ),
          ),

          SizedBox(width: responsive.getAdaptiveSpacing(16)),

          // Nom et email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.userName ?? 'Utilisateur',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(16),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(4)),
                Text(
                  viewModel.userEmail ?? 'email@example.com',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(14),
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget - Item de menu des paramètres
  Widget _buildSettingsMenuItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
    required ResponsiveUtils responsive,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.getAdaptiveSpacing(16),
            vertical: responsive.getAdaptiveSpacing(16),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Icône
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),

              SizedBox(width: responsive.getAdaptiveSpacing(16)),

              // Label
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(16),
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1F2937),
                  ),
                ),
              ),

              // Flèche
              Icon(
                Icons.chevron_right,
                color: const Color(0xFF9CA3AF),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Confirmation de déconnexion
  void _confirmLogout(BuildContext context, ProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Fermer la boîte de dialogue

              // Effectuer la déconnexion
              await viewModel.logout();

              // Naviguer vers l'écran de login et supprimer toute la pile de navigation
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false, // Supprime toutes les routes précédentes
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
