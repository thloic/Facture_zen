// lib/features/chat/services/gemini_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';

class GeminiService {
  static GeminiService? _instance;
  late GenerativeModel _model;
  ChatSession? _currentSession;

  // Singleton
  factory GeminiService() {
    _instance ??= GeminiService._internal();
    return _instance!;
  }

  GeminiService._internal() {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  print('🔑 Clé API chargée: ${apiKey != null ? "OUI (${apiKey.substring(0, 10)}...)" : "NON"}');
  
  if (apiKey == null || apiKey.isEmpty) {
    if (kDebugMode) {
      print('⚠️ GEMINI_API_KEY non configurée dans .env');
    }
  } else {
    _initializeModels(apiKey);
  }
}

  void _initializeModels(String apiKey) {
  // ✅ Utiliser gemini-2.0-flash (disponible et rapide)
  _model = GenerativeModel(
    model: 'gemini-2.0-flash',  // ← Changement ici
    apiKey: apiKey,
    generationConfig: GenerationConfig(
      temperature: 0.7,
      topK: 1,
      topP: 0.8,
      maxOutputTokens: 500,
    ),
  );
}


  /// Prompt système personnalisé pour VoxIn
  String _getSystemPrompt() {
    return '''
Tu es l'assistant virtuel de VoxIn, une application mobile qui permet de générer des devis professionnels avec la reconnaissance vocale.

RÈGLES IMPORTANTES :
1. Réponds de manière **courte et concise** (max 3-4 phrases)
2. Utilise un ton **professionnel mais amical**
3. Si tu ne connais pas la réponse, suggère de contacter support@voxin-app.com
4. Pour les problèmes techniques, demande à l'utilisateur de vérifier :
   - Autorisations de l'application
   - Connexion internet
   - Version de l'application
5. Si l'utilisateur demande des fonctionnalités premium, mentionne qu'il peut s'abonner dans l'application

FONCTIONNALITÉS DE VOXIN :
- Génération de devis par voix
- Historique des devis
- Signature électronique
- Export PDF
- Modèles personnalisables
- Synchronisation multi-appareils
- Abonnement Premium (devis illimités, templates pro)

COMMENT RÉPONDRE :
- Questions sur les devis vocaux → Expliquer la procédure étape par étape
- Questions sur l'abonnement → Diriger vers l'écran d'abonnement
- Questions sur les bugs → Proposer de redémarrer l'app et contacter le support
- Questions générales → Répondre brièvement

Rappel : Reste utile et concis ! L'utilisateur cherche une réponse rapide.
''';
  }

  /// Envoie un message et reçoit une réponse
  // lib/features/chat/services/gemini_service.dart

Future<String> sendMessage(String message) async {
  int retries = 0;
  const maxRetries = 3;
  
  while (retries < maxRetries) {
    try {
      _currentSession ??= _model.startChat();
      final userContent = Content.text(message);
      final response = await _currentSession!.sendMessage(userContent);
      
      if (response.text == null || response.text!.isEmpty) {
        return _getFallbackResponse();
      }
      return response.text!;
      
    } catch (e) {
      final errorMsg = e.toString();
      
      // Si c'est une erreur de quota, attendre et réessayer
      if (errorMsg.contains('quota') || errorMsg.contains('rate limit')) {
        retries++;
        if (retries < maxRetries) {
          print('⏳ Quota atteint, attente ${retries * 2}s avant réessai...');
          await Future.delayed(Duration(seconds: retries * 2));
          continue; // Réessayer
        }
      }
      
      // Si erreur autre ou plus de tentatives
      print('❌ Erreur Gemini: $e');
      return _getFallbackResponse();
    }
  }
  
  return _getFallbackResponse();
}

  /// Envoie un message avec streaming (effet "en train d'écrire")
  Stream<String> sendMessageStream(String message) async* {
    try {
      // ✅ Utiliser le même modèle pour le streaming
      final chat = _model.startChat();
      
      // Envoyer le message utilisateur avec streaming
      final userContent = Content.text(message);
      final stream = chat.sendMessageStream(userContent);

      String fullResponse = '';
      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          fullResponse += text;
          yield fullResponse; // Émet le texte progressivement
        }
      }

      if (fullResponse.isEmpty) {
        yield _getFallbackResponse();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur streaming Gemini: $e');
      }
      yield _getFallbackResponse();
    }
  }

  /// Réponse de fallback quand Gemini ne répond pas
  String _getFallbackResponse() {
    return "Je rencontre une difficulté technique. 🤔\n\n"
        "En attendant, vous pouvez :\n"
        "• Consulter notre FAQ dans l'app\n"
        "• Contacter notre support : support@voxin-app.com\n\n"
        "Nous revenons vers vous rapidement !";
  }

  /// Réinitialiser la conversation
  void resetConversation() {
    _currentSession = null;
  }

  /// Vérifie si l'API est disponible
  Future<bool> isAvailable() async {
  try {
    final testModel = GenerativeModel(
      model: 'gemini-2.0-flash',  // ← Changement ici aussi
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    );
    await testModel.generateContent([Content.text('test')]);
    return true;
  } catch (e) {
    return false;
  }
}
}