import 'package:flutter/material.dart';
import '../../../common/services/pin_service.dart';
import 'package:provider/provider.dart';
import '../../../common/widgets/curved_bottom_nav.dart';
import '../../invoicing/services/subscription_sync_service.dart';
import '../../invoicing/views/subscription_screen.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../../../common/utils/responsive_utils.dart';
import '../../auth/views/login_screen.dart';
import '../../settings/views/account_info_screen.dart';
import '../../settings/views/help_screen.dart';
import '../../chat/views/chat_screen.dart';
import '../../settings/views/privacy_screen.dart';
import '../../settings/views/about_screen.dart';
import '../../notifications/views/notifications_screen.dart';
import 'company_profile_setup_screen.dart';
import 'dart:math' as math;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        },
        backgroundColor: const Color(0xFF5B5FC7),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        tooltip: 'Assistant',
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Background avec dégradé
                _buildBackground(context),

                // Contenu principal avec carte de profil
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalPadding,
                  ),
                  child: Column(
                    children: [
                      // Avatar utilisateur (positionné négativement pour chevaucher le dégradé)
                      Transform.translate(
                        offset: Offset(0, -responsive.getAdaptiveHeight(50)),
                        child: _buildUserAvatar(viewModel, responsive),
                      ),

                      SizedBox(height: responsive.getAdaptiveSpacing(16)),

                      // Email utilisateur
                      Text(
                        viewModel.userEmail ?? 'email@example.com',
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(14),
                          color: const Color(0xFF6B7280),
                        ),
                      ),

                      SizedBox(height: responsive.getAdaptiveSpacing(24)),

                      // ✅ Carte plan d'abonnement
                      _buildSubscriptionPlanCard(context, viewModel, responsive),

                      SizedBox(height: responsive.getAdaptiveSpacing(24)),

                      // Menu principal
                      _buildMenuItem(
                        icon: Icons.business_outlined,
                        label: 'Profil entreprise',
                        iconColor: const Color(0xFF5B5FC7),
                        iconBgColor: const Color(0xFFE8E9F8),
                        onTap: () => _navigateToCompanyProfile(context),
                        responsive: responsive,
                      ),

                      SizedBox(height: responsive.getAdaptiveSpacing(12)),

                      _buildMenuItem(
                        icon: Icons.account_circle_outlined,
                        label: 'Informations du compte',
                        iconColor: const Color(0xFF5B5FC7),
                        iconBgColor: const Color(0xFFE8E9F8),
                        onTap: () => _navigateToAccountInfo(context),
                        responsive: responsive,
                      ),

                      SizedBox(height: responsive.getAdaptiveSpacing(12)),

                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        label: 'Paramètres',
                        iconColor: const Color(0xFF5B5FC7),
                        iconBgColor: const Color(0xFFE8E9F8),
                        onTap: () => _navigateToSettings(context),
                        responsive: responsive,
                      ),

                      SizedBox(height: responsive.getAdaptiveSpacing(12)),

                      _buildMenuItem(
                        icon: Icons.logout,
                        label: 'Déconnexion',
                        iconColor: const Color(0xFFEF4444),
                        iconBgColor: const Color(0xFFFFF5F5),
                        onTap: () => _confirmLogout(context, viewModel),
                        responsive: responsive,
                        isDestructive: true,
                      ),

                      SizedBox(height: responsive.getAdaptiveSpacing(32)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const CurvedBottomNav(
        currentIndex: 3, // Index 3 = Profil
      ),
    );
  }

  /// Widget - Background avec dégradé violet
  Widget _buildBackground(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
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
                color: Colors.black.withOpacity(0.15),
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

        SizedBox(height: responsive.getAdaptiveSpacing(14)),

        // Nom de l'utilisateur
        Text(
          viewModel.userName ?? 'Utilisateur',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(20),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// ✅ Carte moderne du plan d'abonnement
  Widget _buildSubscriptionPlanCard(
    BuildContext context,
    ProfileViewModel viewModel,
    ResponsiveUtils responsive,
  ) {
    final plan = viewModel.currentPlan;
    final isLoading = viewModel.isLoadingPlan;

    if (isLoading) {
      return Container(
        height: responsive.getAdaptiveHeight(140),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8E9F8), Color(0xFFF3F4F6)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF5B5FC7),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    // Configuration visuelle selon le plan
    final planConfig = _getPlanConfig(plan);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: planConfig.gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: planConfig.gradientColors.first.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Motifs décoratifs en arrière-plan
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          // Contenu principal
          Padding(
            padding: EdgeInsets.all(responsive.getAdaptiveSpacing(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icône du plan avec cercle
                    Container(
                      width: responsive.getAdaptiveSize(52),
                      height: responsive.getAdaptiveSize(52),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        planConfig.icon,
                        color: Colors.white,
                        size: responsive.getAdaptiveSize(26),
                      ),
                    ),

                    SizedBox(width: responsive.getAdaptiveSpacing(14)),

                    // Nom et badge du plan
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  plan?.name ?? 'Chargement...',
                                  style: TextStyle(
                                    fontSize: responsive.getAdaptiveTextSize(20),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (planConfig.isPremium) ...[
                                SizedBox(width: responsive.getAdaptiveSpacing(8)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: responsive.getAdaptiveSpacing(8),
                                    vertical: responsive.getAdaptiveSpacing(4),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: responsive.getAdaptiveSize(12),
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: responsive.getAdaptiveSpacing(3)),
                                      Text(
                                        'PRO',
                                        style: TextStyle(
                                          fontSize: responsive.getAdaptiveTextSize(9),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: responsive.getAdaptiveSpacing(4)),
                          Text(
                            planConfig.subtitle,
                            style: TextStyle(
                              fontSize: responsive.getAdaptiveTextSize(13),
                              color: Colors.white.withOpacity(0.9),
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: responsive.getAdaptiveSpacing(16)),

                // Statistiques du plan
                Row(
                  children: [
                    // Factures
                    Expanded(
                      child: _buildPlanStat(
                        icon: Icons.description_outlined,
                        value: plan?.monthlyInvoiceLimit == -1
                            ? '∞'
                            : '${plan?.monthlyInvoiceLimit ?? 0}',
                        label: 'Factures',
                        responsive: responsive,
                      ),
                    ),

                    SizedBox(width: responsive.getAdaptiveSpacing(12)),

                    // Templates
                    Expanded(
                      child: _buildPlanStat(
                        icon: Icons.palette_outlined,
                        value: plan?.allowedTemplatesCount == -1
                            ? '∞'
                            : '${plan?.allowedTemplatesCount ?? 0}',
                        label: 'Templates',
                        responsive: responsive,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: responsive.getAdaptiveSpacing(16)),

                // Bouton "Changer de plan"
                SizedBox(
                  width: double.infinity,
                  height: responsive.getAdaptiveHeight(46),
                  child: ElevatedButton(
                    onPressed: () => _navigateToSubscription(context, viewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: planConfig.gradientColors.first,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          planConfig.isPremium
                              ? Icons.upgrade_rounded
                              : Icons.rocket_launch_rounded,
                          size: responsive.getAdaptiveSize(20),
                        ),
                        SizedBox(width: responsive.getAdaptiveSpacing(8)),
                        Text(
                          planConfig.isPremium
                              ? 'Changer de plan'
                              : 'Passer à Premium',
                          style: TextStyle(
                            fontSize: responsive.getAdaptiveTextSize(15),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour afficher une statistique du plan
  Widget _buildPlanStat({
    required IconData icon,
    required String value,
    required String label,
    required ResponsiveUtils responsive,
  }) {
    return Container(
      padding: EdgeInsets.all(responsive.getAdaptiveSpacing(12)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: responsive.getAdaptiveSize(22),
          ),
          SizedBox(height: responsive.getAdaptiveSpacing(6)),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(18),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: responsive.getAdaptiveSpacing(2)),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(11),
              color: Colors.white.withOpacity(0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Configuration visuelle selon le plan
  _PlanConfig _getPlanConfig(SubscriptionPlan? plan) {
    if (plan == null) {
      return _PlanConfig(
        gradientColors: [const Color(0xFFE8E9F8), const Color(0xFFF3F4F6)],
        icon: Icons.hourglass_empty,
        subtitle: 'Chargement...',
        isPremium: false,
      );
    }

    final planId = plan.name.toLowerCase();

    if (planId.contains('pro') || planId.contains('enterprise')) {
      return _PlanConfig(
        gradientColors: [
          const Color(0xFF6366F1),
          const Color(0xFF8B5CF6),
        ],
        icon: Icons.workspace_premium_rounded,
        subtitle: '${plan.monthlyInvoiceLimit} factures/mois',
        isPremium: true,
      );
    } else if (planId.contains('basic')) {
      return _PlanConfig(
        gradientColors: [
          const Color(0xFF10B981),
          const Color(0xFF059669),
        ],
        icon: Icons.verified_rounded,
        subtitle: '${plan.monthlyInvoiceLimit} factures/mois',
        isPremium: true,
      );
    } else {
      // Plan gratuit
      return _PlanConfig(
        gradientColors: [
          const Color(0xFF94A3B8),
          const Color(0xFF64748B),
        ],
        icon: Icons.star_border_rounded,
        subtitle: '${plan.monthlyInvoiceLimit} factures/mois',
        isPremium: false,
      );
    }
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
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccountInfoScreen()),
    );
  }

  /// Navigation vers le profil entreprise
  void _navigateToCompanyProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompanyProfileSetupScreen(isOnboarding: false),
      ),
    );
  }

  /// Navigation vers les paramètres
  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  /// Navigation vers l'écran d'abonnement avec rafraîchissement au retour
  Future<void> _navigateToSubscription(
    BuildContext context,
    ProfileViewModel viewModel,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionScreen(remainingInvoices: 0),
      ),
    );

    // Si l'utilisateur a acheté un abonnement, rafraîchir le plan
    if (result == true) {
      debugPrint('✅ Retour de l\'écran d\'abonnement - rafraîchissement du plan');
      await viewModel.refreshSubscriptionPlan();
    }
  }

  /// Confirmation de déconnexion
  void _confirmLogout(BuildContext context, ProfileViewModel viewModel) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 80,
                    offset: const Offset(0, 20),
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône de déconnexion
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFEF4444).withOpacity(0.15),
                            const Color(0xFFFCA5A5).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        size: 36,
                        color: Color(0xFFEF4444),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Titre
                    const Text(
                      'Déconnexion',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Message
                    const Text(
                      'Êtes-vous sûr de vouloir vous déconnecter ?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Boutons
                    Column(
                      children: [
                        // Bouton Déconnexion
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              navigator.pop();
                              await viewModel.logout();
                              if (context.mounted) {
                                navigator.pushReplacementNamed('/login');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Déconnexion',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Bouton Annuler
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// SettingsScreen avec gestion du PIN (rendu facultatif)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PinService _pinService = PinService();
  bool _isPinEnabled = false;
  bool _isLoadingPin = true;

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
  }

  /// Charge l'état actuel du PIN depuis SharedPreferences
  Future<void> _loadPinStatus() async {
    final enabled = await _pinService.isPinEnabled();
    if (mounted) {
      setState(() {
        _isPinEnabled = enabled;
        _isLoadingPin = false;
      });
    }
  }

  /// Gère l'activation/désactivation du toggle PIN
  Future<void> _onPinToggleChanged(bool value) async {
    if (value) {
      // Activation : rediriger vers PinSetupScreen
      final result = await Navigator.pushNamed(context, '/pin-setup');
      // Recharger l'état après retour
      await _loadPinStatus();
    } else {
      // Désactivation : demander confirmation
      final confirmed = await _showDisablePinDialog();
      if (confirmed == true) {
        await _pinService.setPinEnabled(false);
        if (mounted) {
          setState(() => _isPinEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code PIN désactivé'),
              backgroundColor: Color(0xFF5B5FC7),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// Dialog de confirmation avant de désactiver le PIN
  Future<bool?> _showDisablePinDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Désactiver le code PIN ?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1F2937),
          ),
        ),
        content: const Text(
          'Votre code PIN sera supprimé. Vous pourrez en créer un nouveau à tout moment depuis les paramètres.',
          style: TextStyle(color: Color(0xFF6B7280), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

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

              // ✅ Toggle Code PIN
              _buildPinToggleItem(responsive),

              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              _buildSettingsMenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                iconColor: const Color(0xFF5B5FC7),
                iconBgColor: const Color(0xFFE8E9F8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NotificationsScreen()),
                  );
                },
                responsive: responsive,
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              _buildSettingsMenuItem(
                icon: Icons.help_outline,
                label: 'Aide',
                iconColor: const Color(0xFF5B5FC7),
                iconBgColor: const Color(0xFFE8E9F8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpScreen()),
                  );
                },
                responsive: responsive,
              ),

              // Ajout bouton Assistant (Chatbot)
              SizedBox(height: responsive.getAdaptiveSpacing(12)),
              _buildSettingsMenuItem(
                icon: Icons.chat_bubble_outline,
                label: 'Assistant',
                iconColor: const Color(0xFF5B5FC7),
                iconBgColor: const Color(0xFFE8E9F8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
                responsive: responsive,
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              _buildSettingsMenuItem(
                icon: Icons.lock_outline,
                label: 'Confidentialité',
                iconColor: const Color(0xFF5B5FC7),
                iconBgColor: const Color(0xFFE8E9F8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                  );
                },
                responsive: responsive,
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(12)),

              _buildSettingsMenuItem(
                icon: Icons.info_outline,
                label: 'À propos',
                iconColor: const Color(0xFF5B5FC7),
                iconBgColor: const Color(0xFFE8E9F8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                },
                responsive: responsive,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Widget Toggle Code PIN
  Widget _buildPinToggleItem(ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.getAdaptiveSpacing(16),
        vertical: responsive.getAdaptiveSpacing(14),
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
              color: const Color(0xFFE8E9F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.pin_outlined,
              color: Color(0xFF5B5FC7),
              size: 20,
            ),
          ),

          SizedBox(width: responsive.getAdaptiveSpacing(16)),

          // Label + sous-titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Code PIN',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(16),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(2)),
                Text(
                  _isPinEnabled
                      ? 'Activé — requis à la reconnexion'
                      : 'Désactivé',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(12),
                    color: _isPinEnabled
                        ? const Color(0xFF5B5FC7)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          // Toggle
          _isLoadingPin
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF5B5FC7),
                  ),
                )
              : Switch(
                  value: _isPinEnabled,
                  onChanged: _onPinToggleChanged,
                  activeColor: const Color(0xFF5B5FC7),
                ),
        ],
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF5B5FC7),
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
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Classe helper pour la configuration visuelle du plan
class _PlanConfig {
  final List<Color> gradientColors;
  final IconData icon;
  final String subtitle;
  final bool isPremium;

  _PlanConfig({
    required this.gradientColors,
    required this.icon,
    required this.subtitle,
    required this.isPremium,
  });
}

/// CustomPainter pour les motifs SVG du background
class ProfileBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final random = math.Random(42);

    for (int i = 0; i < 8; i++) {
      final path = Path();
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;

      path.moveTo(startX, startY);

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