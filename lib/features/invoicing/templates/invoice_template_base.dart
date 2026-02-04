import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import 'classic_template.dart';
import 'corporate_template.dart';
import 'creative_template.dart';
import 'elegant_template.dart';
import 'minimal_template.dart';
import 'modern_template.dart';
import 'professional_template.dart';
import 'compact_template.dart';
import 'stylish_template.dart';
import 'executive_template.dart';
import 'luxe_template.dart';

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
  Widget buildInvoice(BuildContext context, InvoiceModel invoice, {bool isPremium = false});

  /// Méthode de compatibilité (appelle buildInvoice)
  Widget build(BuildContext context, InvoiceModel invoice, {bool isPremium = false}) {
    return buildInvoice(context, invoice, isPremium: isPremium);
  }

  /// Génère le PDF (optionnel, pour plus tard)
  Future<void>? generatePDF(InvoiceModel invoice) => null;
}

/// Mixin pour fournir des méthodes communes aux templates
mixin InvoiceTemplateMixin {
  /// Widget de signature VoxIn pour utilisateurs gratuits
  Widget buildVoxInSignature() {
    return Container(
      margin: const EdgeInsets.only(top: 32, bottom: 8),
      child: Column(
        children: [
          // Ligne de séparation élégante
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade400,
                  Colors.grey.shade200,
                ],
              ),
            ),
          ),
          // Signature
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade50,
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Généré avec',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'VoxIn',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
  Future<void>? generatePDF(InvoiceModel invoice) => null;


/// Enum des templates disponibles
enum InvoiceTemplateType {
  classic,
  modern,
  minimal,
  corporate,
  creative,
  elegant,
  professional,
  compact,
  stylish,
  executive,
  luxe,
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
      case InvoiceTemplateType.professional:
        return ProfessionalTemplate();
      case InvoiceTemplateType.compact:
        return CompactTemplate();
      case InvoiceTemplateType.stylish:
        return StylishTemplate();
      case InvoiceTemplateType.executive:
        return ExecutiveTemplate();
      case InvoiceTemplateType.luxe:
        return LuxeTemplate();
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
      ProfessionalTemplate(),
      CompactTemplate(),
      StylishTemplate(),
      ExecutiveTemplate(),
      LuxeTemplate(),
    ];
  }
}

