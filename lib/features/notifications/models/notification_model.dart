/// Type de notification
enum NotificationType {
  invoiceCreated('invoice_created'),
  invoiceDeleted('invoice_deleted'),
  invoiceUpdated('invoice_updated'),
  paymentReceived('payment_received');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.invoiceCreated,
    );
  }
}

/// Modèle de notification
class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? invoiceId;
  final String? invoiceNumber;
  final int timestamp;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.invoiceId,
    this.invoiceNumber,
    required this.timestamp,
    required this.read,
    required this.createdAt,
  });

  /// Créer depuis Map (Firebase)
  factory NotificationModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      type: NotificationType.fromString(map['type'] as String? ?? 'invoice_created'),
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      invoiceId: map['invoiceId'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
      timestamp: map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      read: map['read'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Convertir en Map (Firebase)
  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'title': title,
      'message': message,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'timestamp': timestamp,
      'read': read,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Temps relatif (Il y a X heures/jours)
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return 'Il y a ${(difference.inDays / 7).floor()} sem';
    }
  }

  /// Copier avec modifications
  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    String? invoiceId,
    String? invoiceNumber,
    int? timestamp,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
