import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  /// Demande la permission pour le microphone.
  /// Renvoie true si la permission est accordée.
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      debugPrint('🎤 Microphone permission granted');
      return true;
    } else if (status.isPermanentlyDenied) {
      debugPrint('🎤 Microphone permission permanently denied');
      // Optionnel : ouvrir les paramètres de l'application
      await openAppSettings();
      return false;
    } else {
      debugPrint('🎤 Microphone permission denied');
      return false;
    }
  }

  /// Demande la permission pour la caméra.
  /// Renvoie true si la permission est accordée.
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      debugPrint('📷 Camera permission granted');
      return true;
    } else if (status.isPermanentlyDenied) {
      debugPrint('📷 Camera permission permanently denied');
      await openAppSettings();
      return false;
    } else {
      debugPrint('📷 Camera permission denied');
      return false;
    }
  }

  /// Demande la permission pour la galerie de photos.
  /// Renvoie true si la permission est accordée.
  Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
     if (status.isGranted) {
      debugPrint('🖼️ Photos permission granted');
      return true;
    } else if (status.isPermanentlyDenied) {
      debugPrint('🖼️ Photos permission permanently denied');
      await openAppSettings();
      return false;
    } else {
      debugPrint('🖼️ Photos permission denied');
      return false;
    }
  }
}
