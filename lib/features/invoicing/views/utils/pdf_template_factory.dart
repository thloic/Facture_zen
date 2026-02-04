import 'package:pdf/widgets.dart' as pw;
import '../../models/invoice_model.dart';
import '../../templates/invoice_template_base.dart';
import 'pdf_classic_generator.dart';
import 'pdf_corporate_generator.dart';
import 'pdf_creative_generator.dart';
import 'pdf_minimal_generator.dart';
import 'pdf_elegant_generator.dart';

/// Factory pour générer les PDFs selon le template choisi
class PdfTemplateFactory {

  /// Génère une page PDF selon le type de template
  static pw.Page generatePdf(InvoiceTemplateType templateType, InvoiceModel invoice) {
    return generatePdfWithLogo(templateType, invoice, null);
  }

  /// Génère une page PDF selon le type de template avec logo optionnel
  static pw.Page generatePdfWithLogo(InvoiceTemplateType templateType, InvoiceModel invoice, pw.MemoryImage? logoImage) {
    switch (templateType) {
      case InvoiceTemplateType.classic:
        return PdfClassicGenerator.generateWithLogo(invoice, logoImage);

      case InvoiceTemplateType.corporate:
        return PdfCorporateGenerator.generateWithLogo(invoice, logoImage);

      case InvoiceTemplateType.creative:
        return PdfCreativeGenerator.generateWithLogo(invoice, logoImage);

      case InvoiceTemplateType.minimal:
        return PdfMinimalGenerator.generateWithLogo(invoice, logoImage);

      case InvoiceTemplateType.elegant:
        return PdfElegantGenerator.generateWithLogo(invoice, logoImage);

      case InvoiceTemplateType.professional:
      case InvoiceTemplateType.compact:
      case InvoiceTemplateType.stylish:
      case InvoiceTemplateType.executive:
      case InvoiceTemplateType.luxe:
        // Pour ces nouveaux types, nous utilisons un rendu adapté avec logo
        return PdfClassicGenerator.generateWithLogo(invoice, logoImage);

      default:
      // Fallback sur Classic si template inconnu
        return PdfClassicGenerator.generateWithLogo(invoice, logoImage);
    }
  }
}