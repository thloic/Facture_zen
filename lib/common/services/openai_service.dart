// ========================================
// Fichier: lib/common/services/openai_service.dart
// ========================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// OpenAIService
/// Service d'intégration avec l'API OpenAI
/// Gère la transcription audio avec Whisper
class OpenAIService {
  // Clé API chargée depuis .env
  String? get _apiKey => dotenv.env['OPENAI_API_KEY'];

  // Base URL de l'API OpenAI
  static const String _baseUrl = 'https://api.openai.com/v1';

  /// Transcrit un fichier audio en texte avec Whisper
  /// @param audioPath Le chemin du fichier audio
  /// @return Le texte transcrit ou null en cas d'erreur
  Future<String?> transcribeAudio(String audioPath) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('❌ ERREUR: OPENAI_API_KEY manquante dans .env');
      return null;
    }

    try {
      debugPrint('🎙️ Transcription audio: $audioPath');

      final file = File(audioPath);
      if (!await file.exists()) {
        debugPrint('❌ Fichier audio inexistant: $audioPath');
        return null;
      }

      // Préparer la requête multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/audio/transcriptions'),
      );

      // Headers
      request.headers['Authorization'] = 'Bearer $_apiKey';

      // Ajouter le fichier audio
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioPath,
        ),
      );

      // Paramètres
      request.fields['model'] = 'whisper-1';
      request.fields['language'] = 'fr'; // Français
      request.fields['response_format'] = 'json';

      // Envoyer la requête
      debugPrint('📤 Envoi vers OpenAI Whisper...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final transcription = data['text'] as String?;
        debugPrint('✅ Transcription réussie: ${transcription?.substring(0, 50)}...');
        return transcription;
      } else {
        debugPrint('❌ Erreur API: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erreur transcription: $e');
      return null;
    }
  }

  /// Extrait les informations de facture depuis un texte transcrit
  /// @param text Le texte transcrit
  /// @return Map avec les informations extraites
  Future<Map<String, dynamic>?> extractInvoiceData(String text) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('❌ ERREUR: OPENAI_API_KEY manquante dans .env');
      return null;
    }

    try {
      debugPrint('🤖 Extraction des données de facture...');

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''Tu es un assistant qui extrait les informations de facture depuis un texte dicté. 
Réponds UNIQUEMENT avec un JSON valide contenant:
{
  "customerName": "nom du client",
  "customerAddress": "adresse du client",
  "items": [
    {
      "description": "description article",
      "quantity": quantité_numérique,
      "unitPrice": prix_unitaire_numérique,
      "total": total_numérique
    }
  ],
  "total": total_général_numérique,
  "date": "date au format YYYY-MM-DD",
  "notes": "notes éventuelles"
}
Si une information n'est pas fournie, utilise null ou une valeur par défaut raisonnable.'''
            },
            {
              'role': 'user',
              'content': 'Voici le texte dicté: $text'
            }
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Parser le JSON extrait
        final invoiceData = json.decode(content) as Map<String, dynamic>;
        debugPrint('✅ Données extraites: $invoiceData');
        return invoiceData;
        
      } else {
        debugPrint('❌ Erreur extraction: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erreur extraction données: $e');
      return null;
    }
  }

  /// Vérifie si la clé API est configurée
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;
}
