import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../revenue_cat_util.dart' as rc_util;

class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  String _planName = 'Zen Gratuit';
  int _invoiceLimit = 3;

  bool get isPremium => _isPremium;
  String get planName => _planName;
  int get invoiceLimit => _invoiceLimit;

  PremiumProvider() {
    _init();
  }

  Future<void> _init() async {
    await refresh();
    Purchases.addCustomerInfoUpdateListener((info) async {
      rc_util.customerInfo = info;
      await refresh();
    });
  }

  Future<void> refresh() async {
    try {
      await rc_util.loadCustomerInfo();
      final info = rc_util.customerInfo;
      if (info == null) return;

      final active = info.entitlements.active;
      _isPremium = active.isNotEmpty;

      final keys = active.keys.map((k) =>
          k.toLowerCase()
           .replaceAll(' ', '_')
           .replaceAll('-', '_')).toSet();

      debugPrint('🔑 Active entitlement keys: $keys');

      // ✅ CORRIGÉ : limites alignées sur le cahier des charges
      if (keys.any((k) => k.contains('entreprise') || k.contains('enterprise'))) {
        _planName = 'Zen Entreprise';
        _invoiceLimit = 5000;
      } else if (keys.any((k) => k.contains('pro'))) {
        _planName = 'Zen Pro';
        _invoiceLimit = 250;
      } else if (keys.any((k) => k.contains('basic'))) {
        _planName = 'Zen Basic';
        _invoiceLimit = 100;
      } else if (_isPremium) {
        // ✅ AJOUTÉ : fallback si entitlement actif mais non reconnu
        debugPrint('⚠️ Entitlement non reconnu: $keys');
        _planName = 'Zen Basic';
        _invoiceLimit = 100;
      } else {
        _planName = 'Zen Gratuit';
        _invoiceLimit = 3;
      }

      notifyListeners();
      debugPrint(
          '✅ PremiumProvider: $_planName | premium: $_isPremium | limite: $_invoiceLimit');
    } catch (e) {
      debugPrint('❌ PremiumProvider.refresh: $e');
    }
  }
}