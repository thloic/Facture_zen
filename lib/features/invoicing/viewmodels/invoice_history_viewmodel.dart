import 'package:flutter/foundation.dart';

class InvoiceHistoryViewModel extends ChangeNotifier {
  // Services injectés
  // final InvoiceService _invoiceService;

  // État de la vue
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _filteredInvoices = [];
  String _searchQuery = '';

  // Getters pour exposer l'état à la View
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  List<Map<String, dynamic>> get filteredInvoices => _filteredInvoices;

  // TODO: Injection du service
  // InvoiceHistoryViewModel(this._invoiceService);

  /// Charge toutes les factures depuis la base de données
  Future<void> loadInvoices() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // TODO: Récupérer les factures depuis Firebase/API
      // _invoices = await _invoiceService.getAllInvoices();

      // Données de test pour le moment
      await Future.delayed(const Duration(seconds: 1));
      _invoices = _generateMockInvoices();
      _filteredInvoices = List.from(_invoices);

      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Impossible de charger les factures';
      _setLoading(false);
      debugPrint('Erreur chargement factures: $e');
    }
  }

  /// Recherche des factures par nom de client
  void searchInvoices(String query) {
    _searchQuery = query.toLowerCase().trim();

    if (_searchQuery.isEmpty) {
      _filteredInvoices = List.from(_invoices);
    } else {
      _filteredInvoices = _invoices.where((invoice) {
        final clientName = invoice['clientName']?.toLowerCase() ?? '';
        return clientName.contains(_searchQuery);
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
          return b['timestamp'].compareTo(a['timestamp']);
        });
        break;
      case 'date_old':
        _filteredInvoices.sort((a, b) {
          return a['timestamp'].compareTo(b['timestamp']);
        });
        break;
      case 'amount_asc':
        _filteredInvoices.sort((a, b) {
          return a['amount'].compareTo(b['amount']);
        });
        break;
      case 'amount_desc':
        _filteredInvoices.sort((a, b) {
          return b['amount'].compareTo(a['amount']);
        });
        break;
    }

    notifyListeners();
  }

  /// Supprime une facture
  /// @param invoiceId L'identifiant de la facture à supprimer
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      // TODO: Supprimer de Firebase/API
      // await _invoiceService.deleteInvoice(invoiceId);

      // Supprimer de la liste locale
      _invoices.removeWhere((invoice) => invoice['id'] == invoiceId);
      _filteredInvoices.removeWhere((invoice) => invoice['id'] == invoiceId);

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur suppression facture: $e');
      _errorMessage = 'Impossible de supprimer la facture';
      notifyListeners();
    }
  }

  /// Génère des données de test
  List<Map<String, dynamic>> _generateMockInvoices() {
    return [
      {
        'id': '1',
        'clientName': 'Facture Medha & Co',
        'date': '28 Oct 2025',
        'size': '1 MB',
        'amount': 450.0,
        'timestamp': DateTime(2025, 10, 28),
      },
      {
        'id': '2',
        'clientName': 'Roger Holmes',
        'date': '28 Oct 2025',
        'size': '1 MB',
        'amount': 320.0,
        'timestamp': DateTime(2025, 10, 28),
      },
      {
        'id': '3',
        'clientName': 'Facture Medha & Co',
        'date': '28 Oct 2025',
        'size': '1 MB',
        'amount': 680.0,
        'timestamp': DateTime(2025, 10, 28),
      },
      {
        'id': '4',
        'clientName': 'Roger Holmes',
        'date': '28 Oct 2025',
        'size': '1 MB',
        'amount': 550.0,
        'timestamp': DateTime(2025, 10, 28),
      },
      {
        'id': '5',
        'clientName': 'Facture Medha & Co',
        'date': '28 Oct 2025',
        'size': '1 MB',
        'amount': 890.0,
        'timestamp': DateTime(2025, 10, 28),
      },
      {
        'id': '6',
        'clientName': 'Roger Holmes',
        'date': '28 Oct 2025',
        'size': '1 MB',
        'amount': 420.0,
        'timestamp': DateTime(2025, 10, 28),
      },
    ];
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