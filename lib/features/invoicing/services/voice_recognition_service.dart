import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service de reconnaissance vocale avec intégration Groq Whisper
/// Gère l'enregistrement, la transcription et la visualisation audio
class VoiceRecognitionService {
  final AudioRecorder _recorder = AudioRecorder();

  // État de l'enregistrement
  bool _isRecording = false;
  String? _currentAudioPath;

  // Stream pour les amplitudes audio (pour la visualisation)
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  Timer? _amplitudeTimer;

  // Configuration Groq API (GRATUIT)
  static String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _whisperEndpoint = 'https://api.groq.com/openai/v1/audio/transcriptions';

  VoiceRecognitionService();

  /// Vérifie et demande les permissions microphone
  Future<bool> _checkPermissions() async {
    final status = await Permission.microphone.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    return status.isGranted;
  }

  /// Démarre l'enregistrement audio
  Future<bool> startRecording() async {
    try {
      // Vérifier les permissions
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        debugPrint('❌ Permission microphone refusée');
        return false;
      }

      // Générer un nom de fichier unique
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentAudioPath = '${directory.path}/recording_$timestamp.m4a';

      // Configuration de l'enregistrement
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      );

      // Démarrer l'enregistrement
      await _recorder.start(config, path: _currentAudioPath!);
      _isRecording = true;

      // Démarrer la surveillance de l'amplitude
      _startAmplitudeMonitoring();

      debugPrint('✅ Enregistrement démarré: $_currentAudioPath');
      return true;

    } catch (e) {
      debugPrint('❌ Erreur startRecording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Surveille l'amplitude audio pour la visualisation
  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();

    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      try {
        final amplitude = await _recorder.getAmplitude();
        final normalized = (amplitude.current + 160) / 160;
        final clamped = normalized.clamp(0.0, 1.0);
        _amplitudeController.add(clamped);
      } catch (e) {
        debugPrint('⚠️ Erreur amplitude: $e');
      }
    });
  }

  /// Met en pause l'enregistrement
  Future<void> pauseRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.pause();
      _isRecording = false;
      _amplitudeTimer?.cancel();
      _amplitudeController.add(0.0);

      debugPrint('⏸️ Enregistrement en pause');
    } catch (e) {
      debugPrint('❌ Erreur pauseRecording: $e');
    }
  }

  /// Reprend l'enregistrement
  Future<void> resumeRecording() async {
    if (_isRecording) return;

    try {
      await _recorder.resume();
      _isRecording = true;
      _startAmplitudeMonitoring();

      debugPrint('▶️ Enregistrement repris');
    } catch (e) {
      debugPrint('❌ Erreur resumeRecording: $e');
    }
  }

  /// Arrête l'enregistrement et retourne le chemin du fichier
  Future<String?> stopRecording() async {
    try {
      _amplitudeTimer?.cancel();
      _amplitudeController.add(0.0);

      final path = await _recorder.stop();
      _isRecording = false;

      debugPrint('⏹️ Enregistrement arrêté: $path');
      return path;

    } catch (e) {
      debugPrint('❌ Erreur stopRecording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Transcrit l'audio avec Groq Whisper API (GRATUIT)
  Future<String?> transcribeAudio(String audioPath) async {
    try {
      debugPrint('🎯 Début transcription avec Groq Whisper...');
      debugPrint('🔑 Clé API: ${_groqApiKey.isEmpty ? "VIDE ❌" : "OK ✅ (${_groqApiKey.substring(0, 10)}...)"}');

      final audioFile = File(audioPath);

      if (!await audioFile.exists()) {
        debugPrint('❌ Fichier audio introuvable: $audioPath');
        return null;
      }

      // Vérifier la taille du fichier
      final fileSize = await audioFile.length();
      debugPrint('📦 Taille fichier: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      if (fileSize > 25 * 1024 * 1024) {
        debugPrint('❌ Fichier trop volumineux (max 25 MB)');
        return null;
      }

      // Préparer la requête multipart
      final request = http.MultipartRequest('POST', Uri.parse(_whisperEndpoint));

      // Headers
      request.headers['Authorization'] = 'Bearer $_groqApiKey';

      // Fichier audio
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioPath,
          filename: 'audio.m4a',
        ),
      );

      // Paramètres
      request.fields['model'] = 'whisper-large-v3';
      request.fields['language'] = 'fr';
      request.fields['response_format'] = 'json';
      request.fields['temperature'] = '0.0';

      // Envoyer la requête
      debugPrint('📤 Envoi à Groq Whisper API...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Réponse API: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final transcription = jsonResponse['text'] as String?;

        if (transcription != null && transcription.isNotEmpty) {
          // ✅ CORRECTION : Afficher seulement les 50 premiers caractères SI le texte est assez long
          final preview = transcription.length > 50
              ? '${transcription.substring(0, 50)}...'
              : transcription;
          debugPrint('✅ Transcription réussie: $preview');
          return transcription;
        } else {
          debugPrint('⚠️ Transcription vide');
          return null;
        }

      } else {
        debugPrint('❌ Erreur API Whisper: ${response.statusCode}');
        debugPrint('📄 Response body: ${response.body}');

        // Analyser l'erreur pour donner un message utile
        try {
          final errorJson = json.decode(response.body);
          debugPrint('💬 Message d\'erreur: ${errorJson['error']}');
        } catch (_) {
          // Pas de JSON dans l'erreur
        }

        return null;
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur transcription: $e');
      debugPrint('📍 StackTrace: $stackTrace');
      return null;
    }
  }

  /// Supprime le fichier audio enregistré
  Future<void> deleteRecording() async {
    if (_currentAudioPath == null) return;

    try {
      final file = File(_currentAudioPath!);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Fichier audio supprimé');
      }
      _currentAudioPath = null;
    } catch (e) {
      debugPrint('❌ Erreur deleteRecording: $e');
    }
  }

  /// Nettoyage
  void dispose() {
    _amplitudeTimer?.cancel();
    _amplitudeController.close();
    _recorder.dispose();
  }
}