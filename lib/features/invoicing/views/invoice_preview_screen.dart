import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../templates/invoice_template_base.dart';
import 'template_selector_modal.dart';
import '../../../common/utils/responsive_utils.dart';
import '../services/pdf_generator_service.dart';
import 'pdf_viewer_screen.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Écran de prévisualisation de la facture avec sélection de templates
class InvoicePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> invoiceData;

  const InvoicePreviewScreen({
    Key? key,
    required this.invoiceData,
  }) : super(key: key);

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  InvoiceTemplateType _selectedTemplate = InvoiceTemplateType.classic;
  late InvoiceModel _invoice;

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

  Future<void> _shareInvoice() async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
            ),
            SizedBox(height: 16),
            Text(
              'Préparation du partage...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );

    try {
      // Générer le PDF
      final pdfGenerator = PdfGeneratorService();
      final pdfFile = await pdfGenerator.generateInvoicePdf(_invoice);
      final pdfBytes = await pdfFile.readAsBytes();

      // Fermer le loader
      if (mounted) Navigator.pop(context);

      // Partager le PDF avec printing
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${_invoice.invoiceNumber}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF partagé avec succès !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Fermer le loader
      if (mounted) Navigator.pop(context);

      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage : $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _downloadPDF() async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
            ),
            SizedBox(height: 16),
            Text(
              'Génération du PDF...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );

    try {
      // Générer le PDF
      final pdfGenerator = PdfGeneratorService();
      final pdfFile = await pdfGenerator.generateInvoicePdf(_invoice);

      // Sauvegarder le PDF dans un dossier permanent
      final directory = await getApplicationDocumentsDirectory();
      final permanentPath = '${directory.path}/${_invoice.invoiceNumber}.pdf';
      final permanentFile = await pdfFile.copy(permanentPath);

      // Fermer le loader
      if (mounted) Navigator.pop(context);

      // Afficher un dialogue avec options
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF généré !'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Le PDF a été enregistré dans :\n$permanentPath'),
                const SizedBox(height: 16),
                const Text('Que souhaitez-vous faire ?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Partager le PDF
                  final pdfBytes = await permanentFile.readAsBytes();
                  await Printing.sharePdf(
                    bytes: pdfBytes,
                    filename: '${_invoice.invoiceNumber}.pdf',
                  );
                },
                child: const Text('Partager'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Ouvrir le viewer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(
                        pdfFile: permanentFile,
                        title: _invoice.invoiceNumber,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5FC7),
                ),
                child: const Text('Ouvrir'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Fermer le loader
      if (mounted) Navigator.pop(context);

      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération : $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
                _downloadPDF();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'templates',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, color: template.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    const Text('Changer de templates'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, color: Color(0xFF5B5FC7), size: 20),
                    SizedBox(width: 12),
                    Text('Partager'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.download_outlined, color: Color(0xFF5B5FC7), size: 20),
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