import 'package:flutter/material.dart';
import '../../../common/utils/responsive_utils.dart';

/// NotificationsScreen
/// Écran d'affichage des notifications avec onglets Non lu / Lus
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    // Données de notifications mockées
    final allNotifications = [
      {
        'title': 'Nouvelle facture créée',
        'message': 'Votre facture #INV-001 a été créée avec succès',
        'time': 'Il y a 2 heures',
        'read': false,
        'icon': Icons.receipt_long,
        'color': const Color(0xFF5B5FC7),
      },
      {
        'title': 'Paiement reçu',
        'message': 'Client ABC a payé la facture #INV-892',
        'time': 'Il y a 5 heures',
        'read': false,
        'icon': Icons.check_circle,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Facture en attente',
        'message': 'La facture #INV-923 attend validation',
        'time': 'Il y a 8 heures',
        'read': false,
        'icon': Icons.pending_outlined,
        'color': const Color(0xFFFF9F66),
      },
      {
        'title': 'Rappel de paiement',
        'message': 'La facture #INV-850 arrive à échéance dans 3 jours',
        'time': 'Il y a 1 jour',
        'read': true,
        'icon': Icons.access_time,
        'color': const Color(0xFFFF9F66),
      },
      {
        'title': 'Nouvel abonnement',
        'message': 'Profitez de factures illimitées avec notre abonnement',
        'time': 'Il y a 2 jours',
        'read': true,
        'icon': Icons.workspace_premium,
        'color': const Color(0xFFFF9F66),
      },
      {
        'title': 'Compte mis à jour',
        'message': 'Vos informations de compte ont été modifiées',
        'time': 'Il y a 3 jours',
        'read': true,
        'icon': Icons.person_outline,
        'color': const Color(0xFF5B5FC7),
      },
    ];

    final unreadNotifications = allNotifications.where((n) => n['read'] == false).toList();
    final readNotifications = allNotifications.where((n) => n['read'] == true).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
        actions: [
          if (_tabController.index == 0 && unreadNotifications.isNotEmpty)
            TextButton(
              onPressed: () {
                // TODO: Marquer toutes les notifications comme lues
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Toutes les notifications ont été marquées comme lues'),
                    backgroundColor: Color(0xFF10B981),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Tout lire',
                style: TextStyle(
                  color: const Color(0xFF5B5FC7),
                  fontSize: responsive.getAdaptiveTextSize(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF5B5FC7),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(15),
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(15),
                fontWeight: FontWeight.w500,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              onTap: (index) {
                setState(() {});
              },
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Non lu'),
                      if (unreadNotifications.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tabController.index == 0
                                ? Colors.white.withOpacity(0.3)
                                : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${unreadNotifications.length}',
                            style: TextStyle(
                              fontSize: responsive.getAdaptiveTextSize(12),
                              fontWeight: FontWeight.bold,
                              color: _tabController.index == 0
                                  ? Colors.white
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Text('Lus (${readNotifications.length})'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Non lu
          unreadNotifications.isEmpty
              ? _buildEmptyState(responsive, 'Aucune notification non lue')
              : _buildNotificationsList(unreadNotifications, responsive),
          
          // Onglet Lus
          readNotifications.isEmpty
              ? _buildEmptyState(responsive, 'Aucune notification lue')
              : _buildNotificationsList(readNotifications, responsive),
        ],
      ),
    );
  }

  /// Widget - Liste des notifications
  Widget _buildNotificationsList(List<Map<String, dynamic>> notifications, ResponsiveUtils responsive) {
    return ListView.separated(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification, responsive);
      },
    );
  }

  /// Widget - Carte de notification
  Widget _buildNotificationCard(Map<String, dynamic> notification, ResponsiveUtils responsive) {
    final bool isUnread = !(notification['read'] as bool);

    return Container(
      color: isUnread ? const Color(0xFFF3F4F6).withOpacity(0.5) : Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: responsive.getAdaptiveSpacing(16),
        horizontal: responsive.getAdaptiveSpacing(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (notification['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              notification['icon'] as IconData,
              color: notification['color'] as Color,
              size: 24,
            ),
          ),

          SizedBox(width: responsive.getAdaptiveSpacing(12)),

          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'] as String,
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(15),
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(4)),
                Text(
                  notification['message'] as String,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(14),
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(6)),
                Text(
                  notification['time'] as String,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(12),
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

  /// Widget - État vide (aucune notification)
  Widget _buildEmptyState(ResponsiveUtils responsive, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: const Color(0xFFE5E7EB),
          ),
          SizedBox(height: responsive.getAdaptiveSpacing(16)),
          Text(
            message,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(18),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: responsive.getAdaptiveSpacing(8)),
          Text(
            'Restez à jour avec vos factures',
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(14),
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
