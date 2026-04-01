// lib/features/subscription/viewmodels/subscription_view_model.dart

import '../services/revenue_cat_service.dart';
import 'package:flutter/material.dart';

import '../../../common/services/tracking_service.dart';
import '../services/subscription_sync_service.dart';

class SubscriptionViewModel extends ChangeNotifier {
  final RevenueCatService _revenueCatService = RevenueCatService();
  final SubscriptionSyncService _syncService = SubscriptionSyncService(); // ✅ AJOUTER

  bool _isLoading = false;
  String? _errorMessage;
  Package? _selectedPackage;
  List<Package>? _allPackages;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Package? get selectedPackage => _selectedPackage;
  List<Package>? get allPackages => _allPackages;

  /// Obtenir le prix formaté d'un package spécifique
  String getPackagePrice(Package package) {
    return package.storeProduct.priceString;
  }

  /// Obtenir la période de facturation d'un package spécifique
  String getPackageBillingPeriod(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return '';
      case PackageType.annual:
        return '';
      case PackageType.weekly:
        return '/semaine';
      case PackageType.lifetime:
        return '';
      case PackageType.twoMonth:
        return '/2 mois';
      case PackageType.threeMonth:
        return '/3 mois';
      case PackageType.sixMonth:
        return '/6 mois';
      default:
        return '';
    }
  }

  /// ✅ Obtenir les informations d'un plan selon le package
  // lib/features/subscription/viewmodels/subscription_view_model.dart

