import 'package:flutter/foundation.dart';

/// Modèle de données pour une facture
class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String clientName;
  final String clientAddress;
  final List<InvoiceItem> items;
  final String? notes;

  // Informations entreprise
  final String companyName;
  final String companyAddress;
  final String? companyPhone;
  final String? companyEmail;
  final String? companySiret;
  final String? companyLogo;

  // TVA et réductions optionnelles
  final double? taxRate; // null = pas de TVA
  final double? discountRate; // null = pas de réduction
  final String? discountLabel; // Ex: "Remise 10%"

  InvoiceModel({
    required this.id,
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
    this.taxRate, // Par défaut null
    this.discountRate,
    this.discountLabel,
  });

  /// Calcul du sous-total
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  /// Calcul de la réduction
  double get discountAmount {
    if (discountRate == null || discountRate! <= 0) return 0.0;
    return subtotal * (discountRate! / 100);
  }

  /// Montant après réduction
  double get afterDiscount {
    return subtotal - discountAmount;
  }

  /// Calcul de la TVA
  double get taxAmount {
    if (taxRate == null || taxRate! <= 0) return 0.0;
    return afterDiscount * (taxRate! / 100);
  }

  /// Total TTC ou HT selon présence TVA
  double get total {
    return afterDiscount + taxAmount;
  }

  /// Indique si la facture a de la TVA
  bool get hasTax => taxRate != null && taxRate! > 0;

  /// Indique si la facture a une réduction
  bool get hasDiscount => discountRate != null && discountRate! > 0;

  /// Formate la date au format "28 Oct 2025 | 17h8"
  String get formattedDate {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${invoiceDate.day} ${months[invoiceDate.month - 1]} ${invoiceDate.year} | ${invoiceDate.hour}h${invoiceDate.minute}';
  }

  /// Factory depuis Map (données GPT)
  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
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

      // TVA et réductions optionnelles (depuis GPT)
      taxRate: map['taxRate'] as double?,
      discountRate: map['discountRate'] as double?,
      discountLabel: map['discountLabel'] as String?,
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