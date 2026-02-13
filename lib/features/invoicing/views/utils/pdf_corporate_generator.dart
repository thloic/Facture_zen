import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_model.dart';
import 'pdf_template_factory.dart';

/// Générateur PDF pour le template Corporate
class PdfCorporateGenerator {

  static pw.Page generate(InvoiceModel invoice, {bool isPremium = false}) {
    return generateWithLogo(invoice, null, isPremium: isPremium);
  }

  static pw.Page generateWithLogo(InvoiceModel invoice, pw.MemoryImage? logoImage, {bool isPremium = false}) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context context) {
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Bande latérale bleue
            pw.Container(width: 12, color: PdfColor.fromHex('#0066CC')),

            // Contenu
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildHeader(invoice, logoImage),
                    pw.SizedBox(height: 32),
                    _buildParties(invoice),
                    pw.SizedBox(height: 32),
                    _buildItemsTable(invoice),
                    pw.SizedBox(height: 24),
                    _buildTotals(invoice),
                    pw.Spacer(),
                    if (invoice.notes != null && invoice.notes!.isNotEmpty)
                      _buildNotes(invoice.notes!),
                    // Signature VoxIn pour utilisateurs gratuits
                    if (!isPremium)
                      PdfTemplateFactory.buildVoxInSignature(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static pw.Widget _buildHeader(InvoiceModel invoice, pw.MemoryImage? logoImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FACTURE',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#0066CC'),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'N° ${invoice.invoiceNumber}',
                    style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    _formatDate(invoice.invoiceDate),
                    style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            // Logo si disponible
            if (logoImage != null)
              pw.Container(
                width: 80,
                height: 80,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildParties(InvoiceModel invoice) {
    return pw.Row(
      children: [
        pw.Expanded(child: _buildBox('DE', [invoice.companyName, invoice.companyAddress, if (invoice.companyPhone != null) invoice.companyPhone!])),
        pw.SizedBox(width: 16),
        pw.Expanded(child: _buildBox('À', [invoice.clientName, invoice.clientAddress])),
      ],
    );
  }

  static pw.Widget _buildBox(String label, List<String> lines) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(color: PdfColors.grey50, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0066CC'))),
          pw.SizedBox(height: 8),
          ...lines.map((line) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 2), child: pw.Text(line, style: const pw.TextStyle(fontSize: 11)))),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    return pw.Column(
      children: [
        // En-tête
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#0066CC'), borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 2, child: pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
              pw.SizedBox(width: 50, child: pw.Text('QTÉ', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
              pw.SizedBox(width: 80, child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
            ],
          ),
        ),

        // Items
        ...invoice.items.map((item) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 2, child: pw.Text(item.description, style: const pw.TextStyle(fontSize: 11))),
              pw.SizedBox(width: 50, child: pw.Text('x${item.quantity}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 11))),
              pw.SizedBox(width: 80, child: pw.Text('${item.total.toStringAsFixed(2)} EUR', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
            ],
          ),
        )),
      ],
    );
  }

  static pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildTotalRow('Sous-total', invoice.subtotal),
          if (invoice.hasDiscount) ...[pw.SizedBox(height: 8), _buildTotalRow(invoice.discountLabel ?? 'Réduction', -invoice.discountAmount, isDiscount: true)],
          if (invoice.hasTax) ...[pw.SizedBox(height: 8), _buildTotalRow('TVA (${invoice.taxRate}%)', invoice.taxAmount)],
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#0066CC'), borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(invoice.hasTax ? 'TOTAL TTC' : 'TOTAL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                pw.SizedBox(width: 40),
                pw.Text('${invoice.total.toStringAsFixed(2)} EUR', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, {bool isDiscount = false}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.SizedBox(width: 120, child: pw.Text(label, style: pw.TextStyle(fontSize: 14, color: isDiscount ? PdfColors.red : PdfColors.black))),
        pw.SizedBox(width: 16),
        pw.Text('${amount.toStringAsFixed(2)} EUR', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: isDiscount ? PdfColors.red : PdfColors.black)),
      ],
    );
  }

  static pw.Widget _buildNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('NOTES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
          pw.SizedBox(height: 8),
          pw.Text(notes, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}