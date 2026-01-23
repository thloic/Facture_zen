import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../common/services/firebase_invoice_service.dart';
import '../models/invoice_model.dart';
import '../templates/invoice_template_base.dart';
import 'template_selector_modal.dart';
import '../../../common/utils/responsive_utils.dart';

/// Écran de prévisualisation de la facture avec sélection de templates
class InvoicePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> invoiceData;
  final String? invoiceId; // Ajout de l'invoiceId

  const InvoicePreviewScreen({
    Key? key,
    required this.invoiceData,
    this.invoiceId,
  }) : super(key: key);

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  InvoiceTemplateType _selectedTemplate = InvoiceTemplateType.classic;
  late InvoiceModel _invoice;
  final FirebaseInvoiceService _invoiceService = FirebaseInvoiceService();
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _invoice = InvoiceModel.fromMap(widget.invoiceData);
  }

  /// Affiche le modal de sélection de templates
  void _showTemplateSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: TemplateSelectorModal(
          currentTemplate: _selectedTemplate,
          onTemplateSelected: (template) {
            setState(() {
              _selectedTemplate = template;
            });
          },
        ),
      ),
    );
  }

  void _shareInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage bientôt disponible'),
        backgroundColor: Color(0xFF5B5FC7),
      ),
    );
  }

  /// Télécharge la facture en PDF ET l'upload sur Firebase Storage
  Future<void> _downloadAndUploadInvoice() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      debugPrint('🚀 Démarrage: Génération + Téléchargement + Upload');

      // 1. Générer le PDF
      final pdfFile = await _generatePdfFile(_invoice);

      if (pdfFile == null) {
        throw Exception('Erreur lors de la génération du PDF');
      }

      debugPrint('✅ PDF généré: ${pdfFile.path}');

      // 2. Télécharger sur l'appareil (partage)
      final pdfBytes = await pdfFile.readAsBytes();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Facture_${_invoice.invoiceNumber}.pdf',
      );
      debugPrint('✅ PDF téléchargé sur l\'appareil $_invoice');

      // 3. Upload sur Firebase Storage (seulement si on a un invoiceId)
      if (_invoice.id != null) {
        final userId = _invoiceService.currentUser?.uid;
        if (userId != null) {
          debugPrint('📤 Upload du PDF sur Firebase Storage...');

          final pdfUrl = await _invoiceService.uploadPDF(
            userId,
            _invoice.id,
            pdfFile,
          );

          if (pdfUrl != null) {
            debugPrint('✅ PDF uploadé sur Storage: $pdfUrl');

            // 4. Mettre à jour l'URL dans la facture
            await _invoiceService.updateInvoicePdfUrl(widget.invoiceId!, pdfUrl);
            debugPrint('✅ URL du PDF mise à jour dans la facture');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Facture téléchargée et sauvegardée avec succès!'),
                  backgroundColor: Color(0xFF10B981),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } else {
            debugPrint('⚠️ Upload sur Storage échoué, mais téléchargement OK');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Facture téléchargée (sauvegarde cloud échouée)'),
                  backgroundColor: Color(0xFFF59E0B),
                ),
              );
            }
          }
        }
      } else {
        // Pas d'invoiceId, juste téléchargement local
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Facture téléchargée avec succès!'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // Nettoyer le fichier temporaire
      try {
        await pdfFile.delete();
        debugPrint('🗑️ Fichier temporaire supprimé');
      } catch (e) {
        debugPrint('⚠️ Erreur suppression fichier temporaire: $e');
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur _downloadAndUploadInvoice: $e');
      debugPrint('📍 StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  /// Génère le fichier PDF
  Future<File?> _generatePdfFile(InvoiceModel invoice) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                _buildPdfHeader(invoice),
                pw.SizedBox(height: 30),

                // Infos facture et client
                _buildPdfInvoiceInfo(invoice),
                pw.SizedBox(height: 30),

                // Tableau des articles
                _buildPdfItemsTable(invoice),
                pw.SizedBox(height: 20),

                // Totaux
                _buildPdfTotals(invoice),

                pw.Spacer(),

                // Footer
                _buildPdfFooter(invoice),
              ],
            );
          },
        ),
      );

      // Sauvegarder dans un fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      debugPrint('❌ Erreur _generatePdfFile: $e');
      return null;
    }
  }

  /// En-tête du PDF
  pw.Widget _buildPdfHeader(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              invoice.companyName,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(invoice.companyAddress, style: const pw.TextStyle(fontSize: 10)),
            if (invoice.companyPhone != null)
              pw.Text('Tél: ${invoice.companyPhone}', style: const pw.TextStyle(fontSize: 10)),
            if (invoice.companyEmail != null)
              pw.Text('Email: ${invoice.companyEmail}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue900,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'FACTURE',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// Infos facture et client
  pw.Widget _buildPdfInvoiceInfo(InvoiceModel invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('N° Facture: ${invoice.invoiceNumber}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
                'Date: ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Facturé à:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(invoice.clientName),
            if (invoice.clientAddress.isNotEmpty)
              pw.Text(invoice.clientAddress, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  /// Tableau des articles
  pw.Widget _buildPdfItemsTable(InvoiceModel invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildPdfTableCell('Description', isHeader: true),
            _buildPdfTableCell('Qté', isHeader: true),
            _buildPdfTableCell('Prix Unit.', isHeader: true),
            _buildPdfTableCell('Total', isHeader: true),
          ],
        ),
        // Articles
        ...invoice.items.map((item) => pw.TableRow(
          children: [
            _buildPdfTableCell(item.description),
            _buildPdfTableCell(item.quantity.toString()),
            _buildPdfTableCell('${item.unitPrice.toStringAsFixed(2)}€'),
            _buildPdfTableCell(
                '${(item.quantity * item.unitPrice).toStringAsFixed(2)}€'),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildPdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Totaux
  pw.Widget _buildPdfTotals(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text('Sous-total: ${invoice.subtotal.toStringAsFixed(2)}€'),
        if (invoice.taxAmount > 0)
          pw.Text(
              'TVA (${(invoice.taxRate! * 100).toStringAsFixed(0)}%): ${invoice.taxAmount.toStringAsFixed(2)}€'),
        if (invoice.discountAmount > 0)
          pw.Text('Remise: -${invoice.discountAmount.toStringAsFixed(2)}€'),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey800, width: 2),
          ),
          child: pw.Text(
            'TOTAL: ${invoice.total.toStringAsFixed(2)}€',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Footer
  pw.Widget _buildPdfFooter(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
          pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 10),
        ],
        pw.Divider(),
        pw.Text(
          'Merci pour votre confiance!',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final template = InvoiceTemplateFactory.createTemplate(_selectedTemplate);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Facture',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
        actions: [
          // Indicateur de chargement dans l'AppBar
          if (_isDownloading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
                  ),
                ),
              ),
            )
          else
          // Menu 3 points
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1F2937)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              offset: const Offset(0, 50),
              onSelected: (value) {
                if (value == 'templates') {
                  _showTemplateSelector();
                } else if (value == 'share') {
                  _shareInvoice();
                } else if (value == 'pdf') {
                  _downloadAndUploadInvoice();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'templates',
                  child: Row(
                    children: [
                      Icon(Icons.palette_outlined,
                          color: template.primaryColor, size: 20),
                      const SizedBox(width: 12),
                      const Text('Changer de templates'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined,
                          color: Color(0xFF5B5FC7), size: 20),
                      SizedBox(width: 12),
                      Text('Partager'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.download_outlined,
                          color: Color(0xFF5B5FC7), size: 20),
                      SizedBox(width: 12),
                      Text('Télécharger PDF'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: template.buildInvoice(context, _invoice),
            ),
          ),
        ),
      ),
    );
  }
}