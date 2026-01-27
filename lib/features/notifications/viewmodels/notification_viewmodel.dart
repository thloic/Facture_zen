import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../../../common/services/firebase_notification_service.dart';

/// ViewModel pour la gestion des notifications
class NotificationViewModel extends ChangeNotifier {
  final FirebaseNotificationService _notificationService;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  NotificationViewModel({FirebaseNotificationService? notificationService})
      : _notificationService = notificationService ?? FirebaseNotificationService();

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Notifications non lues
  List<NotificationModel> get unreadNotifications {
    return _notifications.where((n) => !n.read).toList();
  }

  /// Notifications lues
  List<NotificationModel> get readNotifications {
    return _notifications.where((n) => n.read).toList();
  }

  /// Nombre de notifications non lues
  int get unreadCount => unreadNotifications.length;

  /// Charger toutes les notifications
  Future<void> loadNotifications() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _notifications = await _notificationService.getUserNotifications();
      debugPrint('📬 ${_notifications.length} notifications chargées');
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des notifications';
      debugPrint('❌ Erreur loadNotifications: $e');
      _setLoading(false);
    }
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Mettre à jour localement
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur markAsRead: $e');
      rethrow;
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      // Mettre à jour localement
      _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur markAllAsRead: $e');
      rethrow;
    }
  }

  /// Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Retirer localement
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur deleteNotification: $e');
      rethrow;
    }
  }

  /// Supprimer toutes les notifications lues
  Future<void> deleteAllRead() async {
    try {
      await _notificationService.deleteAllRead();
      
      // Retirer localement
      _notifications.removeWhere((n) => n.read);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur deleteAllRead: $e');
      rethrow;
    }
  }

  /// Écouter les notifications en temps réel
  void startListening() {
    _notificationService.watchUserNotifications().listen(
      (notifications) {
        _notifications = notifications;
        notifyListeners();
        debugPrint('🔄 Notifications mises à jour: ${notifications.length}');
      },
      onError: (error) {
        _errorMessage = 'Erreur lors de l\'écoute des notifications';
        debugPrint('❌ Erreur stream notifications: $error');
      },
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
