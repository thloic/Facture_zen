import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_model.dart';

/// Générateur PDF pour le template Minimal
class PdfMinimalGenerator {

  static pw.Page generate(InvoiceModel invoice) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(invoice),
            pw.SizedBox(height: 48),
            _buildParties(invoice),
            pw.SizedBox(height: 48),
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

  static pw.Widget _buildHeader(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(height: 2, width: 60, color: PdfColors.black),
        pw.SizedBox(height: 16),
        pw.Text('INVOICE', style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.normal, letterSpacing: 4)),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Text(invoice.invoiceNumber, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 16),
            pw.Text('•', style: const pw.TextStyle(color: PdfColors.grey400)),
            pw.SizedBox(width: 16),
            pw.Text(_formatDate(invoice.invoiceDate), style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildParties(InvoiceModel invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _buildParty('From', invoice.companyName, invoice.companyAddress, invoice.companyPhone)),
        pw.SizedBox(width: 48),
        pw.Expanded(child: _buildParty('To', invoice.clientName, invoice.clientAddress, null)),
      ],
    );
  }

  static pw.Widget _buildParty(String label, String name, String address, String? phone) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500, letterSpacing: 1)),
        pw.SizedBox(height: 12),
        pw.Text(name, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(address, style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
        if (phone != null) ...[pw.SizedBox(height: 2), pw.Text(phone, style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700))],
      ],
    );
  }

  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    return pw.Column(
      children: [
        // En-tête
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 3, child: pw.Text('Description', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1))),
              pw.Expanded(child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1))),
              pw.Expanded(child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1))),
              pw.SizedBox(width: 16),
              pw.SizedBox(width: 80, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1))),
            ],
          ),
        ),
        pw.Container(height: 1, color: PdfColors.grey300),

        // Items
        ...invoice.items.map((item) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 16),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 3, child: pw.Text(item.description, style: const pw.TextStyle(fontSize: 14))),
              pw.Expanded(child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700))),
              pw.Expanded(child: pw.Text('EUR ${item.unitPrice.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700))),
              pw.SizedBox(width: 16),
              pw.SizedBox(width: 80, child: pw.Text('EUR ${item.total.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
            ],
          ),
        )),
      ],
    );
  }

  static pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Column(
      children: [
        _buildTotalRow('Subtotal', invoice.subtotal, false),
        pw.SizedBox(height: 8),
        if (invoice.hasTax) _buildTotalRow('Tax (${invoice.taxRate}%)', invoice.taxAmount, false),
        if (invoice.hasDiscount) _buildTotalRow('Discount', -invoice.discountAmount, false),
        pw.SizedBox(height: 16),
        pw.Container(height: 2, color: PdfColors.black, margin: const pw.EdgeInsets.only(bottom: 16)),
        _buildTotalRow('Total', invoice.total, true),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, bool isTotal) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(width: 120, child: pw.Text(label, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal))),
        pw.SizedBox(width: 32),
        pw.SizedBox(width: 100, child: pw.Text('EUR ${amount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: isTotal ? 20 : 14, fontWeight: pw.FontWeight.bold))),
      ],
    );
  }

  static pw.Widget _buildNotes(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Notes', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500, letterSpacing: 1)),
        pw.SizedBox(height: 12),
        pw.Text(notes, style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}