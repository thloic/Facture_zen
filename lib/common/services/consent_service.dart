import 'package:shared_preferences/shared_preferences.dart';

/// Gère le consentement au partage de données avec nos partenaires
/// publicitaires (Google Ads, Meta) sur Android, où il n'existe pas
/// d'équivalent natif à l'App Tracking Transparency d'iOS.
class ConsentService {
  static const _askedKey = 'tracking_consent_asked';
  static const _grantedKey = 'tracking_consent_granted';

  Future<bool> hasBeenAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_askedKey) ?? false;
  }

  Future<bool> isGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_grantedKey) ?? false;
  }

  Future<void> setConsent(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
    await prefs.setBool(_grantedKey, granted);
  }
}
