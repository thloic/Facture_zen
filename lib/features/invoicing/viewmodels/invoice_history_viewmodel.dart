import 'package:flutter/foundation.dart';
import '../../../common/services/firebase_invoice_service.dart';
import '../models/invoice_model.dart';

class InvoiceHistoryViewModel extends ChangeNotifier {
  // Services injectés
  final FirebaseInvoiceService _invoiceService;

  // État de la vue
  bool _isLoading = false;
  String? _errorMessage;
  List<InvoiceModel> _invoices = [];
  List<InvoiceModel> _filteredInvoices = [];
  String _searchQuery = '';

  // Getters pour exposer l'état à la View
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  List<InvoiceModel> get filteredInvoices => _filteredInvoices;

  /// Constructeur avec injection du service
  InvoiceHistoryViewModel({FirebaseInvoiceService? invoiceService})
      : _invoiceService = invoiceService ?? FirebaseInvoiceService();

  /// Charge toutes les factures depuis la base de données
  Future<void> loadInvoices() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('📋 Chargement des factures depuis Firebase...');
      
      // Récupérer les factures depuis Firebase
      _invoices = await _invoiceService.getUserInvoices();
      _filteredInvoices = List.from(_invoices);

      debugPrint('✅ ${_invoices.length} facture(s) chargée(s)');
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Impossible de charger les factures';
      _setLoading(false);
      debugPrint('❌ Erreur chargement factures: $e');
    }
  }

  /// Recherche des factures par nom de client
  void searchInvoices(String query) {
    _searchQuery = query.toLowerCase().trim();

    if (_searchQuery.isEmpty) {
      _filteredInvoices = List.from(_invoices);
    } else {
      _filteredInvoices = _invoices.where((invoice) {
        final clientName = invoice.clientName.toLowerCase();
        final invoiceNumber = invoice.invoiceNumber.toLowerCase();
        return clientName.contains(_searchQuery) || invoiceNumber.contains(_searchQuery);
      }).toList();
    }

    notifyListeners();
  }

  /// Filtre les factures selon un critère
  /// @param filterType Type de filtre (date, montant, etc.)
  void filterInvoices(String filterType) {
    switch (filterType) {
      case 'date_recent':
        _filteredInvoices.sort((a, b) {
          return b.invoiceDate.compareTo(a.invoiceDate);
        });
        break;
      case 'date_old':
        _filteredInvoices.sort((a, b) {
          return a.invoiceDate.compareTo(b.invoiceDate);
        });
        break;
      case 'amount_asc':
        _filteredInvoices.sort((a, b) {
          return a.total.compareTo(b.total);
        });
        break;
      case 'amount_desc':
        _filteredInvoices.sort((a, b) {
          return b.total.compareTo(a.total);
        });
        break;
    }

    notifyListeners();
  }

  /// Supprime une facture
  /// @param invoiceId L'identifiant de la facture à supprimer
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      debugPrint('🗑️ Suppression de la facture $invoiceId...');
      
      // Supprimer de Firebase
      await _invoiceService.deleteInvoice(invoiceId);

      // Supprimer de la liste locale
      _invoices.removeWhere((invoice) => invoice.id == invoiceId);
      _filteredInvoices.removeWhere((invoice) => invoice.id == invoiceId);

      debugPrint('✅ Facture supprimée');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur suppression facture: $e');
      _errorMessage = 'Impossible de supprimer la facture';
      notifyListeners();
    }
  }

  /// Modifie l'état de chargement et notifie les listeners
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Nettoyage lors de la destruction du ViewModel
  @override
  void dispose() {
    super.dispose();
  }
}