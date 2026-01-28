import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_model.dart';

/// Générateur PDF pour le template Creative
class PdfCreativeGenerator {

  static pw.Page generate(InvoiceModel invoice) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(invoice),
            pw.SizedBox(height: 32),
            _buildParties(invoice),
            pw.SizedBox(height: 32),
            _buildItems(invoice),
            pw.SizedBox(height: 24),
            _buildTotals(invoice),
            pw.Spacer(),
            if (invoice.notes != null && invoice.notes!.isNotEmpty)
              _buildNotes(invoice.notes!),
          ],
        );
      },
    );
  }

  static pw.Widget _buildHeader(InvoiceModel invoice) {
    return pw.Row(
      children: [
        pw.Container(
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FF6B6B'), borderRadius: pw.BorderRadius.circular(30)),
          child: pw.Center(child: pw.Icon(pw.IconData(0xe873), color: PdfColors.white, size: 30)),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
              pw.Text(invoice.invoiceNumber, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildParties(InvoiceModel invoice) {
    return pw.Row(
      children: [
        pw.Expanded(child: _buildBox('FROM', [invoice.companyName, invoice.companyAddress], PdfColor.fromHex('#FF6B6B'))),
        pw.SizedBox(width: 12),
        pw.Expanded(child: _buildBox('TO', [invoice.clientName, invoice.clientAddress], PdfColor.fromHex('#FECA57'))),
      ],
    );
  }

  static pw.Widget _buildBox(String label, List<String> lines, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(16), border: pw.Border.all(color: PdfColors.grey300)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 8),
          ...lines.map((line) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 2), child: pw.Text(line, style: const pw.TextStyle(fontSize: 11)))),
        ],
      ),
    );
  }

  static pw.Widget _buildItems(InvoiceModel invoice) {
    return pw.Column(
      children: invoice.items.map((item) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(12), border: pw.Border.all(color: PdfColors.grey300)),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(item.description, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('${item.quantity} x ${item.unitPrice.toStringAsFixed(2)} EUR', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                ],
              ),
            ),
            pw.Text('${item.total.toStringAsFixed(2)} EUR', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#FF6B6B'))),
          ],
        ),
      )).toList(),
    );
  }

  static pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FF6B6B'), borderRadius: pw.BorderRadius.circular(16)),
      child: pw.Column(
        children: [
          if (invoice.hasDiscount) _buildTotalRow('Réduction', -invoice.discountAmount, true),
          if (invoice.hasTax) _buildTotalRow('TVA (${invoice.taxRate}%)', invoice.taxAmount, true),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.Text('${invoice.total.toStringAsFixed(2)} EUR', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, bool isWhite) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 13, color: isWhite ? PdfColors.white : PdfColors.grey800)),
          pw.Text('${amount.toStringAsFixed(2)} EUR', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: isWhite ? PdfColors.white : PdfColors.grey800)),
        ],
      ),
    );
  }

  static pw.Widget _buildNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(12)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('NOTES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#FF6B6B'))),
          pw.SizedBox(height: 8),
          pw.Text(notes, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}