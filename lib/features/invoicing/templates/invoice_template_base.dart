import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import 'classic_template.dart';
import 'corporate_template.dart';
import 'creative_template.dart';
import 'elegant_template.dart';
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

  /// Méthode de compatibilité (appelle buildInvoice)
  Widget build(BuildContext context, InvoiceModel invoice) {
    return buildInvoice(context, invoice);
  }

  /// Génère le PDF (optionnel, pour plus tard)
  Future<void>? generatePDF(InvoiceModel invoice) => null;
}

/// Enum des templates disponibles
enum InvoiceTemplateType {
  classic,
  modern,
  minimal,
  corporate,
  creative,
  elegant,
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
      case InvoiceTemplateType.corporate:
        return CorporateTemplate();
      case InvoiceTemplateType.creative:
        return CreativeTemplate();
      case InvoiceTemplateType.elegant:
        return ElegantTemplate();
    }
  }

  static List<InvoiceTemplate> getAllTemplates() {
    return [
      ClassicTemplate(),
      ModernTemplate(),
      MinimalTemplate(),
      CorporateTemplate(),
      CreativeTemplate(),
      ElegantTemplate(),
    ];
  }
}

