import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/invoice_model.dart';

/// Service de génération de PDF pour les factures
class PdfGeneratorService {
  
  /// Génère un PDF à partir d'une facture
  /// Retourne le fichier PDF temporaire
  Future<File> generateInvoicePdf(InvoiceModel invoice) async {
    try {
      debugPrint('📄 Génération du PDF pour la facture: ${invoice.invoiceNumber}');
      
      final pdf = pw.Document();

      // Ajouter la page de facture
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return _buildInvoicePage(invoice);
          },
        ),
      );

      // Sauvegarder le PDF dans un fichier temporaire
      final output = await _getTempPdfFile(invoice.invoiceNumber);
      final bytes = await pdf.save();
      await output.writeAsBytes(bytes);

      debugPrint('✅ PDF généré avec succès: ${output.path}');
      debugPrint('   Taille: ${bytes.length} bytes');
      
      return output;

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la génération du PDF: $e');
      debugPrint('📍 StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Construit le contenu de la page de facture
  pw.Widget _buildInvoicePage(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // En-tête avec informations entreprise
        _buildHeader(invoice),
        
        pw.SizedBox(height: 40),
        
        // Informations client
        _buildClientInfo(invoice),
        
        pw.SizedBox(height: 40),
        
        // Tableau des articles
        _buildItemsTable(invoice),
        
        pw.SizedBox(height: 30),
        
        // Totaux
        _buildTotals(invoice),
        
        pw.Spacer(),
        
        // Notes et pied de page
        if (invoice.notes != null && invoice.notes!.isNotEmpty)
          _buildNotes(invoice.notes!),
        
        _buildFooter(invoice),
      ],
    );
  }

  /// En-tête du document
  pw.Widget _buildHeader(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Informations entreprise
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              invoice.companyName,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              invoice.companyAddress,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            if (invoice.companyPhone != null) ...[
              pw.SizedBox(height: 3),
              pw.Text(
                'Tél: ${invoice.companyPhone}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
            if (invoice.companyEmail != null) ...[
              pw.SizedBox(height: 3),
              pw.Text(
                invoice.companyEmail!,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
            if (invoice.companySiret != null) ...[
              pw.SizedBox(height: 3),
              pw.Text(
                'SIRET: ${invoice.companySiret}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ],
        ),
        
        // Numéro et date de facture
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'FACTURE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              invoice.invoiceNumber,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              _formatDate(invoice.invoiceDate),
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Informations client
  pw.Widget _buildClientInfo(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Facturé à:',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            invoice.clientName,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            invoice.clientAddress,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  /// Tableau des articles
  pw.Widget _buildItemsTable(InvoiceModel invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // En-tête du tableau
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          children: [
            _buildTableHeader('Description'),
            _buildTableHeader('Qté'),
            _buildTableHeader('Prix unitaire'),
            _buildTableHeader('Total'),
          ],
        ),
        
        // Lignes des articles
        ...invoice.items.map((item) => pw.TableRow(
          children: [
            _buildTableCell(item.description, isLeft: true),
            _buildTableCell(item.quantity.toString()),
            _buildTableCell('${item.unitPrice.toStringAsFixed(2)} €'),
            _buildTableCell('${item.total.toStringAsFixed(2)} €'),
          ],
        )),
      ],
    );
  }

  /// Cellule d'en-tête du tableau
  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Cellule du tableau
  pw.Widget _buildTableCell(String text, {bool isLeft = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: isLeft ? pw.TextAlign.left : pw.TextAlign.center,
      ),
    );
  }

  /// Section des totaux
  pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          child: pw.Column(
            children: [
              // Sous-total
              _buildTotalRow('Sous-total HT:', '${invoice.subtotal.toStringAsFixed(2)} €'),
              
              // Réduction si applicable
              if (invoice.hasDiscount) ...[
                pw.SizedBox(height: 5),
                _buildTotalRow(
                  invoice.discountLabel ?? 'Réduction (${invoice.discountRate}%):',
                  '-${invoice.discountAmount.toStringAsFixed(2)} €',
                  color: PdfColors.green,
                ),
              ],
              
              // TVA si applicable
              if (invoice.hasTax) ...[
                pw.SizedBox(height: 5),
                _buildTotalRow(
                  'TVA (${invoice.taxRate}%):',
                  '${invoice.taxAmount.toStringAsFixed(2)} €',
                ),
              ],
              
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 5),
              
              // Total
              _buildTotalRow(
                invoice.hasTax ? 'TOTAL TTC:' : 'TOTAL HT:',
                '${invoice.total.toStringAsFixed(2)} €',
                isBold: true,
                fontSize: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Ligne de total
  pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 10,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Notes
  pw.Widget _buildNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Notes:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            notes,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  /// Pied de page
  pw.Widget _buildFooter(InvoiceModel invoice) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'Merci pour votre confiance !',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Crée un fichier PDF temporaire
  Future<File> _getTempPdfFile(String invoiceNumber) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'invoice_${invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    return File('${tempDir.path}/$fileName');
  }
}
