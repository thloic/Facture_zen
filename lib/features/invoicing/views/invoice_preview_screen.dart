import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../../../common/services/firebase_invoice_service.dart';
import '../models/invoice_model.dart';
import '../templates/invoice_template_base.dart';
import 'template_selector_modal.dart';
import '../../../common/utils/responsive_utils.dart';

/// Écran de prévisualisation de la facture avec sélection de templates
class InvoicePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> invoiceData;
  final String? invoiceId;

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

  // Clé globale pour capturer le widget
  final GlobalKey _invoiceKey = GlobalKey();

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

      // 1. Capturer le rendu visuel du template et générer le PDF
      final pdfFile = await _generatePdfFromTemplate();

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
      debugPrint('✅ PDF téléchargé sur l\'appareil');

      // 3. Upload sur Firebase Storage (seulement si on a un invoiceId)
      if (_invoice.id != null) {
        final userId = _invoiceService.currentUser?.uid;
        if (userId != null) {
          debugPrint('📤 Upload du PDF sur Firebase Storage...');

          final pdfUrl = await _invoiceService.uploadPDF(
            userId,
            _invoice.id!,
            pdfFile,
          );

          if (pdfUrl != null) {
            debugPrint('✅ PDF uploadé sur Storage: $pdfUrl');

            // 4. Mettre à jour l'URL dans la facture
            await _invoiceService.updateInvoicePdfUrl(_invoice.id!, pdfUrl);
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

  /// Génère le PDF à partir du template visuel affiché
  Future<File?> _generatePdfFromTemplate() async {
    try {
      debugPrint('📸 Capture du rendu du template...');

      // Attendre que le widget soit rendu
      await Future.delayed(const Duration(milliseconds: 100));

      // Récupérer le RenderRepaintBoundary
      final RenderRepaintBoundary boundary =
      _invoiceKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capturer l'image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final imageBytes = byteData!.buffer.asUint8List();

      debugPrint('✅ Image capturée: ${imageBytes.length} bytes');

      // Créer le PDF avec l'image capturée
      final pdf = pw.Document();

      final pdfImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      // Sauvegarder dans un fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/invoice_${_invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      debugPrint('✅ PDF créé à partir du template');
      return file;

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur _generatePdfFromTemplate: $e');
      debugPrint('📍 StackTrace: $stackTrace');
      return null;
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
              // ✅ RepaintBoundary pour capturer le widget
              child: RepaintBoundary(
                key: _invoiceKey,
                child: template.buildInvoice(context, _invoice),
              ),
            ),
          ),
        ),
      ),
    );
  }
}