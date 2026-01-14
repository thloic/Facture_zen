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
          invoiceNumber: 'FACT-2025-001',
          invoiceDate: DateTime(2025, 10, 28, 17, 8),
          clientName: 'Medha & Co',
          clientAddress: '123 Rue Example\n75001 Paris',
          items: [
            InvoiceItem(
              description: 'Service de consultation',
              quantity: 1,
              unitPrice: 450.0,
            ),
          ],
          companyName: 'Mon Entreprise',
          companyAddress: '456 Avenue Test\n75002 Paris',
          companyPhone: '+33 1 23 45 67 89',
          companyEmail: 'contact@entreprise.fr',
          taxRate: 20.0, // Avec TVA
        ),
        InvoiceModel(
          id: '2',
          invoiceNumber: 'FACT-2025-002',
          invoiceDate: DateTime(2025, 10, 28, 17, 8),
          clientName: 'Medha & Co',
          clientAddress: '123 Rue Example\n75001 Paris',
          items: [
            InvoiceItem(
              description: 'Maintenance système',
              quantity: 2,
              unitPrice: 225.0,
            ),
          ],
          companyName: 'Mon Entreprise',
          companyAddress: '456 Avenue Test\n75002 Paris',
          taxRate: null, // Sans TVA
        ),
        InvoiceModel(
          id: '3',
          invoiceNumber: 'FACT-2025-003',
          invoiceDate: DateTime(2025, 10, 28, 17, 8),
          clientName: 'Medha & Co',
          clientAddress: '123 Rue Example\n75001 Paris',
          items: [
            InvoiceItem(
              description: 'Formation équipe',
              quantity: 1,
              unitPrice: 450.0,
            ),
          ],
          companyName: 'Mon Entreprise',
          companyAddress: '456 Avenue Test\n75002 Paris',
          discountRate: 10.0, // Avec réduction
          discountLabel: 'Remise client fidèle',
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