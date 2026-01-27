import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../../features/notifications/models/notification_model.dart';

/// Service de gestion des notifications dans Firebase Realtime Database
/// Structure: /notifications/{userId}/{notificationId}
class FirebaseNotificationService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Récupérer l'utilisateur actuel
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Créer une nouvelle notification
  Future<void> createNotification({
    required NotificationType type,
    required String title,
    required String message,
    String? invoiceId,
    String? invoiceNumber,
  }) async {
    try {
      if (_currentUserId == null) {
        debugPrint('⚠️ Impossible de créer une notification : utilisateur non connecté');
        return;
      }

      final notificationId = _database
          .child('notifications')
          .child(_currentUserId!)
          .push()
          .key;

      if (notificationId == null) {
        debugPrint('❌ Erreur : ID de notification null');
        return;
      }

      final notification = NotificationModel(
        id: notificationId,
        type: type,
        title: title,
        message: message,
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        read: false,
        createdAt: DateTime.now(),
      );

      await _database
          .child('notifications')
          .child(_currentUserId!)
          .child(notificationId)
          .set(notification.toMap());

      debugPrint('✅ Notification créée: $title');
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de la notification: $e');
      rethrow;
    }
  }

  /// Récupérer toutes les notifications de l'utilisateur
  Future<List<NotificationModel>> getUserNotifications() async {
    try {
      debugPrint('🔍 [NOTIF] Début getUserNotifications');
      
      if (_currentUserId == null) {
        debugPrint('⚠️ [NOTIF] Aucun utilisateur connecté');
        return [];
      }

      debugPrint('🔍 [NOTIF] UserId: $_currentUserId');

      // Modification: on récupère tout le nœud sans trier côté serveur pour éviter les crashs
      // liés aux types de données. Le tri est déjà effectué plus bas en Dart.
      final snapshot = await _database
          .child('notifications')
          .child(_currentUserId!)
          .get();

      debugPrint('🔍 [NOTIF] Snapshot exists: ${snapshot.exists}');

      if (!snapshot.exists) {
        debugPrint('📭 [NOTIF] Aucune notification trouvée');
        return [];
      }

      debugPrint('🔍 [NOTIF] Snapshot value type: ${snapshot.value.runtimeType}');
      debugPrint('🔍 [NOTIF] Snapshot value: ${snapshot.value}');

      final notifications = <NotificationModel>[];
      
      // Vérifier que la valeur est bien un Map
      if (snapshot.value is! Map) {
        debugPrint('⚠️ [NOTIF] Format de données invalide - Type: ${snapshot.value.runtimeType}');
        debugPrint('⚠️ [NOTIF] Valeur brute: ${snapshot.value}');
        return [];
      }
      
      debugPrint('🔍 [NOTIF] Conversion en Map...');
      final data = snapshot.value as Map<dynamic, dynamic>;
      debugPrint('🔍 [NOTIF] Nombre d\'entrées dans data: ${data.length}');

      data.forEach((key, value) {
        try {
          debugPrint('🔍 [NOTIF] Traitement notification key: $key');
          debugPrint('🔍 [NOTIF] Valeur type: ${value.runtimeType}');
          
          if (value is! Map) {
            debugPrint('⚠️ [NOTIF] Notification $key ignorée (type: ${value.runtimeType}, valeur: $value)');
            return;
          }
          
          debugPrint('🔍 [NOTIF] Parsing notification $key...');
          final notif = NotificationModel.fromMap(value, key as String);
          notifications.add(notif);
          debugPrint('✅ [NOTIF] Notification $key ajoutée: ${notif.title}');
        } catch (e, stack) {
          debugPrint('❌ [NOTIF] Erreur parsing notification $key: $e');
          debugPrint('❌ [NOTIF] Stack: $stack');
        }
      });

      // Trier par date (plus récentes en premier)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      debugPrint('✅ [NOTIF] ${notifications.length} notification(s) récupérée(s)');
      return notifications;
    } catch (e, stack) {
      debugPrint('❌ [NOTIF] Erreur globale getUserNotifications: $e');
      debugPrint('❌ [NOTIF] Stack trace: $stack');
      return [];
    }
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      if (_currentUserId == null) return;

      await _database
          .child('notifications')
          .child(_currentUserId!)
          .child(notificationId)
          .update({'read': true});

      debugPrint('✅ Notification $notificationId marquée comme lue');
    } catch (e) {
      debugPrint('❌ Erreur lors du marquage comme lu: $e');
      rethrow;
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      debugPrint('🔍 [NOTIF] Début markAllAsRead');
      
      if (_currentUserId == null) {
        debugPrint('⚠️ [NOTIF] markAllAsRead - Aucun utilisateur connecté');
        return;
      }

      final snapshot = await _database
          .child('notifications')
          .child(_currentUserId!)
          .get();

      debugPrint('🔍 [NOTIF] markAllAsRead - Snapshot exists: ${snapshot.exists}');
      
      if (!snapshot.exists) return;

      debugPrint('🔍 [NOTIF] markAllAsRead - Snapshot type: ${snapshot.value.runtimeType}');
      
      if (snapshot.value is! Map) {
        debugPrint('⚠️ [NOTIF] markAllAsRead - Format invalide');
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final updates = <String, dynamic>{};

      data.forEach((key, value) {
        try {
          if (value is Map && value['read'] == false) {
            updates['notifications/$_currentUserId/$key/read'] = true;
          }
        } catch (e) {
          debugPrint('❌ [NOTIF] Erreur traitement notification $key: $e');
        }
      });

      if (updates.isNotEmpty) {
        await _database.update(updates);
        debugPrint('✅ [NOTIF] ${updates.length} notifications marquées comme lues');
      }
    } catch (e, stack) {
      debugPrint('❌ [NOTIF] Erreur markAllAsRead: $e');
      debugPrint('❌ [NOTIF] Stack: $stack');
      rethrow;
    }
  }

  /// Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      if (_currentUserId == null) return;

      await _database
          .child('notifications')
          .child(_currentUserId!)
          .child(notificationId)
          .remove();

      debugPrint('✅ Notification $notificationId supprimée');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la notification: $e');
      rethrow;
    }
  }

  /// Supprimer toutes les notifications lues
  Future<void> deleteAllRead() async {
    try {
      debugPrint('🔍 [NOTIF] Début deleteAllRead');
      
      if (_currentUserId == null) {
        debugPrint('⚠️ [NOTIF] deleteAllRead - Aucun utilisateur connecté');
        return;
      }

      final snapshot = await _database
          .child('notifications')
          .child(_currentUserId!)
          .get();

      debugPrint('🔍 [NOTIF] deleteAllRead - Snapshot exists: ${snapshot.exists}');
      
      if (!snapshot.exists) return;

      debugPrint('🔍 [NOTIF] deleteAllRead - Snapshot type: ${snapshot.value.runtimeType}');
      
      if (snapshot.value is! Map) {
        debugPrint('⚠️ [NOTIF] deleteAllRead - Format invalide');
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final updates = <String, dynamic>{};

      data.forEach((key, value) {
        try {
          if (value is Map && value['read'] == true) {
            updates['notifications/$_currentUserId/$key'] = null;
          }
        } catch (e) {
          debugPrint('❌ [NOTIF] Erreur traitement notification $key pour suppression: $e');
        }
      });

      if (updates.isNotEmpty) {
        await _database.update(updates);
        debugPrint('✅ [NOTIF] ${updates.length} notifications lues supprimées');
      }
    } catch (e, stack) {
      debugPrint('❌ [NOTIF] Erreur deleteAllRead: $e');
      debugPrint('❌ [NOTIF] Stack: $stack');
      rethrow;
    }
  }

  /// Stream des notifications en temps réel
  Stream<List<NotificationModel>> watchUserNotifications() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _database
        .child('notifications')
        .child(_currentUserId!)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) {
        return <NotificationModel>[];
      }

      final notifications = <NotificationModel>[];
      
      // Vérifier que la valeur est bien un Map
      if (event.snapshot.value is! Map) {
        debugPrint('⚠️ Format de données invalide pour les notifications (Stream)');
        return <NotificationModel>[];
      }
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        try {
          if (value is! Map) {
            return;
          }
          notifications.add(NotificationModel.fromMap(value, key as String));
        } catch (e) {
          debugPrint('⚠️ Erreur parsing notification: $e');
        }
      });

      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    });
  }
}
