import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// PinService
/// Service de gestion du code PIN à 4 chiffres
/// Stocke le PIN de manière sécurisée avec flutter_secure_storage
class PinService {
  static const String _pinKey = 'user_pin';
  static const String _hasPinKey = 'has_pin_configured';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// Configure les options de stockage sécurisé pour Android
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
    encryptedSharedPreferences: true,
  );

  /// Sauvegarde le code PIN de manière sécurisée
  /// @param pin Code PIN à 4 chiffres
  Future<bool> savePin(String pin) async {
    try {
      if (pin.length != 4 || !_isNumeric(pin)) {
        debugPrint('❌ PIN invalide : doit contenir 4 chiffres');
        return false;
      }

      // Hasher le PIN avant de le stocker (simple hash pour l'exemple)
      final hashedPin = _hashPin(pin);
      
      // Stocker dans flutter_secure_storage
      await _secureStorage.write(
        key: _pinKey,
        value: hashedPin,
        aOptions: _getAndroidOptions(),
      );

      // Marquer que le PIN est configuré dans shared_preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasPinKey, true);

      debugPrint('✅ PIN sauvegardé avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde du PIN : $e');
      return false;
    }
  }

  /// Vérifie si le PIN entré correspond au PIN stocké
  /// @param pin Code PIN à vérifier
  Future<bool> verifyPin(String pin) async {
    try {
      if (pin.length != 4 || !_isNumeric(pin)) {
        debugPrint('❌ PIN invalide');
        return false;
      }

      final storedHashedPin = await _secureStorage.read(
        key: _pinKey,
        aOptions: _getAndroidOptions(),
      );

      if (storedHashedPin == null) {
        debugPrint('❌ Aucun PIN configuré');
        return false;
      }

      final hashedPin = _hashPin(pin);
      final isValid = hashedPin == storedHashedPin;

      if (isValid) {
        debugPrint('✅ PIN correct');
      } else {
        debugPrint('❌ PIN incorrect');
      }

      return isValid;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du PIN : $e');
      return false;
    }
  }

  /// Vérifie si un PIN est configuré
  Future<bool> hasPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPinConfigured = prefs.getBool(_hasPinKey) ?? false;
      
      // Double vérification : aussi vérifier dans secure storage
      if (hasPinConfigured) {
        final storedPin = await _secureStorage.read(
          key: _pinKey,
          aOptions: _getAndroidOptions(),
        );
        return storedPin != null;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de l\'existence du PIN : $e');
      return false;
    }
  }

  /// Supprime le PIN (lors de la déconnexion complète)
  Future<bool> deletePin() async {
    try {
      await _secureStorage.delete(
        key: _pinKey,
        aOptions: _getAndroidOptions(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasPinKey, false);

      debugPrint('✅ PIN supprimé');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression du PIN : $e');
      return false;
    }
  }

  /// Hash simple du PIN (pour ne pas stocker en clair)
  /// Dans une vraie app, utiliser bcrypt ou argon2
  String _hashPin(String pin) {
    // Hash simple : on multiplie chaque chiffre par sa position et on somme
    // Puis on convertit en string avec un salt
    int hash = 0;
    for (int i = 0; i < pin.length; i++) {
      hash += int.parse(pin[i]) * (i + 1) * 137; // 137 est notre "salt"
    }
    return 'PIN_${hash}_HASH';
  }

  /// Vérifie si une chaîne contient uniquement des chiffres
  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }

  /// Récupère le nombre de tentatives échouées
  Future<int> getFailedAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('pin_failed_attempts') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Incrémente le compteur de tentatives échouées
  Future<void> incrementFailedAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getFailedAttempts();
      await prefs.setInt('pin_failed_attempts', current + 1);
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'incrémentation des tentatives : $e');
    }
  }

  /// Réinitialise le compteur de tentatives échouées
  Future<void> resetFailedAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pin_failed_attempts', 0);
    } catch (e) {
      debugPrint('❌ Erreur lors de la réinitialisation des tentatives : $e');
    }
  }
}
