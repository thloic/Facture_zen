import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_model.dart';

/// Générateur PDF pour le template Moderne
class PdfModernGenerator {
  // Couleurs du thème moderne
  static const PdfColor primaryColor = PdfColor(0.357, 0.373, 0.780); // #5B5FC7
  static const PdfColor accentColor = PdfColor(0.612, 0.624, 0.910); // #9C9FE8
  static const PdfColor lightBg = PdfColor(0.980, 0.980, 0.980); // #FAFAFA

  static pw.Page generate(InvoiceModel invoice) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // En-tête avec fond coloré
            _buildGradientHeader(invoice),

            // Contenu principal
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPartiesInfo(invoice),
                    pw.SizedBox(height: 24),
                    _buildItemsCards(invoice),
                    pw.Spacer(),
                    _buildTotals(invoice),
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      pw.SizedBox(height: 16),
                      _buildNotes(invoice.notes!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// En-tête avec fond coloré et informations principales
  static pw.Widget _buildGradientHeader(InvoiceModel invoice) {
    return pw.Container(
      width: double.infinity,
      color: primaryColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Titre FACTURE
              pw.Text(
                'FACTURE',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 2,
                ),
              ),

              // Numéro de facture dans une capsule
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(1.0, 1.0, 1.0, 0.25),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                ),
                child: pw.Text(
                  invoice.invoiceNumber,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 10),

          // Date
          pw.Text(
            _formatDate(invoice.invoiceDate),
            style: const pw.TextStyle(
              fontSize: 13,
              color: PdfColor(1.0, 1.0, 1.0, 0.85),
            ),
          ),
        ],
      ),
    );
  }

  /// Informations FROM et BILL TO dans des cartes
  static pw.Widget _buildPartiesInfo(InvoiceModel invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _buildInfoCard(
            'FROM',
            [
              invoice.companyName,
              invoice.companyAddress,
              if (invoice.companyPhone != null && invoice.companyPhone!.isNotEmpty)
                invoice.companyPhone!,
              if (invoice.companyEmail != null && invoice.companyEmail!.isNotEmpty)
                invoice.companyEmail!,
            ],
          ),
        ),

        pw.SizedBox(width: 20),

        pw.Expanded(
          child: _buildInfoCard(
            'BILL TO',
            [
              invoice.clientName,
              invoice.clientAddress,
            ],
          ),
        ),
      ],
    );
  }

  /// Carte d'information avec bordure colorée
  static pw.Widget _buildInfoCard(String title, List<String> lines) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(
          color: const PdfColor(0.357, 0.373, 0.780, 0.25),
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
              letterSpacing: 1.2,
            ),
          ),

          pw.SizedBox(height: 8),

          ...lines.map((line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(
              line,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
            ),
          )),
        ],
      ),
    );
  }

  /// Liste des items dans des cartes avec barre latérale colorée
  static pw.Widget _buildItemsCards(InvoiceModel invoice) {
    return pw.Column(
      children: invoice.items.map((item) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Barre latérale colorée
              pw.Container(
                width: 3,
                height: 35,
                decoration: const pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
              ),

              pw.SizedBox(width: 10),

              // Description et détails
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      item.description,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                      maxLines: 2,
                      overflow: pw.TextOverflow.clip,
                    ),

                    pw.SizedBox(height: 2),

                    pw.Text(
                      '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} EUR',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(width: 10),

              // Prix total
              pw.Container(
                alignment: pw.Alignment.centerRight,
                width: 80,
                child: pw.Text(
                  '${item.total.toStringAsFixed(2)} EUR',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Section des totaux avec fond coloré
  static pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: const pw.BoxDecoration(
        color: PdfColor(0.357, 0.373, 0.780, 0.08),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          // Subtotal
          _buildTotalRow('Subtotal', invoice.subtotal),

          pw.SizedBox(height: 5),

          // TVA
          if (invoice.hasTax)
            _buildTotalRow(
              'TVA (${invoice.taxRate?.toStringAsFixed(0) ?? '20'}%)',
              invoice.taxAmount,
            ),

          // Remise
          if (invoice.hasDiscount)
            _buildTotalRow(
              'Remise',
              -invoice.discountAmount,
            ),

          pw.SizedBox(height: 10),

          // Total avec fond coloré
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 1,
                  ),
                ),

                pw.Text(
                  '${invoice.total.toStringAsFixed(2)} EUR',
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

  /// Ligne de total
  static pw.Widget _buildTotalRow(String label, double amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey800,
          ),
        ),

        pw.Text(
          '${amount.toStringAsFixed(2)} EUR',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
      ],
    );
  }

  /// Notes avec fond jaune/ambre
  static pw.Widget _buildNotes(String notes) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor(1.0, 0.98, 0.80),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(
          color: const PdfColor(1.0, 0.93, 0.51),
          width: 1,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ℹ',
            style: pw.TextStyle(
              fontSize: 14,
              color: const PdfColor(0.78, 0.58, 0.13),
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(width: 10),

          pw.Expanded(
            child: pw.Text(
              notes,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formatage de la date
  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}