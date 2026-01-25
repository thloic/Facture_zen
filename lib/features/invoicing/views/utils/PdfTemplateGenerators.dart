import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_model.dart';

/// Helpers pour les templates PDF (suite du générateur)
class PdfTemplateGenerators {

  // ============= HELPERS CREATIVE (suite) =============

  static pw.Widget buildCreativeBox(String label, List<String> lines, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 8),
          ...lines.map((line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(line, style: const pw.TextStyle(fontSize: 11)),
          )),
        ],
      ),
    );
  }

  static pw.Widget buildCreativeTotalRow(String label, double amount, bool isWhite) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 13,
              color: isWhite ? PdfColors.white : PdfColors.grey800,
            ),
          ),
          pw.Text(
            '${amount.toStringAsFixed(2)} EUR',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: isWhite ? PdfColors.white : PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildCreativeNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('NOTES',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#FF6B6B'))),
          pw.SizedBox(height: 8),
          pw.Text(notes, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  // ============= HELPERS MINIMAL =============

  static pw.Widget buildMinimalParty(String label, String name, String address, String? phone) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey500,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          name,
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          address,
          style: const pw.TextStyle(
            fontSize: 13,
            color: PdfColors.grey700,
          ),
        ),
        if (phone != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            phone,
            style: const pw.TextStyle(
              fontSize: 13,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget buildMinimalItemsTable(InvoiceModel invoice) {
    return pw.Column(
      children: [
        // En-tête
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'Description',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'Qty',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'Price',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.SizedBox(
                width: 80,
                child: pw.Text(
                  'Total',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),

        pw.Container(
          height: 1,
          color: PdfColors.grey300,
        ),

        // Items
        ...invoice.items.map((item) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey200),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    item.description,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    '${item.quantity}',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'EUR ${item.unitPrice.toStringAsFixed(2)}',
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(
                    'EUR ${item.total.toStringAsFixed(2)}',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget buildMinimalTotals(InvoiceModel invoice) {
    return pw.Column(
      children: [
        buildMinimalTotalRow('Subtotal', invoice.subtotal, false),
        pw.SizedBox(height: 8),
        if (invoice.hasTax)
          buildMinimalTotalRow('Tax (${invoice.taxRate}%)', invoice.taxAmount, false),
        if (invoice.hasDiscount)
          buildMinimalTotalRow('Discount', -invoice.discountAmount, false),
        pw.SizedBox(height: 16),
        pw.Container(
          height: 2,
          color: PdfColors.black,
          margin: const pw.EdgeInsets.only(bottom: 16),
        ),
        buildMinimalTotalRow('Total', invoice.total, true),
      ],
    );
  }

  static pw.Widget buildMinimalTotalRow(String label, double amount, bool isTotal) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.SizedBox(width: 32),
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            'EUR ${amount.toStringAsFixed(2)}',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget buildMinimalNotes(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey500,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          notes,
          style: const pw.TextStyle(
            fontSize: 13,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  // ============= HELPERS ELEGANT =============

  static pw.Widget buildElegantParty(String label, String name, String address) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#D4AF37'), // Or
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          name,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          address,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget buildElegantItemsTable(InvoiceModel invoice) {
    return pw.Column(
      children: [
        // En-tête
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColor.fromHex('#D4AF37'), width: 2),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Description',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#2D3436'),
                    letterSpacing: 1,
                  ),
                ),
              ),
              pw.SizedBox(
                width: 40,
                child: pw.Text(
                  'Qty',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(
                width: 70,
                child: pw.Text(
                  'Total',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Items
        ...invoice.items.map((item) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey200),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  item.description,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(
                width: 40,
                child: pw.Text(
                  '${item.quantity}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(
                width: 70,
                child: pw.Text(
                  '${item.total.toStringAsFixed(2)} EUR',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  static pw.Widget buildElegantTotals(InvoiceModel invoice) {
    return pw.Column(
      children: [
        if (invoice.hasDiscount)
          buildElegantTotalRow('Reduction', -invoice.discountAmount),
        if (invoice.hasTax)
          buildElegantTotalRow('TVA (${invoice.taxRate}%)', invoice.taxAmount),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#D4AF37'), width: 2),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#2D3436'),
                  letterSpacing: 2,
                ),
              ),
              pw.Text(
                '${invoice.total.toStringAsFixed(2)} EUR',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#D4AF37'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget buildElegantTotalRow(String label, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 13),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '${amount.toStringAsFixed(2)} EUR',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildElegantNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
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

  // ============= COMMUNS =============

  static String formatDateMinimal(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}