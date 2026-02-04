import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_model.dart';

/// Générateur PDF pour le template Elegant
class PdfElegantGenerator {

  static pw.Page generate(InvoiceModel invoice) {
    return generateWithLogo(invoice, null);
  }

  static pw.Page generateWithLogo(InvoiceModel invoice, pw.MemoryImage? logoImage) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(invoice, logoImage),
            pw.SizedBox(height: 40),
            _buildParties(invoice),
            pw.SizedBox(height: 40),
            _buildItemsTable(invoice),
            pw.SizedBox(height: 32),
            _buildTotals(invoice),
            pw.Spacer(),
            if (invoice.notes != null && invoice.notes!.isNotEmpty)
              _buildNotes(invoice.notes!),
          ],
        );
      },
    );
  }

  static pw.Widget _buildHeader(InvoiceModel invoice, pw.MemoryImage? logoImage) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Container(width: 4, height: 50, color: PdfColor.fromHex('#D4AF37')), // Or
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FACTURE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.normal, color: PdfColor.fromHex('#2D3436'), letterSpacing: 3)),
                    pw.SizedBox(height: 4),
                    pw.Text(invoice.invoiceNumber, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
            if (logoImage != null)
              pw.Container(
                width: 80,
                height: 80,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1, color: PdfColor.fromHex('#D4AF37')),
      ],
    );
  }

  static pw.Widget _buildParties(InvoiceModel invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _buildParty('De', invoice.companyName, invoice.companyAddress)),
        pw.SizedBox(width: 24),
        pw.Expanded(child: _buildParty('À', invoice.clientName, invoice.clientAddress)),
      ],
    );
  }

  static pw.Widget _buildParty(String label, String name, String address) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#D4AF37'), letterSpacing: 1)),
        pw.SizedBox(height: 12),
        pw.Text(name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text(address, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
      ],
    );
  }

  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    return pw.Column(
      children: [
        // En-tête
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#D4AF37'), width: 2))),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 2, child: pw.Text('Description', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2D3436'), letterSpacing: 1))),
              pw.SizedBox(width: 40, child: pw.Text('Qté', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(width: 70, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
            ],
          ),
        ),

        // Items
        ...invoice.items.map((item) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 2, child: pw.Text(item.description, style: const pw.TextStyle(fontSize: 12))),
              pw.SizedBox(width: 40, child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 12))),
              pw.SizedBox(width: 70, child: pw.Text('${item.total.toStringAsFixed(2)} EUR', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
            ],
          ),
        )),
      ],
    );
  }

  static pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Column(
      children: [
        if (invoice.hasDiscount) _buildTotalRow('Réduction', -invoice.discountAmount),
        if (invoice.hasTax) _buildTotalRow('TVA (${invoice.taxRate}%)', invoice.taxAmount),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColor.fromHex('#D4AF37'), width: 2), borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2D3436'), letterSpacing: 2)),
              pw.Text('${invoice.total.toStringAsFixed(2)} EUR', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#D4AF37'))),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.SizedBox(width: 120, child: pw.Text(label, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 13))),
          pw.SizedBox(width: 16),
          pw.SizedBox(width: 80, child: pw.Text('${amount.toStringAsFixed(2)} EUR', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  static pw.Widget _buildNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('NOTES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(notes, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}