import 'package:flutter/material.dart';
import 'classic_template.dart';
import 'invoice_model.dart';
import 'minimal_template.dart';
import 'modern_template.dart';

/// Interface commune pour tous les templates de facture
abstract class InvoiceTemplate {
  /// Nom du template
  String get name;

  /// Description courte
  String get description;

  /// Icône représentative
  IconData get icon;

  /// Couleur principale du template
  Color get primaryColor;

  /// Widget de prévisualisation (miniature)
  Widget buildThumbnail(BuildContext context);

  /// Widget complet de la facture
  Widget buildInvoice(BuildContext context, InvoiceModel invoice);

  /// Génère le PDF (optionnel, pour plus tard)
  Future<void>? generatePDF(InvoiceModel invoice) => null;
}

/// Enum des templates disponibles
enum InvoiceTemplateType {
  classic,
  modern,
  minimal,
}

/// Factory pour créer les templates
class InvoiceTemplateFactory {
  static InvoiceTemplate createTemplate(InvoiceTemplateType type) {
    switch (type) {
      case InvoiceTemplateType.classic:
        return ClassicTemplate();
      case InvoiceTemplateType.modern:
        return ModernTemplate();
      case InvoiceTemplateType.minimal:
        return MinimalTemplate();
    }
  }

  static List<InvoiceTemplate> getAllTemplates() {
    return [
      ClassicTemplate(),
      ModernTemplate(),
      MinimalTemplate(),
    ];
  }
}

// Import des templates (à créer)