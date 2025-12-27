import 'package:flutter/foundation.dart';
import 'dart:async';

/// VoiceRecordingViewModel
/// Gère l'état et la logique de l'enregistrement vocal
/// Respecte l'architecture MVVM - cette classe est le ViewModel
class VoiceRecordingViewModel extends ChangeNotifier {
  // Services injectés
  // final VoiceRecognitionService _voiceService;
  // final InvoiceGenerationService _invoiceService;

  // État de l'enregistrement
  bool _isRecording = false;
  bool _isGenerating = false;
  int _durationInSeconds = 0;
  String? _transcribedText;
  Timer? _timer;

  // Getters pour exposer l'état à la View
  bool get isRecording => _isRecording;
  bool get isGenerating => _isGenerating;
  int get durationInSeconds => _durationInSeconds;
  String? get transcribedText => _transcribedText;

  /// Retourne true si on peut réinitialiser (durée > 0 et pas en enregistrement)
  bool get canReset => _durationInSeconds > 0 && !_isRecording;

  /// Retourne true si on peut valider (durée > 0 et pas en enregistrement)
  bool get canValidate => _durationInSeconds > 0 && !_isRecording;

  /// Formate la durée en MM:SS
  String get formattedDuration {
    final minutes = (_durationInSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_durationInSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // TODO: Injection des services
  // VoiceRecordingViewModel(this._voiceService, this._invoiceService);

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
      _isRecording = true;
      notifyListeners();

      // TODO: Démarrer l'enregistrement audio réel
      // await _voiceService.startRecording();

      // Démarrer le timer
      _startTimer();

    } catch (e) {
      _isRecording = false;
      notifyListeners();
      debugPrint('Erreur démarrage enregistrement: $e');
    }
  }

  /// Met en pause l'enregistrement
  Future<void> _pauseRecording() async {
    try {
      _isRecording = false;
      _stopTimer();
      notifyListeners();

      // TODO: Mettre en pause l'enregistrement audio réel
      // await _voiceService.pauseRecording();

    } catch (e) {
      debugPrint('Erreur pause enregistrement: $e');
    }
  }

  /// Réinitialise l'enregistrement
  Future<void> reset() async {
    if (!canReset) return;

    try {
      _stopTimer();
      _durationInSeconds = 0;
      _isRecording = false;
      _transcribedText = null;
      notifyListeners();

      // TODO: Supprimer l'enregistrement audio
      // await _voiceService.deleteRecording();

    } catch (e) {
      debugPrint('Erreur reset: $e');
    }
  }

  /// Valide et traite l'enregistrement
  /// Retourne le texte transcrit
  Future<String?> validate() async {
    if (!canValidate) return null;

    try {
      _stopTimer();
      _isRecording = false;
      _isGenerating = true;
      notifyListeners();

      // TODO: Arrêter l'enregistrement
      // await _voiceService.stopRecording();

      // TODO: Envoyer l'audio pour transcription
      // final audioPath = await _voiceService.getRecordingPath();
      // final transcription = await _invoiceService.transcribeAudio(audioPath);

      // Simulation du traitement (3 secondes)
      await Future.delayed(const Duration(seconds: 3));

      // Texte de test (Lorem ipsum long)
      _transcribedText = '''
exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
''';

      _isGenerating = false;
      notifyListeners();

      return _transcribedText;

    } catch (e) {
      _isGenerating = false;
      notifyListeners();
      debugPrint('Erreur validation: $e');
      return null;
    }
  }

  /// Annule la génération en cours
  void cancelGeneration() {
    _isGenerating = false;
    notifyListeners();

    // TODO: Annuler les requêtes en cours
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

  /// Nettoyage lors de la destruction du ViewModel
  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}