import 'package:flutter/foundation.dart';
import '../../invoicing/models/invoice_model.dart';
import '../models/user_profile_model.dart';
import '../../../common/services/auth_service.dart';
import '../../../common/services/firebase_invoice_service.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseInvoiceService _invoiceService;
  
  UserProfileModel? _userProfile;
  List<InvoiceModel> _recentInvoices = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPageIndex = 0;
  String _searchQuery = '';

  HomeViewModel({FirebaseInvoiceService? invoiceService})
      : _invoiceService = invoiceService ?? FirebaseInvoiceService();

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
             invoice.id.toLowerCase().contains(_searchQuery.toLowerCase());
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

      // Récupérer les factures récentes depuis Firebase
      debugPrint('📋 Chargement des factures récentes...');
      final allInvoices = await _invoiceService.getUserInvoices();
      _recentInvoices = allInvoices.take(5).toList(); // Les 5 plus récentes
      debugPrint('✅ ${_recentInvoices.length} facture(s) récente(s) chargée(s)');

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