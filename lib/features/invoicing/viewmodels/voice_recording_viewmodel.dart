import 'package:flutter/foundation.dart';
import 'dart:async';

class VoiceRecordingViewModel extends ChangeNotifier {
  // Services injectés
  // final VoiceRecognitionService _voiceService;
  // final InvoiceGenerationService _invoiceService;

  // État de l'enregistrement
  bool _isRecording = false;
  bool _isGenerating = false;
  int _durationInSeconds = 0;
  Timer? _timer;

  // Getters pour exposer l'état à la View
  bool get isRecording => _isRecording;
  bool get isGenerating => _isGenerating;
  int get durationInSeconds => _durationInSeconds;

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
      notifyListeners();

      // TODO: Supprimer l'enregistrement audio
      // await _voiceService.deleteRecording();

    } catch (e) {
      debugPrint('Erreur reset: $e');
    }
  }

  /// Valide et traite l'enregistrement
  Future<void> validate() async {
    if (!canValidate) return;

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

      // Simulation du traitement
      await Future.delayed(const Duration(seconds: 3));

      // TODO: Parser le texte transcrit pour générer la facture
      // final invoiceData = await _invoiceService.parseTranscription(transcription);

      _isGenerating = false;
      notifyListeners();

      // TODO: Navigation vers l'écran de prévisualisation de facture
      // avec les données extraites

    } catch (e) {
      _isGenerating = false;
      notifyListeners();
      debugPrint('Erreur validation: $e');
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