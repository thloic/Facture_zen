import 'package:flutter/foundation.dart';
import '../../invoicing/models/invoice_model.dart';
import '../models/user_profile_model.dart';

class HomeViewModel extends ChangeNotifier {
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

  Future<void> loadInitialData() async {
    _setLoading(true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      _userProfile = UserProfileModel(
        fullName: 'Maxime Watson',
      );

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