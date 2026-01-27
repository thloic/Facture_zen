import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/utils/responsive_utils.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../models/notification_model.dart';

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
    
    // Charger les notifications au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          Consumer<NotificationViewModel>(
            builder: (context, viewModel, _) {
              if (_tabController.index == 0 && viewModel.unreadCount > 0) {
                return TextButton(
                  onPressed: () async {
                    await viewModel.markAllAsRead();
                    if (mounted) {
                      _showSuccessToast('Toutes les notifications ont été marquées comme lues');
                    }
                  },
                  child: Text(
                    'Tout lire',
                    style: TextStyle(
                      color: const Color(0xFF5B5FC7),
                      fontSize: responsive.getAdaptiveTextSize(14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Consumer<NotificationViewModel>(
            builder: (context, viewModel, _) {
              return Container(
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
                          if (viewModel.unreadCount > 0) ...[
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
                                '${viewModel.unreadCount}',
                                style: TextStyle(
                                  fontSize: responsive.getAdaptiveTextSize(12),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Text('Lus (${viewModel.readNotifications.length})'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Onglet Non lu
              viewModel.unreadNotifications.isEmpty
                  ? _buildEmptyState(responsive, 'Aucune notification non lue')
                  : _buildNotificationsList(viewModel.unreadNotifications, responsive),
              
              // Onglet Lus
              viewModel.readNotifications.isEmpty
                  ? _buildEmptyState(responsive, 'Aucune notification lue')
                  : _buildNotificationsList(viewModel.readNotifications, responsive),
            ],
          );
        },
      ),
    );
  }

  /// Widget - Liste des notifications
  Widget _buildNotificationsList(List<NotificationModel> notifications, ResponsiveUtils responsive) {
    return ListView.separated(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(notification);
          },
          onDismissed: (direction) async {
            await context.read<NotificationViewModel>().deleteNotification(notification.id);
            if (mounted) {
              _showDeleteToast('Notification supprimée');
            }
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade400,
                  Colors.red.shade600,
                ],
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, color: Colors.white, size: 28),
                SizedBox(height: 4),
                Text(
                  'Supprimer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          child: _buildNotificationCard(notification, responsive),
        );
      },
    );
  }

  /// Widget - Carte de notification
  Widget _buildNotificationCard(NotificationModel notification, ResponsiveUtils responsive) {
    final bool isUnread = !notification.read;
    
    // Déterminer l'icône et la couleur selon le type
    IconData icon;
    Color color;
    
    switch (notification.type) {
      case NotificationType.invoiceCreated:
        icon = Icons.receipt_long;
        color = const Color(0xFF5B5FC7);
        break;
      case NotificationType.invoiceDeleted:
        icon = Icons.delete_outline;
        color = const Color(0xFFEF4444);
        break;
      case NotificationType.invoiceUpdated:
        icon = Icons.update;
        color = const Color(0xFFFF9F66);
        break;
      case NotificationType.paymentReceived:
        icon = Icons.check_circle;
        color = const Color(0xFF10B981);
        break;
    }

    return GestureDetector(
      onTap: () async {
        if (isUnread) {
          await context.read<NotificationViewModel>().markAsRead(notification.id);
        }
      },
      child: Container(
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
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
                          notification.title,
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
                    notification.message,
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
                    notification.relativeTime,
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

  /// Dialogue de confirmation de suppression (premium style)
  Future<bool> _showDeleteConfirmation(NotificationModel notification) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEF4444),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Supprimer cette notification ?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _DeleteDialogButton(
                      onPressed: () => Navigator.pop(context, false),
                      text: 'Annuler',
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DeleteDialogButton(
                      onPressed: () => Navigator.pop(context, true),
                      text: 'Supprimer',
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ?? false;
  }

  /// Toast de succès (style premium)
  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Toast de suppression (style premium rouge)
  void _showDeleteToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Bouton personnalisé pour le dialogue de suppression avec effet hover
class _DeleteDialogButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isPrimary;

  const _DeleteDialogButton({
    required this.onPressed,
    required this.text,
    required this.isPrimary,
  });

  @override
  State<_DeleteDialogButton> createState() => _DeleteDialogButtonState();
}

class _DeleteDialogButtonState extends State<_DeleteDialogButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isPrimary
                ? (_isHovered ? const Color(0xFFDC2626) : const Color(0xFFEF4444))
                : (_isHovered ? Colors.grey[100] : Colors.white),
            foregroundColor: widget.isPrimary ? Colors.white : Colors.grey[700],
            elevation: _isHovered ? 4 : 0,
            shadowColor: widget.isPrimary
                ? const Color(0xFFEF4444).withOpacity(0.4)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: widget.isPrimary
                  ? BorderSide.none
                  : BorderSide(
                      color: _isHovered
                          ? Colors.grey[300]!
                          : Colors.grey[200]!,
                      width: 2,
                    ),
            ),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: widget.isPrimary ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
