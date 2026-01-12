/// Modèle de données pour une facture
class InvoiceModel {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String clientName;
  final String clientAddress;
  final List<InvoiceItem> items;
  final String? notes;

  // Informations entreprise (depuis le profil utilisateur)
  final String companyName;
  final String companyAddress;
  final String? companyPhone;
  final String? companyEmail;
  final String? companySiret;
  final String? companyLogo; // URL ou base64

  InvoiceModel({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.clientName,
    required this.clientAddress,
    required this.items,
    this.notes,
    required this.companyName,
    required this.companyAddress,
    this.companyPhone,
    this.companyEmail,
    this.companySiret,
    this.companyLogo,
  });

  /// Calcul du sous-total
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  /// Calcul de la TVA (20% par défaut)
  double get taxAmount {
    return subtotal * 0.20;
  }

  /// Total TTC
  double get total {
    return subtotal + taxAmount;
  }

  /// Factory depuis Map (données GPT)
  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      invoiceNumber: map['invoiceNumber'] as String? ?? _generateInvoiceNumber(),
      invoiceDate: DateTime.now(),
      clientName: map['clientName'] as String? ?? 'Client inconnu',
      clientAddress: map['clientAddress'] as String? ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      notes: map['notes'] as String?,

      // TODO: Récupérer depuis le profil utilisateur
      companyName: 'Mon Entreprise',
      companyAddress: '123 Rue Example\n75001 Paris',
      companyPhone: '+33 1 23 45 67 89',
      companyEmail: 'contact@entreprise.fr',
      companySiret: '123 456 789 00012',
    );
  }

  /// Génère un numéro de facture unique
  static String _generateInvoiceNumber() {
    final now = DateTime.now();
    return 'FACT-${now.year}${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';
  }
}

/// Item/ligne de facture
class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}