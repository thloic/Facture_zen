import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_model.dart';

/// Générateur PDF pour le template Classic
class PdfClassicGenerator {

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
            _buildItemsTable(invoice),
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
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1F2937'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('FACTURE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('N° ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text('Date: ${_formatDate(invoice.invoiceDate)}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.white)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildParties(InvoiceModel invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _buildPartyInfo('DE', invoice.companyName, invoice.companyAddress, invoice.companyPhone, invoice.companySiret)),
        pw.SizedBox(width: 32),
        pw.Expanded(child: _buildPartyInfo('FACTURÉ À', invoice.clientName, invoice.clientAddress, null, null)),
      ],
    );
  }

  static pw.Widget _buildPartyInfo(String label, String name, String address, String? phone, String? siret) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
        pw.SizedBox(height: 8),
        pw.Text(name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(address, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        if (phone != null) pw.Text(phone, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        if (siret != null) pw.Text('SIRET: $siret', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.only(topLeft: pw.Radius.circular(8), topRight: pw.Radius.circular(8))),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 3, child: pw.Text('DESCRIPTION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
                pw.Expanded(child: pw.Text('QTÉ', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
                pw.Expanded(child: pw.Text('PRIX U.', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
                pw.Expanded(child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          ...invoice.items.asMap().entries.map((entry) {
            final item = entry.value;
            return pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: entry.key.isEven ? PdfColors.white : PdfColors.grey50),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text(item.description, style: const pw.TextStyle(fontSize: 11))),
                  pw.Expanded(child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 11))),
                  pw.Expanded(child: pw.Text('${item.unitPrice.toStringAsFixed(2)} EUR', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 11))),
                  pw.Expanded(child: pw.Text('${item.total.toStringAsFixed(2)} EUR', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildTotalRow('Sous-total:', invoice.subtotal),
          if (invoice.hasDiscount) ...[pw.SizedBox(height: 8), _buildTotalRow(invoice.discountLabel ?? 'Réduction:', -invoice.discountAmount, isDiscount: true)],
          if (invoice.hasTax) ...[pw.SizedBox(height: 8), _buildTotalRow('TVA (${invoice.taxRate}%):', invoice.taxAmount)],
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1F2937'), borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.SizedBox(width: 120, child: pw.Text(invoice.hasTax ? 'TOTAL TTC:' : 'TOTAL:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                pw.SizedBox(width: 16),
                pw.Text('${invoice.total.toStringAsFixed(2)} EUR', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
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