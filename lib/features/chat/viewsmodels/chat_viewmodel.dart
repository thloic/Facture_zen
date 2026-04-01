// lib/features/chat/viewmodels/chat_viewmodel.dart
import 'package:facture_zen/features/chat/service/chat_fallback_service.dart';
import 'package:facture_zen/features/chat/service/groq_service.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'dart:math';

class ChatViewModel extends ChangeNotifier {
  final GroqService _groqService = GroqService();
  final ChatFallbackService _fallbackService = ChatFallbackService();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;

  ChatViewModel() {
    _loadWelcomeMessage();
  }

  void _loadWelcomeMessage() {
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '👋 Bonjour ! Je suis l\'assistant VoxIn.\n\n'
          'Je peux vous aider à :\n'
          '• Créer des devis avec la voix \n'
          '• Répondre à vos questions \n\n'
          'Comment puis-je vous aider ?',
      type: MessageType.bot,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Ajouter message utilisateur
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    // Message temporaire de chargement
    final loadingMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '',
      type: MessageType.loading,
      timestamp: DateTime.now(),
    );
    _messages.add(loadingMessage);
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      // Vérifier d'abord dans le fallback (questions fréquentes)
      final fallbackAnswer = _fallbackService.getAnswer(text);
      String response;
      
      if (fallbackAnswer != null) {
        response = fallbackAnswer;
      } else {
        // Sinon utiliser Groq
        response = await _groqService.sendMessage(text);
      }

      // Remplacer le message de chargement par la réponse
      final index = _messages.indexOf(loadingMessage);
      if (index != -1) {
        _messages[index] = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response,
          type: MessageType.bot,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      // En cas d'erreur
      final index = _messages.indexOf(loadingMessage);
      if (index != -1) {
        _messages[index] = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '❌ Désolé, je rencontre un problème technique.\n\n'
              'Contactez support@voxin-app.com pour une assistance.',
          type: MessageType.error,
          timestamp: DateTime.now(),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessageWithStream(String text) async {
    if (text.trim().isEmpty) return;

    // Ajouter message utilisateur
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    _isTyping = true;
    notifyListeners();

    // Créer message bot vide avec streaming
    final botMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '',
      type: MessageType.bot,
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    _messages.add(botMessage);
    notifyListeners();

    String fullResponse = '';
    await for (final chunk in _groqService.sendMessageStream(text)) {
      fullResponse = chunk;
      final index = _messages.indexOf(botMessage);
      if (index != -1) {
        _messages[index] = botMessage.copyWith(
          content: fullResponse,
          isStreaming: true,
        );
        notifyListeners();
      }
    }

    // Finaliser le message
    final index = _messages.indexOf(botMessage);
    if (index != -1) {
      _messages[index] = botMessage.copyWith(
        content: fullResponse.isEmpty ? _getDefaultResponse() : fullResponse,
        isStreaming: false,
      );
    }

    _isTyping = false;
    notifyListeners();
  }

  String _getDefaultResponse() {
    return "Je ne peux pas répondre pour le moment. 🤔\n\n"
        "Contactez notre support : support@voxin-app.com";
  }

  void clearMessages() {
    _messages.clear();
    _loadWelcomeMessage();
    _groqService.resetConversation();
    notifyListeners();
  }
}