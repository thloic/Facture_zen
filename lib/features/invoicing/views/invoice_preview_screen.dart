import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice_model.dart';
import '../templates/invoice_template_base.dart';
import 'template_selector_modal.dart';
import '../../../common/utils/responsive_utils.dart';
import '../services/pdf_generator_service.dart';
import 'pdf_viewer_screen.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../common/services/firebase_invoice_service.dart';
import '../utils/invoice_creation_helper.dart';
import '../viewmodels/invoice_history_viewmodel.dart';
import '../../profile/services/firebase_profile_service.dart';

/// Écran de prévisualisation de la facture avec sélection de templates
class InvoicePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> invoiceData;

  const InvoicePreviewScreen({Key? key, required this.invoiceData})
    : super(key: key);

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  InvoiceTemplateType _selectedTemplate = InvoiceTemplateType.classic;
  late InvoiceModel _invoice;
  final FirebaseProfileService _profileService = FirebaseProfileService();
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _invoice = InvoiceModel.fromMap(widget.invoiceData);
    _selectedTemplate = _invoice.templateType;
    _loadProfileAndEnrichInvoice();
  }

  /// Charge le profil utilisateur et enrichit la facture pour l'affichage
  Future<void> _loadProfileAndEnrichInvoice() async {
    try {
      debugPrint('📊 [PREVIEW] Chargement du profil pour prévisualisation...');
      final profile = await _profileService.getUserProfile();
      
      if (profile != null && mounted) {
        debugPrint('✅ [PREVIEW] Profil trouvé: ${profile.companyName ?? "Sans nom"}');
        setState(() {
          _invoice = InvoiceModel(
            id: _invoice.id,
            invoiceNumber: _invoice.invoiceNumber,
            invoiceDate: _invoice.invoiceDate,
            clientName: _invoice.clientName,
            clientAddress: _invoice.clientAddress,
            items: _invoice.items,
            notes: _invoice.notes,
            templateType: _invoice.templateType,
            companyName: profile.companyName ?? '',
            companyAddress: profile.companyAddress ?? '',
            companyPhone: profile.companyPhone ?? '',
            companyEmail: profile.companyEmail ?? '',
            companySiret: profile.companySiret ?? '',
            companyLogo: profile.companyLogo,
            taxRate: _invoice.taxRate,
            discountRate: _invoice.discountRate,
            discountLabel: _invoice.discountLabel,
          );
          _isLoadingProfile = false;
        });
        debugPrint('✅ [PREVIEW] Facture enrichie pour affichage');
      } else {
        debugPrint('⚠️ [PREVIEW] Aucun profil trouvé');
        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [PREVIEW] Erreur chargement profil: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
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
          onPreviewTap: (template) {
             // Déjà en preview, on peut juste changer la sélection
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


  /// Sauvegarde la facture dans Firebase avec génération du PDF et affichage d'un Toast
  Future<void> _saveInvoiceToFirebase() async {
    try {
      // Utiliser le helper pour créer la facture avec Toast
      final invoiceService = context.read<FirebaseInvoiceService>();
      final helper = InvoiceCreationHelper(invoiceService);

      final invoiceId = await helper.createInvoiceWithPdf(
        context: context,
        invoice: _invoice,
        showLoader: true,
      );

      if (invoiceId != null && mounted) {
        // Recharger l'historique des factures
        context.read<InvoiceHistoryViewModel>().loadInvoices();

        // Retourner à la page d'accueil après 1 seconde
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          // Retourner à la page home en supprimant toutes les routes précédentes
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde facture: $e');
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 50),
            onSelected: (value) {
              if (value == 'templates') {
                _showTemplateSelector();
              } else if (value == 'share') {
                _shareInvoice();
              } else if (value == 'save') {
                _saveInvoiceToFirebase();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    const Icon(
                      Icons.save_outlined,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Enregistrer la facture',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(enabled: false, child: Divider()),
              PopupMenuItem(
                value: 'templates',
                child: Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      color: template.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Changer de templates'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(
                      Icons.share_outlined,
                      color: Color(0xFF5B5FC7),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text('Partager'),
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
