// lib/features/chat/services/groq_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static GroqService? _instance;
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  List<Map<String, String>> _messages = [];
  
  // Cache pour les questions/réponses
  final Map<String, String> _responseCache = {};
  final Map<String, DateTime> _cacheExpiry = {};
  static const Duration _cacheDuration = Duration(hours: 24);
  
  // Liste des questions fréquentes pour suggestions
  static const List<String> _suggestedQuestions = [
    "Comment créer une facture ?",
    "Comment contacter l'assistance ?",
    "Quels sont les tarifs ?",
    "Comment ajouter mon logo ?",
    "Où trouver l'historique ?",
    "Comment partager une facture ?",
    "La reconnaissance vocale ne fonctionne pas",
    "Comment modifier un devis ?",
  ];
  
  factory GroqService() {
    _instance ??= GroqService._internal();
    return _instance!;
  }

  GroqService._internal() {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) {
        print('⚠️ GROQ_API_KEY non configurée dans .env');
      }
    } else {
      _initialize();
    }
  }

  void _initialize() {
    _messages = [
      {
        'role': 'system',
        'content': _getSystemPrompt(),
      }
    ];
  }
  
  // Récupérer les suggestions
  List<String> getSuggestedQuestions({String? context}) {
    return _suggestedQuestions;
  }
  
  // Vérifier le cache avant d'appeler l'API
  String? _getCachedResponse(String message) {
    final key = message.toLowerCase().trim();
    final cached = _responseCache[key];
    final expiry = _cacheExpiry[key];
    
    if (cached != null && expiry != null && DateTime.now().isBefore(expiry)) {
      print('✅ [CACHE] Réponse trouvée pour: "$message"');
      return cached;
    }
    return null;
  }
  
  // Sauvegarder dans le cache
  void _saveToCache(String message, String response) {
    final key = message.toLowerCase().trim();
    _responseCache[key] = response;
    _cacheExpiry[key] = DateTime.now().add(_cacheDuration);
    print('💾 [CACHE] Sauvegardé: "$message"');
  }

  // Fallback local : Détection des mots-clés avant API
  String? _getLocalResponse(String message) {
    final lowerMsg = message.toLowerCase().trim();
    
    // Assistance / Contact
    if (lowerMsg.contains('contact') || 
        lowerMsg.contains('assistance') || 
        lowerMsg.contains('support') ||
        lowerMsg.contains('joindre')) {
      return "Pour contacter l'assistance humaine, envoyez un email à support@voxin-app.com. Nous vous répondrons dans les meilleurs délais.";
    }
    
    // Création facture/devis
    if ((lowerMsg.contains('facture') || lowerMsg.contains('devis')) && 
        (lowerMsg.contains('créer') || lowerMsg.contains('comment') || lowerMsg.contains('faire'))) {
      return "Pour générer une facture ou un devis, allez sur l'onglet Facturation (le deuxième onglet à droite de l'accueil). Vous verrez un bouton microphone en bas de l'écran. Cliquez dessus et dictez les informations de votre facture. L'application générera automatiquement un PDF que vous pourrez exporter ou partager.";
    }
    
    // Historique
    if (lowerMsg.contains('historique')) {
      return "Pour voir l'historique de vos factures et devis, allez sur l'onglet Historique (le troisième onglet, à droite de l'onglet Facturation). Vous y retrouverez tous vos documents générés.";
    }
    
    // Abonnement / Tarifs
    if (lowerMsg.contains('abonnement') || 
        lowerMsg.contains('tarif') || 
        lowerMsg.contains('prix') ||
        lowerMsg.contains('premium')) {
      return "Nos offres : Gratuit (3 factures/mois), ESSENTIEL à 19,99€/mois (200 factures), PRO à 49,99€/mois (500 factures), ILLIMITÉ à 79,99€/mois (factures illimitées). Vous pouvez souscrire dans l'onglet Abonnement.";
    }
    
    // Micro / reconnaissance vocale
    if (lowerMsg.contains('micro') || 
        lowerMsg.contains('reconnaissance') || 
        lowerMsg.contains('voix')) {
      return "La reconnaissance vocale est accessible via le bouton microphone dans l'onglet Facturation. Assurez-vous d'avoir donné les permissions à l'application pour utiliser le microphone dans les paramètres de votre téléphone.";
    }
    
    // Template / modèle PDF
    if (lowerMsg.contains('template') || 
        lowerMsg.contains('modèle') || 
        lowerMsg.contains('pdf')) {
      return "Vous pouvez choisir parmi plusieurs modèles de factures dans les paramètres. Allez dans l'onglet Profil, puis dans Préférences de facture pour sélectionner le template qui vous convient.";
    }
    
    // Logo / entreprise
    if (lowerMsg.contains('logo') || 
        lowerMsg.contains('entreprise') || 
        lowerMsg.contains('société')) {
      return "Pour ajouter votre logo et les informations de votre entreprise, allez dans l'onglet Profil et appuyez sur Informations entreprise.";
    }
    
    // Partage / WhatsApp / Gmail
    if (lowerMsg.contains('partage') || 
        lowerMsg.contains('whatsapp') || 
        lowerMsg.contains('gmail') ||
        lowerMsg.contains('envoyer')) {
      return "Une fois votre facture générée, vous pouvez la partager directement via WhatsApp, Gmail ou SMS depuis l'écran de confirmation ou depuis l'historique.";
    }
    
    return null; // Pas de correspondance locale
  }

  String _getSystemPrompt() {
    return '''
Tu es l'assistant automatique de VoxIn. Tu aides les utilisateurs à utiliser l'application.

REGLES STRICTES :
- Reponds en 3-4 phrases maximum
- Sois court et precis
- N'utilise pas d'emojis
- Si tu ne connais pas la reponse, dis : "Je ne peux pas repondre a cette question. Contactez notre support a support@voxin-app.com"

FONCTIONNALITES DE VOXIN :
- Navigation : l'application a 4 onglets en bas : Accueil, Facturation, Historique, Profil
- Facture/Devis vocal : accessible dans l'onglet Facturation, bouton microphone
- Historique : accessible dans l'onglet Historique, liste tous les documents
- Abonnements : Gratuit (3 factures), ESSENTIEL 19,99€ (200 factures), PRO 49,99€ (500 factures), ILLIMITE 79,99€ (illimitees)
- Personnalisation : logo et infos entreprise dans l'onglet Profil
- Partage : disponible depuis l'ecran de confirmation ou l'historique

EXEMPLES DE REPONSES :
- Comment creer une facture ? → "Pour generer une facture, allez sur l'onglet Facturation (deuxieme onglet en bas). Cliquez sur le bouton microphone et dictez les informations. La facture sera generee automatiquement."
- Tarifs ? → "Nos offres : Gratuit (3 factures), ESSENTIEL 19,99€ (200 factures), PRO 49,99€ (500 factures). Souscrivez dans l'onglet Abonnement."
- Probleme technique ? → "Contactez notre support a support@voxin-app.com pour obtenir de l'aide."
''';
  }

  // Version avec cache et fallback local
  Stream<String> sendMessageStream(String message) async* {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      yield "Cle API Groq non configuree. Contactez le support.";
      return;
    }
    
    // 1. Verifier le fallback local (reponses pre-definies)
    final localResponse = _getLocalResponse(message);
    if (localResponse != null) {
      yield localResponse;
      _saveToCache(message, localResponse);
      return;
    }
    
    // 2. Verifier le cache (meme question deja posee)
    final cachedResponse = _getCachedResponse(message);
    if (cachedResponse != null) {
      yield cachedResponse;
      return;
    }
    
    // 3. Appeler l'API Groq
    _messages.add({
      'role': 'user',
      'content': message,
    });
    
    try {
      final requestBody = {
        'model': 'llama-3.1-8b-instant',
        'messages': _messages,
        'temperature': 0.3,
        'max_tokens': 500,
        'stream': true,
      };
      
      final request = http.Request(
        'POST',
        Uri.parse(_baseUrl),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      });
      
      request.body = jsonEncode(requestBody);
      
      final response = await request.send();
      
      if (response.statusCode != 200) {
        final error = await response.stream.bytesToString();
        print('Erreur Groq: $error');
        yield _getFallbackResponse();
        return;
      }
      
      String fullResponse = '';
      
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              break;
            }
            
            try {
              final jsonData = jsonDecode(data);
              final content = jsonData['choices'][0]['delta']['content'];
              if (content != null && content.isNotEmpty) {
                fullResponse += content;
                yield fullResponse;
              }
            } catch (e) {
              // Ignorer les erreurs de parsing
            }
          }
        }
      }
      
      if (fullResponse.isNotEmpty) {
        _messages.add({
          'role': 'assistant',
          'content': fullResponse,
        });
        _saveToCache(message, fullResponse);
      } else {
        yield _getFallbackResponse();
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Erreur streaming Groq: $e');
      }
      yield _getFallbackResponse();
    }
  }
  
  Future<String> sendMessage(String message) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      return "Cle API Groq non configuree. Contactez le support.";
    }
    
    final localResponse = _getLocalResponse(message);
    if (localResponse != null) {
      return localResponse;
    }
    
    _messages.add({
      'role': 'user',
      'content': message,
    });
    
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': _messages,
          'temperature': 0.3,
          'max_tokens': 500,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        _messages.add({
          'role': 'assistant',
          'content': content,
        });
        
        return content;
      } else {
        print('Erreur Groq: ${response.statusCode}');
        return _getFallbackResponse();
      }
    } catch (e) {
      print('Erreur Groq: $e');
      return _getFallbackResponse();
    }
  }

  String _getFallbackResponse() {
    return "Je rencontre une difficulte technique. Contactez notre support : support@voxin-app.com";
  }

  void resetConversation() {
    _initialize();
  }
}