import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_model.dart';

/// Générateur de PDF optimisés pour chaque template
class PdfTemplateGenerators {

  /// Génère un PDF avec le template Classic
  static pw.Page generateClassicPdf(InvoiceModel invoice) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête avec fond bleu foncé
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1F2937'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'FACTURE',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'N° ${invoice.invoiceNumber}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date: ${_formatDate(invoice.invoiceDate)}',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 32),

            // Informations entreprise et client
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _buildClassicPartyInfo('DE', invoice.companyName, invoice.companyAddress,
                      invoice.companyPhone, invoice.companySiret),
                ),
                pw.SizedBox(width: 32),
                pw.Expanded(
                  child: _buildClassicPartyInfo('FACTURÉ À', invoice.clientName, invoice.clientAddress, null, null),
                ),
              ],
            ),

            pw.SizedBox(height: 32),

            // Tableau des items
            _buildClassicItemsTable(invoice),

            pw.SizedBox(height: 24),

            // Totaux
            _buildClassicTotals(invoice),

            pw.Spacer(),

            // Notes
            if (invoice.notes != null && invoice.notes!.isNotEmpty)
              _buildClassicNotes(invoice.notes!),
          ],
        );
      },
    );
  }

  /// Génère un PDF avec le template Corporate
  static pw.Page generateCorporatePdf(InvoiceModel invoice) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context context) {
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Bande latérale bleue
            pw.Container(
              width: 12,
              color: PdfColor.fromHex('#0066CC'),
            ),

            // Contenu
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    pw.Column(
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

                    pw.SizedBox(height: 32),

                    // Parties
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildCorporateBox('DE', [
                            invoice.companyName,
                            invoice.companyAddress,
                            if (invoice.companyPhone != null) invoice.companyPhone!,
                          ]),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Expanded(
                          child: _buildCorporateBox('À', [
                            invoice.clientName,
                            invoice.clientAddress,
                          ]),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 32),

                    // Items
                    _buildCorporateItemsTable(invoice),

                    pw.SizedBox(height: 24),

                    // Totaux
                    _buildCorporateTotals(invoice),

                    pw.Spacer(),

                    // Notes
                    if (invoice.notes != null && invoice.notes!.isNotEmpty)
                      _buildCorporateNotes(invoice.notes!),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Génère un PDF avec le template Creative
  static pw.Page generateCreativePdf(InvoiceModel invoice) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête avec cercle coloré
            pw.Row(
              children: [
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FF6B6B'),
                    borderRadius: pw.BorderRadius.circular(30),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '📄',
                      style: const pw.TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.Text(
                        invoice.invoiceNumber,
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 32),

            // Parties
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildCreativeBox('FROM', [
                    invoice.companyName,
                    invoice.companyAddress,
                  ], PdfColor.fromHex('#FF6B6B')),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _buildCreativeBox('TO', [
                    invoice.clientName,
                    invoice.clientAddress,
                  ], PdfColor.fromHex('#FECA57')),
                ),
              ],
            ),

            pw.SizedBox(height: 32),

            // Items
            ...invoice.items.map((item) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColor.fromInt(0x33FF6B6B)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.description,
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)}€',
                          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                  pw.Text(
                    '${item.total.toStringAsFixed(2)}€',
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#FF6B6B'),
                    ),
                  ),
                ],
              ),
            )),

            pw.SizedBox(height: 24),

            // Totaux
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FF6B6B'),
                borderRadius: pw.BorderRadius.circular(16),
              ),
              child: pw.Column(
                children: [
                  if (invoice.hasDiscount)
                    _buildCreativeTotalRow('Réduction', -invoice.discountAmount, true),
                  if (invoice.hasTax)
                    _buildCreativeTotalRow('TVA (${invoice.taxRate}%)', invoice.taxAmount, true),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '${invoice.total.toStringAsFixed(2)}€',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // Notes
            if (invoice.notes != null && invoice.notes!.isNotEmpty)
              _buildCreativeNotes(invoice.notes!),
          ],
        );
      },
    );
  }

  // ============= HELPERS CLASSIC =============

  static pw.Widget _buildClassicPartyInfo(String label, String name, String address, String? phone, String? siret) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          name,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(address, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        if (phone != null)
          pw.Text(phone, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        if (siret != null)
          pw.Text('SIRET: $siret', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _buildClassicItemsTable(InvoiceModel invoice) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // En-tête
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text('DESCRIPTION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ),
                pw.Expanded(
                  child: pw.Text('QTÉ', textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ),
                pw.Expanded(
                  child: pw.Text('PRIX U.', textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ),
                pw.Expanded(
                  child: pw.Text('TOTAL', textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          // Lignes
          ...invoice.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: index.isEven ? PdfColors.white : PdfColors.grey50,
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(item.description, style: const pw.TextStyle(fontSize: 11)),
                  ),
                  pw.Expanded(
                    child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 11)),
                  ),
                  pw.Expanded(
                    child: pw.Text('${item.unitPrice.toStringAsFixed(2)} €', textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 11)),
                  ),
                  pw.Expanded(
                    child: pw.Text('${item.total.toStringAsFixed(2)} €', textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildClassicTotals(InvoiceModel invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildTotalRow('Sous-total:', invoice.subtotal),
          if (invoice.hasDiscount) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow(invoice.discountLabel ?? 'Réduction:', -invoice.discountAmount, isDiscount: true),
          ],
          if (invoice.hasTax) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow('TVA (${invoice.taxRate}%):', invoice.taxAmount),
          ],
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1F2937'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.SizedBox(
                  width: 120,
                  child: pw.Text(
                    invoice.hasTax ? 'TOTAL TTC:' : 'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Text(
                  '${invoice.total.toStringAsFixed(2)} €',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildClassicNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
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

  // ============= HELPERS CORPORATE =============

  static pw.Widget _buildCorporateBox(String label, List<String> lines) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0066CC'),
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

  static pw.Widget _buildCorporateItemsTable(InvoiceModel invoice) {
    return pw.Column(
      children: [
        // En-tête
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#0066CC'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text('DESCRIPTION',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ),
              pw.SizedBox(
                width: 50,
                child: pw.Text('QTÉ',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ),
              pw.SizedBox(
                width: 80,
                child: pw.Text('TOTAL',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ),
            ],
          ),
        ),

        // Items
        ...invoice.items.map((item) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text(item.description, style: const pw.TextStyle(fontSize: 11)),
              ),
              pw.SizedBox(
                width: 50,
                child: pw.Text('×${item.quantity}', textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 11)),
              ),
              pw.SizedBox(
                width: 80,
                child: pw.Text('${item.total.toStringAsFixed(2)}€', textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  static pw.Widget _buildCorporateTotals(InvoiceModel invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildTotalRow('Sous-total', invoice.subtotal),
          if (invoice.hasDiscount) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow(invoice.discountLabel ?? 'Réduction', -invoice.discountAmount, isDiscount: true),
          ],
          if (invoice.hasTax) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow('TVA (${invoice.taxRate}%)', invoice.taxAmount),
          ],
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#0066CC'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  invoice.hasTax ? 'TOTAL TTC' : 'TOTAL',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
                pw.SizedBox(width: 40),
                pw.Text(
                  '${invoice.total.toStringAsFixed(2)}€',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCorporateNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
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

  // ============= HELPERS CREATIVE =============

  static pw.Widget _buildCreativeBox(String label, List<String> lines, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: color.shade(0.8)),
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

  static pw.Widget _buildCreativeTotalRow(String label, double amount, bool isWhite) {
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
            '${amount.toStringAsFixed(2)}€',
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

  static pw.Widget _buildCreativeNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0x1AFF6B6B),
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

  // ============= HELPERS COMMUNS =============

  static pw.Widget _buildTotalRow(String label, double amount, {bool isDiscount = false}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              color: isDiscount ? PdfColors.red : PdfColors.black,
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Text(
          '${amount.toStringAsFixed(2)} €',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: isDiscount ? PdfColors.red : PdfColors.black,
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}