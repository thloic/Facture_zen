// lib/features/subscription/viewmodels/subscription_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../services/revenue_cat_service.dart';

class SubscriptionViewModel extends ChangeNotifier {
  final RevenueCatService _revenueCatService = RevenueCatService();

  bool _isLoading = false;
  String? _errorMessage;
  Package? _selectedPackage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Package? get selectedPackage => _selectedPackage;

  // Prix formaté
  String get formattedPrice {
    if (_selectedPackage == null) return '...';
    return _selectedPackage!.storeProduct.priceString;
  }

  // Description du produit
  String get productDescription {
    if (_selectedPackage == null) return 'Chargement...';
    return _selectedPackage!.storeProduct.description;
  }

  // Titre du produit
  String get productTitle {
    if (_selectedPackage == null) return 'Premium';
    return _selectedPackage!.storeProduct.title;
  }

  // Période de facturation (ex: "mensuel", "annuel")
  String get billingPeriod {
    if (_selectedPackage == null) return '';

    final packageType = _selectedPackage!.packageType;
    switch (packageType) {
      case PackageType.monthly:
        return '/mois';
      case PackageType.annual:
        return '/an';
      case PackageType.weekly:
        return '/semaine';
      default:
        return '';
    }
  }

  /// Charger les offres disponibles
  Future<void> loadOfferings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _revenueCatService.loadOfferings();

      // Récupérer les packages disponibles
      final packages = _revenueCatService.availablePackages;

      if (packages != null && packages.isNotEmpty) {
        // Prioriser le package mensuel, sinon prendre le premier
        _selectedPackage = _revenueCatService.monthlyPackage ?? packages.first;
      } else {
        _errorMessage = 'Aucun abonnement disponible';
      }
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: $e';
      print('❌ Error loading offerings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Acheter l'abonnement
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
      final success = await _revenueCatService.purchasePackageObject(_selectedPackage!);

      if (!success) {
        _errorMessage = 'L\'achat n\'a pas pu être finalisé';
      }

      return success;
    } catch (e) {
      // Gérer l'annulation par l'utilisateur
      if (e.toString().contains('PURCHASE_CANCELLED')) {
        _errorMessage = null; // Pas d'erreur si annulé par l'utilisateur
      } else {
        _errorMessage = 'Erreur lors de l\'achat';
      }
      print('❌ Purchase error: $e');
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
      await _revenueCatService.restorePurchases();

      // Vérifier si l'utilisateur est maintenant premium
      final isPremium = _revenueCatService.isPremium;

      if (!isPremium) {
        _errorMessage = 'Aucun achat à restaurer';
      }

      return isPremium;
    } catch (e) {
      _errorMessage = 'Erreur lors de la restauration';
      print('❌ Restore error: $e');
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
      print('❌ Error checking premium status: $e');
      return false;
    }
  }

  /// Obtenir tous les packages disponibles
  List<Package>? get allPackages {
    return _revenueCatService.availablePackages;
  }

  /// Sélectionner un package différent
  void selectPackage(Package package) {
    _selectedPackage = package;
    notifyListeners();
  }
}