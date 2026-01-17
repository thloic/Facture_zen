import 'package:flutter/material.dart';
import '../../../common/services/firebase_invoice_service.dart';
import '../models/invoice_model.dart';
import '../templates/invoice_template_base.dart';
import 'template_selector_modal.dart';
import '../../../common/utils/responsive_utils.dart';

/// Écran de prévisualisation de la facture avec sélection de template
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
  final FirebaseInvoiceService _invoiceService = FirebaseInvoiceService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _invoice = InvoiceModel.fromMap(widget.invoiceData);

    // 💾 Sauvegarder automatiquement dans Firebase
    _saveToFirebase();
  }

  /// Sauvegarde automatique dans Firebase
  Future<void> _saveToFirebase() async {
    try {
      final invoiceId = await _invoiceService.saveInvoice(_invoice);
      if (invoiceId != null) {
        debugPrint('✅ Facture sauvegardée dans Firebase: $invoiceId');
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde Firebase: $e');
      if (e.toString().contains('LIMIT_REACHED')) {
        // La limite a déjà été vérifiée avant, mais au cas où
        debugPrint('⚠️ Limite atteinte');
      }
    }
  }

  /// Affiche le modal de sélection de template
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

  void _downloadPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération PDF bientôt disponible'),
        backgroundColor: Color(0xFF5B5FC7),
      ),
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
          // Menu 3 points
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1F2937)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 50),
            onSelected: (value) {
              if (value == 'template') {
                _showTemplateSelector();
              } else if (value == 'share') {
                _shareInvoice();
              } else if (value == 'pdf') {
                _downloadPDF();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, color: template.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    const Text('Changer de template'),
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