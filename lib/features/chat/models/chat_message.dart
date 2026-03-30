// lib/features/chat/models/chat_message.dart
import 'package:intl/intl.dart';  // ✅ AJOUTER CET IMPORT


enum MessageType {
  user,      // Message de l'utilisateur
  bot,       // Message du bot
  error,     // Message d'erreur
  loading,   // État de chargement
}

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isStreaming = false,
  });

  String get formattedTime => DateFormat('HH:mm').format(timestamp);

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'type': type.index,
    'timestamp': timestamp.toIso8601String(),
    'isStreaming': isStreaming,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    content: json['content'],
    type: MessageType.values[json['type']],
    timestamp: DateTime.parse(json['timestamp']),
    isStreaming: json['isStreaming'] ?? false,
  );
}