/// Obtenir les informations d'un plan selon le package
PlanInfo getPlanInfo(Package package) {
  final identifier = package.identifier;
  final productId = package.storeProduct.identifier;
  
  debugPrint('📦 Analyzing package:');
  debugPrint('   Identifier: $identifier');
  debugPrint('   Product ID: $productId');

  // ✅ Mapper par product ID (plus fiable)
  if (productId.contains('enterprise') || identifier.contains('lifetime')) {
    return PlanInfo(
      badge: 'ILLIMITÉ',
      badgeColor: const Color(0xFFFFD700),
      title: 'ILLIMITÉ',
      subtitle: 'Factures illimitées',
      features: [
        'Factures illimitées',
        'Modèles de facture illimités',
        'Transcription vocale IA',
        'Export PDF instantané',
        'Chatbot assistance 24/7',
        'Historique de vos factures',
        'Support prioritaire 7j/7',
      ],
      isPopular: false,
    );
  }
  
  // ✅ PRO (500 factures) — 49,99 $
  if (productId.contains('pro') || identifier.contains('annual')) {
    return PlanInfo(
      badge: 'PRO',
      badgeColor: const Color(0xFF5B5FC7),
      title: 'PRO',
      subtitle: '500 factures',
      features: [
        '500 factures/mois',
        '5 modèles de facture',
        'Transcription vocale IA',
        'Export PDF instantané',
        'Chatbot assistance 24/7',
        'Historique de vos factures',
      ],
      isPopular: true,  // ✅ PRO est populaire
    );
  }
  
  // ✅ ESSENTIEL (200 factures) — 19,99 $
  // Par défaut, tout ce qui n'est pas Pro ou Enterprise
  return PlanInfo(
    badge: 'ESSENTIEL',
    badgeColor: const Color(0xFF10B981),
    title: 'ESSENTIEL',
    subtitle: '200 factures',
    features: [
      '200 factures/mois',
      '4 modèles de facture',
      'Transcription vocale IA',
      'Export PDF instantané',
      'Chatbot assistance 24/7',
      'Historique de vos factures',
    ],
    isPopular: false,
  );
}
  /// Nettoyer le titre du produit
  String _cleanTitle(String title, String fallback) {
    // Supprimer les préfixes communs de l'App Store/Play Store
    String cleaned = title
        .replaceAll(RegExp(r'\(.*?\)'), '') // Enlever les parenthèses
        .replaceAll('Facture Zen', '')
        .replaceAll('FactureZen', '')
        .trim();

    return cleaned.isNotEmpty ? cleaned : fallback;
  }

  /// ✅ CORRECTION: Charger TOUS les packages disponibles
  Future<void> loadOfferings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 Loading offerings...');
      await _revenueCatService.loadOfferings();

      // ✅ Utiliser la nouvelle méthode qui retourne TOUS les packages
      final allPackages = _revenueCatService.allAvailablePackages;

      debugPrint('✅ Total packages loaded: ${allPackages.length}');

      if (allPackages.isEmpty) {
        _errorMessage = 'Aucun abonnement disponible';
        _allPackages = null;
        debugPrint('❌ No packages found');
      } else {
        _allPackages = allPackages;

        // Afficher les détails de chaque package
        for (var i = 0; i < allPackages.length; i++) {
          final pkg = allPackages[i];
          debugPrint('Package ${i + 1}:');
          debugPrint('  ID: ${pkg.identifier}');
          debugPrint('  Type: ${pkg.packageType}');
          debugPrint('  Title: ${pkg.storeProduct.title}');
          debugPrint('  Price: ${pkg.storeProduct.priceString}');
        }

        // Sélectionner le package le plus populaire par défaut
        _selectedPackage = _findBestDefaultPackage(allPackages);
        debugPrint('✅ Default package selected: ${_selectedPackage!.identifier}');
      }
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des offres';
      _allPackages = null;
      debugPrint('❌ Error loading offerings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Trouver le meilleur package par défaut (annuel si disponible, sinon mensuel)
  Package _findBestDefaultPackage(List<Package> packages) {
    // 1. Chercher un package annuel
    final annual = packages.firstWhere(
          (p) => p.packageType == PackageType.annual,
      orElse: () => packages.first,
    );

    if (annual.packageType == PackageType.annual) {
      return annual;
    }

    // 2. Chercher un package mensuel
    final monthly = packages.firstWhere(
          (p) => p.packageType == PackageType.monthly,
      orElse: () => packages.first,
    );

    return monthly;
  }

  /// Sélectionner un package
  void selectPackage(Package package) {
  // ✅ LOGS DE DEBUG
  debugPrint('🔍 PACKAGE SELECTED:');
  debugPrint('   Identifier: ${package.identifier}');
  debugPrint('   Product ID: ${package.storeProduct.identifier}'); 
  debugPrint('   Price: ${package.storeProduct.priceString}');
  debugPrint('   Title: ${package.storeProduct.title}');
  
  _selectedPackage = package;
  _errorMessage = null;
  debugPrint('✅ Package selected: ${package.identifier}');
  
  // 📊 Tracker l'ajout au panier (Google Ads + Facebook Ads)
  final price = package.storeProduct.price;
  final currency = package.storeProduct.currencyCode;
  TrackingService().logAddToCart(
    productId: package.identifier,
    price: price,
    currency: currency,
  );
  
  notifyListeners();
}
  /// Vérifier si un package est sélectionné
  bool isPackageSelected(Package package) {
    return _selectedPackage?.identifier == package.identifier;
  }

  /// ✅ Acheter l'abonnement sélectionné
  /*Future<bool> purchaseSubscription() async {
    if (_selectedPackage == null) {
      _errorMessage = 'Aucun package sélectionné';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🛒 Starting purchase for: ${_selectedPackage!.identifier}');
      final success = await _revenueCatService.purchasePackageObject(_selectedPackage!);

      if (!success) {
        _errorMessage = 'L\'achat n\'a pas pu être finalisé';
      } else {
        debugPrint('✅ Purchase completed successfully!');
      }

      return success;
    } catch (e) {
      final errorString = e.toString();

      if (errorString.contains('PURCHASE_CANCELLED')) {
        _errorMessage = null;
        debugPrint('ℹ️ Purchase cancelled by user');
      } else if (errorString.contains('DEVELOPER_ERROR')) {
        _errorMessage = 'Erreur de configuration. Contactez le support.';
        debugPrint('❌ Developer error: $e');
      } else if (errorString.contains('NETWORK_ERROR')) {
        _errorMessage = 'Erreur réseau. Vérifiez votre connexion.';
        debugPrint('❌ Network error: $e');
      } else {
        _errorMessage = 'Erreur lors de l\'achat';
        debugPrint('❌ Purchase error: $e');
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }*/

  Future<bool> purchaseSubscription() async {
    if (_selectedPackage == null) {
      _errorMessage = 'Aucun package sélectionné';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🛒 Starting purchase for: ${_selectedPackage!.identifier}');
      final success = await _revenueCatService.purchasePackageObject(_selectedPackage!);

      if (success) {
        debugPrint('✅ Purchase completed successfully!');
        // 📊 Tracker l'achat (Google Ads + Facebook Ads)
        final price = _selectedPackage!.storeProduct.price;
        final currency = _selectedPackage!.storeProduct.currencyCode;
        await TrackingService().logPurchase(
          productId: _selectedPackage!.identifier,
          price: price,
          currency: currency,
        );
        debugPrint('📊 Purchase tracked: ${_selectedPackage!.identifier}');

        // ✅ SYNCHRONISER avec Firebase après l'achat
        await _syncService.syncSubscriptionStatus();
        // PremiumProvider se met à jour automatiquement via le listener RevenueCat
        // Pas besoin de faire quoi que ce soit d'autre ici ✅
        debugPrint('✅ Subscription synced with Firebase');
      } else {
        _errorMessage = 'L\'achat n\'a pas pu être finalisé';
      }

      return success;
    } catch (e) {
      final errorString = e.toString();

      if (errorString.contains('PURCHASE_CANCELLED')) {
        _errorMessage = null;
        debugPrint('ℹ️ Purchase cancelled by user');
      } else if (errorString.contains('DEVELOPER_ERROR')) {
        _errorMessage = 'Erreur de configuration. Contactez le support.';
        debugPrint('❌ Developer error: $e');
      } else if (errorString.contains('NETWORK_ERROR')) {
        _errorMessage = 'Erreur réseau. Vérifiez votre connexion.';
        debugPrint('❌ Network error: $e');
      } else {
        _errorMessage = 'Erreur lors de l\'achat';
        debugPrint('❌ Purchase error: $e');
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restaurer les achats
  Future<bool> restorePurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 Restoring purchases...');
      await _revenueCatService.restorePurchases();
      final isPremium = _revenueCatService.isPremium;

      if (!isPremium) {
        _errorMessage = 'Aucun achat à restaurer';
        debugPrint('ℹ️ No purchases to restore');
      } else {
        debugPrint('✅ Purchases restored successfully!');
      }

      return isPremium;
    } catch (e) {
      _errorMessage = 'Erreur lors de la restauration';
      debugPrint('❌ Restore error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vérifier le statut premium
  Future<bool> checkPremiumStatus() async {
    try {
      await _revenueCatService.loadCustomerInfo();
      return _revenueCatService.isPremium;
    } catch (e) {
      debugPrint('❌ Error checking premium status: $e');
      return false;
    }
  }

  /// Réinitialiser l'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Classe helper pour les informations de plan
class PlanInfo {
  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final List<String> features;
  final bool isPopular;

  PlanInfo({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.features,
    this.isPopular = false,
  });
}