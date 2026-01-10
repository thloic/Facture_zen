import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/voice_recognition_service.dart';

/// VoiceRecordingViewModel
/// Gère l'état et la logique de l'enregistrement vocal avec transcription Whisper
/// Architecture MVVM
class VoiceRecordingViewModel extends ChangeNotifier {
  final VoiceRecognitionService _voiceService;

  // État de l'enregistrement
  bool _isRecording = false;
  bool _isGenerating = false;
  int _durationInSeconds = 0;
  String? _transcribedText;
  String? _audioPath;
  Timer? _timer;

  // Stream d'amplitude pour la visualisation audio
  Stream<double>? _amplitudeStream;
  StreamSubscription<double>? _amplitudeSubscription;

  // Getters
  bool get isRecording => _isRecording;
  bool get isGenerating => _isGenerating;
  int get durationInSeconds => _durationInSeconds;
  String? get transcribedText => _transcribedText;
  String? get audioPath => _audioPath;
  Stream<double>? get amplitudeStream => _amplitudeStream;

  bool get canReset => _durationInSeconds > 0 && !_isRecording;
  bool get canValidate => _durationInSeconds > 0 && !_isRecording;

  String get formattedDuration {
    final minutes = (_durationInSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_durationInSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Constructeur avec injection du service
  VoiceRecordingViewModel({VoiceRecognitionService? voiceService})
      : _voiceService = voiceService ?? VoiceRecognitionService() {
    // Initialiser le stream d'amplitude
    _amplitudeStream = _voiceService.amplitudeStream;
  }

  /// Démarre ou met en pause l'enregistrement
  Future<void> toggleRecording() async {
    if (_isRecording) {
      await _pauseRecording();
    } else {
      await _startRecording();
    }
  }

  /// Démarre l'enregistrement vocal
  Future<void> _startRecording() async {
    try {
      debugPrint('🎙️ Tentative de démarrage enregistrement...');

      final started = await _voiceService.startRecording();

      if (started) {
        _isRecording = true;
        _startTimer();
        notifyListeners();
        debugPrint('✅ Enregistrement démarré avec succès');
      } else {
        debugPrint('❌ Échec démarrage enregistrement');
      }

    } catch (e) {
      _isRecording = false;
      notifyListeners();
      debugPrint('❌ Erreur démarrage enregistrement: $e');
      rethrow;
    }
  }

  /// Met en pause l'enregistrement
  Future<void> _pauseRecording() async {
    try {
      debugPrint('⏸️ Mise en pause...');

      await _voiceService.pauseRecording();

      _isRecording = false;
      _stopTimer();
      notifyListeners();

      debugPrint('✅ Pause effectuée');
    } catch (e) {
      debugPrint('❌ Erreur pause enregistrement: $e');
    }
  }

  /// Réinitialise l'enregistrement
  Future<void> reset() async {
    if (!canReset) return;

    try {
      debugPrint('🔄 Réinitialisation...');

      _stopTimer();
      await _voiceService.deleteRecording();

      _durationInSeconds = 0;
      _isRecording = false;
      _transcribedText = null;
      _audioPath = null;

      notifyListeners();

      debugPrint('✅ Réinitialisation effectuée');
    } catch (e) {
      debugPrint('❌ Erreur reset: $e');
    }
  }

  /// Valide et transcrit l'enregistrement avec Whisper
  /// Retourne le texte transcrit
  Future<String?> validate() async {
    if (!canValidate) return null;

    try {
      debugPrint('✅ Validation de l\'enregistrement...');

      _stopTimer();
      _isRecording = false;
      _isGenerating = true;
      notifyListeners();

      // Arrêter l'enregistrement et récupérer le chemin du fichier
      _audioPath = await _voiceService.stopRecording();

      if (_audioPath != null) {
        debugPrint('📁 Fichier audio sauvegardé: $_audioPath');

        // 🎯 TRANSCRIPTION AVEC GROQ WHISPER (GRATUIT)
        _transcribedText = await _voiceService.transcribeAudio(_audioPath!);

        if (_transcribedText != null && _transcribedText!.isNotEmpty) {
          // ✅ CORRECTION : Limiter la longueur du substring
          final preview = _transcribedText!.length > 50
              ? _transcribedText!.substring(0, 50)
              : _transcribedText!;
          debugPrint('✅ Transcription réussie: $preview...');
        } else {
          debugPrint('⚠️ Transcription vide ou échouée');
          _transcribedText = 'Erreur: Impossible de transcrire l\'audio. Veuillez réessayer.';
        }

        // Supprimer le fichier audio après transcription (optionnel)
        // await _voiceService.deleteRecording();

      } else {
        debugPrint('⚠️ Aucun fichier audio sauvegardé');
        _transcribedText = 'Erreur: Aucun fichier audio enregistré.';
      }

      _isGenerating = false;
      notifyListeners();

      return _transcribedText;

    } catch (e, stackTrace) {
      _isGenerating = false;
      _transcribedText = 'Erreur technique: $e';
      notifyListeners();
      debugPrint('❌ Erreur validation: $e');
      debugPrint('📍 StackTrace: $stackTrace');
      return _transcribedText;
    }
  }

  /// Annule la génération en cours
  void cancelGeneration() {
    _isGenerating = false;
    notifyListeners();
  }

  /// Démarre le timer d'enregistrement
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _durationInSeconds++;
      notifyListeners();
    });
  }

  /// Arrête le timer
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    _amplitudeSubscription?.cancel();
    _voiceService.dispose();
    super.dispose();
  }
}