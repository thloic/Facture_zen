import 'package:flutter/foundation.dart';
import '../../invoicing/models/invoice_model.dart';
import '../models/user_profile_model.dart';
import '../../../common/services/auth_service.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserProfileModel? _userProfile;
  List<InvoiceModel> _recentInvoices = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPageIndex = 0;
  String _searchQuery = '';

  UserProfileModel? get userProfile => _userProfile;
  List<InvoiceModel> get recentInvoices => _recentInvoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPageIndex => _currentPageIndex;
  String get searchQuery => _searchQuery;

  // Filtre les factures selon la recherche
  List<InvoiceModel> get filteredInvoices {
    if (_searchQuery.isEmpty) {
      return _recentInvoices;
    }
    return _recentInvoices.where((invoice) {
      return invoice.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             invoice.amount.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> loadInitialData() async {
    _setLoading(true);

    try {
      // Récupérer l'utilisateur connecté
      final currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        // Récupérer les données de l'utilisateur depuis la base de données
        final userData = await _authService.getUserData(currentUser.uid);
        
        if (userData != null) {
          final firstName = userData['firstName'] ?? '';
          final lastName = userData['lastName'] ?? '';
          final fullName = '${firstName} ${lastName}'.trim();
          
          _userProfile = UserProfileModel(
            fullName: fullName.isNotEmpty ? fullName : (currentUser.email ?? 'Utilisateur'),
            avatarUrl: userData['avatarUrl'],
          );
        } else {
          // Si pas de données dans la DB, utiliser l'email
          _userProfile = UserProfileModel(
            fullName: currentUser.email ?? 'Utilisateur',
          );
        }
      } else {
        // Aucun utilisateur connecté
        _userProfile = UserProfileModel(
          fullName: 'Invité',
        );
      }

      _recentInvoices = [
        InvoiceModel(
          id: '1',
          clientName: 'Facture Medha & Co',
          date: DateTime(2025, 10, 28, 17, 8),
          amount: '450€',
          status: 'paid',
        ),
        InvoiceModel(
          id: '2',
          clientName: 'Facture Medha & Co',
          date: DateTime(2025, 10, 28, 17, 8),
          amount: '450€',
          status: 'paid',
        ),
        InvoiceModel(
          id: '3',
          clientName: 'Facture Medha & Co',
          date: DateTime(2025, 10, 28, 17, 8),
          amount: '450€',
          status: 'paid',
        ),
      ];

      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des données';
      _setLoading(false);
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCurrentPage(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}