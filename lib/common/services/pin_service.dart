import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// PinService
/// Service de gestion du code PIN à 4 chiffres
/// Stocke le PIN de manière sécurisée avec flutter_secure_storage
class PinService {
  static const String _pinKey = 'user_pin';
  static const String _hasPinKey = 'has_pin_configured';
  static const String _pinEnabledKey = 'pin_enabled'; // ✅ NOUVEAU

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Configure les options de stockage sécurisé pour Android
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  // ─────────────────────────────────────────────
  // ✅ Gestion de l'activation du PIN
  // ─────────────────────────────────────────────

  /// Retourne true si le PIN est activé dans les paramètres
  Future<bool> isPinEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Par défaut : désactivé (false) — le client veut que ce soit facultatif
      return prefs.getBool(_pinEnabledKey) ?? false;
    } catch (e) {
      debugPrint('❌ Erreur isPinEnabled : $e');
      return false;
    }
  }

  /// Active ou désactive le PIN dans les paramètres
  /// - Si on désactive : supprime le PIN stocké
  /// - Si on active : le PIN sera créé via PinSetupScreen
  Future<bool> setPinEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pinEnabledKey, enabled);

      // Si on désactive le PIN, on supprime le PIN existant
      if (!enabled) {
        await deletePin();
        debugPrint('✅ PIN désactivé et supprimé');
      } else {
        debugPrint('✅ PIN activé (configuration requise)');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Erreur setPinEnabled : $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Méthodes existantes
  // ─────────────────────────────────────────────

  /// Sauvegarde le code PIN de manière sécurisée
  Future<bool> savePin(String pin) async {
    try {
      if (pin.length != 4 || !_isNumeric(pin)) {
        debugPrint('❌ PIN invalide : doit contenir 4 chiffres');
        return false;
      }

      final hashedPin = _hashPin(pin);

      await _secureStorage.write(
        key: _pinKey,
        value: hashedPin,
        aOptions: _getAndroidOptions(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasPinKey, true);
      await prefs.setBool(_pinEnabledKey, true); // ✅ Activer automatiquement après setup

      debugPrint('✅ PIN sauvegardé avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde du PIN : $e');
      return false;
    }
  }

  /// Vérifie si le PIN entré correspond au PIN stocké
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

      debugPrint(isValid ? '✅ PIN correct' : '❌ PIN incorrect');
      return isValid;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du PIN : $e');
      return false;
    }
  }

  /// Vérifie si un PIN est configuré ET activé
  Future<bool> hasPin() async {
    try {
      // ✅ Si le PIN est désactivé dans les paramètres, on retourne false directement
      final enabled = await isPinEnabled();
      if (!enabled) {
        debugPrint('🔐 PinService.hasPin() - PIN désactivé dans les paramètres');
        return false;
      }

      // Vérifier si le PIN existe dans SecureStorage (source de vérité)
      final storedPin = await _secureStorage.read(
        key: _pinKey,
        aOptions: _getAndroidOptions(),
      );
      
      if (storedPin == null) {
        debugPrint('🔐 PinService.hasPin() - Aucun PIN dans SecureStorage');
        return false;
      }

      // Réparation : PIN existe dans SecureStorage mais pas dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final hasPinConfigured = prefs.getBool(_hasPinKey) ?? false;
      
      if (!hasPinConfigured) {
        debugPrint('🔐 Réparation: PIN existe mais flag has_pin_configured est false');
        await prefs.setBool(_hasPinKey, true);
      }

      debugPrint('🔐 PinService.hasPin() - PIN présent et activé ✅');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de l\'existence du PIN : $e');
      return false;
    }
  }

  /// Supprime le PIN (lors de la déconnexion ou désactivation)
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
  String _hashPin(String pin) {
    int hash = 0;
    for (int i = 0; i < pin.length; i++) {
      hash += int.parse(pin[i]) * (i + 1) * 137;
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