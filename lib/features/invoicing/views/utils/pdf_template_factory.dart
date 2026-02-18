
import 'package:facture_zen/features/invoicing/views/utils/pdf_modern_generator.dart';
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
  static pw.Page generatePdf(InvoiceTemplateType templateType, InvoiceModel invoice, {bool isPremium = false}) {
    return generatePdfWithLogo(templateType, invoice, null, isPremium: isPremium);
  }

  /// Génère une page PDF selon le type de template avec logo optionnel
  static pw.Page generatePdfWithLogo(InvoiceTemplateType templateType, InvoiceModel invoice, pw.MemoryImage? logoImage, {bool isPremium = false}) {
    switch (templateType) {
      case InvoiceTemplateType.classic:
        return PdfClassicGenerator.generateWithLogo(invoice, logoImage, isPremium: isPremium);

      case InvoiceTemplateType.corporate:
        return PdfCorporateGenerator.generateWithLogo(invoice, logoImage, isPremium: isPremium);

      case InvoiceTemplateType.creative:
        return PdfCreativeGenerator.generateWithLogo(invoice, logoImage, isPremium: isPremium);

      case InvoiceTemplateType.minimal:
        return PdfMinimalGenerator.generateWithLogo(invoice, logoImage, isPremium: isPremium);

      case InvoiceTemplateType.elegant:
        return PdfElegantGenerator.generate(invoice);
      case InvoiceTemplateType.modern:
        return PdfModernGenerator.generate(invoice);

      case InvoiceTemplateType.professional:
      case InvoiceTemplateType.compact:
      case InvoiceTemplateType.stylish:
      case InvoiceTemplateType.executive:
      case InvoiceTemplateType.luxe:
        // Pour ces nouveaux types, nous utilisons un rendu adapté avec logo
        return PdfClassicGenerator.generateWithLogo(invoice, logoImage, isPremium: isPremium);

      default:
      // Fallback sur Classic si template inconnu
        return PdfClassicGenerator.generateWithLogo(invoice, logoImage, isPremium: isPremium);
    }
  }
  
  /// Crée la signature VoxIn pour les utilisateurs gratuits
  static pw.Widget buildVoxInSignature() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#5B5FC7'),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Icon(
              pw.IconData(0xe84f), // workspace_premium icon
              color: PdfColors.white,
              size: 14,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            'Généré avec VoxIn',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}