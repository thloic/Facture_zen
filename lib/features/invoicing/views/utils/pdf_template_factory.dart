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
    switch (templateType) {
      case InvoiceTemplateType.classic:
        return PdfClassicGenerator.generate(invoice);

      case InvoiceTemplateType.corporate:
        return PdfCorporateGenerator.generate(invoice);

      case InvoiceTemplateType.creative:
        return PdfCreativeGenerator.generate(invoice);

      case InvoiceTemplateType.minimal:
        return PdfMinimalGenerator.generate(invoice);

      case InvoiceTemplateType.elegant:
        return PdfElegantGenerator.generate(invoice);

      default:
      // Fallback sur Classic si template inconnu
        return PdfClassicGenerator.generate(invoice);
    }
  }
}