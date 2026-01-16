<<<<<<< HEAD
// ========================================
// Fichier: lib/common/services/voice_recognition_service.dart
// ========================================
=======
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
>>>>>>> 971f1f1 (feat: Ajout clé API Groq depuis variables d'environnement (sécurisé))

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// VoiceRecognitionService
/// Service d'enregistrement audio
/// Gère l'enregistrement, la pause et la sauvegarde de fichiers audio
class VoiceRecognitionService {
  // Instance du recorder
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Chemin du fichier d'enregistrement
  String? _recordingPath;

  // État de l'enregistrement
  bool _isRecording = false;
  bool _isPaused = false;

  /// Getters
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get recordingPath => _recordingPath;

  /// Vérifie et demande les permissions du microphone
  Future<bool> checkAndRequestPermission() async {
    try {
      debugPrint('🎙️ Vérification des permissions microphone...');

<<<<<<< HEAD
      final status = await Permission.microphone.request();
=======
  // Configuration Groq API (GRATUIT)
  static String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _whisperEndpoint = 'https://api.groq.com/openai/v1/audio/transcriptions';
>>>>>>> 971f1f1 (feat: Ajout clé API Groq depuis variables d'environnement (sécurisé))

      if (status.isGranted) {
        debugPrint('✅ Permission microphone accordée');
        return true;
      } else if (status.isDenied) {
        debugPrint('❌ Permission microphone refusée');
        return false;
      } else if (status.isPermanentlyDenied) {
        debugPrint('⚠️ Permission microphone définitivement refusée');
        // Ouvrir les paramètres
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Erreur vérification permissions: $e');
      return false;
    }
  }

  /// Démarre l'enregistrement audio
  Future<bool> startRecording() async {
    try {
      // Vérifier les permissions
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        throw Exception('Permission microphone refusée');
      }

      // Vérifier si le recorder est disponible
      if (await _audioRecorder.hasPermission() == false) {
        throw Exception('Pas de permission pour le microphone');
      }

      // Générer le chemin du fichier
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${directory.path}/facture_audio_$timestamp.m4a';

      debugPrint('🎙️ Démarrage de l\'enregistrement...');
      debugPrint('📁 Chemin: $_recordingPath');

      // Configuration de l'enregistrement
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // AAC format (compatible iOS & Android)
        bitRate: 128000,             // Qualité audio
        sampleRate: 44100,           // Fréquence d'échantillonnage
      );

      // Démarrer l'enregistrement
      await _audioRecorder.start(config, path: _recordingPath!);

      _isRecording = true;
      _isPaused = false;

      debugPrint('✅ Enregistrement démarré avec succès');
      return true;

    } catch (e) {
      debugPrint('❌ Erreur démarrage enregistrement: $e');
      _isRecording = false;
      _isPaused = false;
      rethrow;
    }
  }

  /// Met en pause l'enregistrement
  Future<void> pauseRecording() async {
    try {
      if (!_isRecording) return;

      debugPrint('⏸️ Pause de l\'enregistrement...');

      await _audioRecorder.pause();

      _isPaused = true;

      debugPrint('✅ Enregistrement mis en pause');
    } catch (e) {
      debugPrint('❌ Erreur pause enregistrement: $e');
      rethrow;
    }
  }

  /// Reprend l'enregistrement après une pause
  Future<void> resumeRecording() async {
    try {
      if (!_isPaused) return;

      debugPrint('▶️ Reprise de l\'enregistrement...');

      await _audioRecorder.resume();

      _isPaused = false;

      debugPrint('✅ Enregistrement repris');
    } catch (e) {
      debugPrint('❌ Erreur reprise enregistrement: $e');
      rethrow;
    }
  }

  /// Arrête l'enregistrement et retourne le chemin du fichier
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      debugPrint('⏹️ Arrêt de l\'enregistrement...');

      final path = await _audioRecorder.stop();

      _isRecording = false;
      _isPaused = false;

      if (path != null) {
        _recordingPath = path;

        // Vérifier que le fichier existe
        final file = File(path);
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint('✅ Enregistrement arrêté');
          debugPrint('📁 Fichier sauvegardé: $path');
          debugPrint('📊 Taille: ${(fileSize / 1024).toStringAsFixed(2)} KB');
        } else {
          debugPrint('⚠️ Le fichier n\'existe pas: $path');
        }
      }

      return path;
    } catch (e) {
      debugPrint('❌ Erreur arrêt enregistrement: $e');
      _isRecording = false;
      _isPaused = false;
      rethrow;
    }
  }

  /// Supprime le fichier d'enregistrement actuel
  Future<void> deleteRecording() async {
    try {
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('🗑️ Fichier supprimé: $_recordingPath');
        }
        _recordingPath = null;
      }
    } catch (e) {
      debugPrint('❌ Erreur suppression fichier: $e');
    }
  }

  /// Récupère l'amplitude audio en temps réel (pour animations)
  Stream<double> getAmplitudeStream() async* {
    while (_isRecording && !_isPaused) {
      try {
        final amplitude = await _audioRecorder.getAmplitude();
        // Normaliser entre 0.0 et 1.0
        final normalizedAmplitude = (amplitude.current + 50) / 50;
        yield normalizedAmplitude.clamp(0.0, 1.0);
      } catch (e) {
        yield 0.0;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Vérifie si on a la permission du microphone
  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  /// Libère les ressources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }
      await _audioRecorder.dispose();
      debugPrint('🧹 VoiceRecognitionService dispose');
    } catch (e) {
      debugPrint('❌ Erreur dispose: $e');
    }
  }
}