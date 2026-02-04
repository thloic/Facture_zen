import 'package:facture_zen/features/invoicing/views/subscription_screen.dart';
import 'package:facture_zen/features/invoicing/views/utils/PdfTemplateGenerators.dart';
import 'package:facture_zen/features/invoicing/views/utils/pdf_template_factory.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../common/services/firebase_invoice_service.dart';
import '../models/invoice_model.dart';
import '../templates/invoice_template_base.dart';
import 'template_selector_modal.dart';
import '../../../common/utils/responsive_utils.dart';
import '../services/pdf_generator_service.dart';
import 'pdf_viewer_screen.dart';
import '../utils/invoice_creation_helper.dart';
import '../viewmodels/invoice_history_viewmodel.dart';
import '../../profile/services/firebase_profile_service.dart';

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
  final FirebaseProfileService _profileService = FirebaseProfileService(); // ✅ AJOUTÉ
  bool _isDownloading = false;
  bool _isLoadingProfile = true; // ✅ AJOUTÉ

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

  /// Sauvegarde la facture dans Firebase
  Future<void> _saveInvoiceToFirebase() async {
    try {
      debugPrint('💾 [SAVE] Début de la sauvegarde de la facture...');
      
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
                'Enregistrement en cours...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );

      // Mettre à jour le template dans les données de la facture
      final updatedInvoiceData = Map<String, dynamic>.from(widget.invoiceData);
      updatedInvoiceData['templateType'] = _selectedTemplate.name;

      String? savedInvoiceId;
      final updatedInvoice = InvoiceModel.fromMap(updatedInvoiceData);

      if (widget.invoiceId != null) {
        // Mise à jour d'une facture existante
        debugPrint('🔄 [SAVE] Mise à jour de la facture existante: ${widget.invoiceId}');
        await _invoiceService.updateInvoice(updatedInvoice);
        savedInvoiceId = widget.invoiceId;
      } else {
        // Création d'une nouvelle facture
        debugPrint('➕ [SAVE] Création d\'une nouvelle facture');
        savedInvoiceId = await _invoiceService.saveInvoice(updatedInvoice);
      }

      // Fermer le loader
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Facture enregistrée avec succès!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );

        debugPrint('✅ [SAVE] Facture sauvegardée avec ID: $savedInvoiceId');

        // Retourner à l'écran précédent après un court délai
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context, savedInvoiceId);
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [SAVE] Erreur lors de la sauvegarde: $e');
      debugPrint('📍 [SAVE] StackTrace: $stackTrace');

      // Fermer le loader
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'enregistrement: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Télécharge la facture en PDF ET l'upload sur Firebase Storage
  Future<void> _downloadAndUploadInvoice() async {
    if (_isDownloading) return;

    final canCreate = await _invoiceService.canCreateInvoice();

    if (!canCreate) {
      debugPrint('⚠️ Limite atteinte, affichage direct de l\'écran d\'abonnement');

      final remaining = await _invoiceService.getRemainingInvoices();

      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubscriptionScreen(
              remainingInvoices: remaining,
            ),
          ),
        );

        // Si abonné, réessayer
        if (result == true) {
          // Relancer la fonction
          await _downloadAndUploadInvoice();
        }
      }

      return; // ← Arrêter ici
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      debugPrint('🚀 Démarrage: Génération + Téléchargement + Upload');


      // 1. Générer le PDF optimisé selon le template
      final pdfFile = await _generateOptimizedPdf();

      if (pdfFile == null) {
        throw Exception('Erreur lors de la génération du PDF');
      }
      final invoiceId = await _invoiceService.saveInvoice(_invoice);


      debugPrint('✅ PDF généré: ${pdfFile.path}');

      // 2. Télécharger sur l'appareil (partage)
      final pdfBytes = await pdfFile.readAsBytes();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Facture_${_invoice.invoiceNumber}.pdf',
      );
      debugPrint('✅ PDF téléchargé sur l\'appareil');

      // 3. Upload sur Firebase Storage (seulement si on a un invoiceId)
      if (invoiceId != null) {
        final userId = _invoiceService.currentUser?.uid;
        if (userId != null) {
          debugPrint('📤 Upload du PDF sur Firebase Storage...');

          final pdfUrl = await _invoiceService.uploadPDF(
            userId,
            invoiceId!,
            pdfFile,
          );

          if (pdfUrl != null) {
            debugPrint('✅ PDF uploadé sur Storage: $pdfUrl');

            // 4. Mettre à jour l'URL dans la facture
            await _invoiceService.updateInvoicePdfUrl(invoiceId!, pdfUrl);
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

    }catch (e, stackTrace) {
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
  /// Génère un PDF optimisé selon le template sélectionné
  Future<File?> _generateOptimizedPdf() async {
    try {
      debugPrint('📄 Génération du PDF pour le template: ${_selectedTemplate.name}');

      final pdf = pw.Document();

      pdf.addPage(PdfTemplateFactory.generatePdf(_selectedTemplate, _invoice));

      // Sauvegarder dans un fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/invoice_${_invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      debugPrint('✅ PDF optimisé créé');
      return file;

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur _generateOptimizedPdf: $e');
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
                _downloadAndUploadInvoice();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(
                      Icons.save_outlined,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
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
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
              ),
            )
          : SingleChildScrollView(
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