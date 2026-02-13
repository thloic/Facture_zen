import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import '../../../common/services/firebase_invoice_service.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/utils/responsive_utils.dart';
import '../models/invoice_model.dart';
import '../../profile/services/firebase_profile_service.dart';
import '../../profile/models/user_profile_model.dart';
import 'subscription_screen.dart';

/// InvoiceFinalScreen
/// Écran d'aperçu final de la facture au format PDF
/// Permet de télécharger ou changer de templates
class InvoiceFinalScreen extends StatefulWidget {
  final Map<String, dynamic> invoiceData;
  final String invoiceId;

  const InvoiceFinalScreen({
    Key? key,
    required this.invoiceData,
    required this.invoiceId,
  }) : super(key: key);

  @override
  State<InvoiceFinalScreen> createState() => _InvoiceFinalScreenState();
}

class _InvoiceFinalScreenState extends State<InvoiceFinalScreen> {
  final FirebaseInvoiceService _invoiceService = FirebaseInvoiceService();
  final FirebaseProfileService _profileService = FirebaseProfileService();
  bool _isDownloading = false;
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;
  Uint8List? _logoBytes; // Cache des bytes du logo pour le PDF
  bool _isPremium = false; // Statut premium de l'utilisateur

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Charge le profil utilisateur pour récupérer le logo
  Future<void> _loadUserProfile() async {
    try {
      // Vérifier le statut premium
      final remainingInvoices = await _invoiceService.getRemainingInvoices();
      _isPremium = remainingInvoices == -1; // -1 = illimité = premium
      
      final profile = await _profileService.getUserProfile();
      
      // Précharger les bytes du logo pour le PDF
      if (profile?.companyLogo != null && profile!.companyLogo!.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(profile.companyLogo!));
          if (response.statusCode == 200) {
            _logoBytes = response.bodyBytes;
            debugPrint('✅ Logo préchargé: ${_logoBytes!.length} bytes');
          }
        } catch (e) {
          debugPrint('⚠️ Erreur préchargement logo: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement profil: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final items = widget.invoiceData['items'] as List<Map<String, dynamic>>? ?? [];

    // Calcul des totaux
    double subTotal = 0;
    for (var item in items) {
      subTotal += (item['quantity'] ?? 0) * (item['unitPrice'] ?? 0.0);
    }
    final tax = subTotal * 0.02; // 2% de taxe
    final total = subTotal + tax;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1F2937)),
            onPressed: () => _showTemplateOptions(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(responsive.horizontalPadding),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(responsive.getAdaptiveSpacing(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo entreprise
                      _buildCompanyLogo(responsive),

                      SizedBox(height: responsive.getAdaptiveSpacing(32)),

                      // Informations facture
                      _buildInvoiceInfo(responsive),

                      SizedBox(height: responsive.getAdaptiveSpacing(32)),

                      // Tableau des articles
                      _buildItemsTable(items, responsive),

                      SizedBox(height: responsive.getAdaptiveSpacing(24)),

                      // Totaux
                      _buildTotals(subTotal, tax, total, responsive),

                      SizedBox(height: responsive.getAdaptiveSpacing(32)),

                      // Contact et Manager
                      _buildFooterInfo(responsive),
                    ],
                  ),
                ),
              ),
            ),

            // Bouton télécharger
            Padding(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              child: _isDownloading
                  ? Container(
                height: responsive.getAdaptiveHeight(56),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B5FC7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
                  : PrimaryButton(
                text: 'Télécharger la facture',
                onPressed: () => _downloadAndUploadInvoice(context),
                height: responsive.getAdaptiveHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Télécharge la facture en PDF ET l'upload sur Firebase Storage
  Future<void> _downloadAndUploadInvoice(BuildContext context) async {
    // ✅ VÉRIFICATION LIMITE AVANT GÉNÉRATION
    final canCreate = await _invoiceService.canCreateInvoice();
    final remainingInvoices = await _invoiceService.getRemainingInvoices();
    
    if (!canCreate) {
      // Limite atteinte → Afficher le paywall
      debugPrint('⚠️ Limite de factures atteinte ($remainingInvoices restantes)');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubscriptionScreen(remainingInvoices: remainingInvoices),
          ),
        );
      }
      return; // ❌ Ne pas générer le PDF
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      debugPrint('🚀 Démarrage: Génération + Téléchargement + Upload');

      // 1. Générer le PDF
      final invoice = InvoiceModel.fromMap(widget.invoiceData);
      final pdfFile = await _generatePdfFile(invoice);

      if (pdfFile == null) {
        throw Exception('Erreur lors de la génération du PDF');
      }

      debugPrint('✅ PDF généré: ${pdfFile.path}');

      // 2. Télécharger sur l'appareil (partage)
      final pdfBytes = await pdfFile.readAsBytes();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Facture_${invoice.invoiceNumber}.pdf',
      );
      debugPrint('✅ PDF téléchargé sur l\'appareil');

      // 3. Upload sur Firebase Storage
      final userId = _invoiceService.currentUser?.uid;
      if (userId != null) {
        debugPrint('📤 Upload du PDF sur Firebase Storage...');

        final pdfUrl = await _invoiceService.uploadPDF(
          userId,
          widget.invoiceId,
          pdfFile,
        );

        if (pdfUrl != null) {
          debugPrint('✅ PDF uploadé sur Storage: $pdfUrl');

          // 4. Mettre à jour l'URL dans la facture
          await _invoiceService.updateInvoicePdfUrl(widget.invoiceId, pdfUrl);
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

      // Utiliser les bytes du logo préchargés
      pw.MemoryImage? logoImage;
      if (_logoBytes != null) {
        try {
          logoImage = pw.MemoryImage(_logoBytes!);
          debugPrint('✅ Logo ajouté au PDF');
        } catch (e) {
          debugPrint('⚠️ Erreur création image logo: $e');
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête avec logo
                _buildPdfHeader(invoice, logoImage),
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

  /// En-tête du PDF avec logo
  pw.Widget _buildPdfHeader(InvoiceModel invoice, pw.MemoryImage? logoImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo + Infos entreprise
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo de l'entreprise
            if (logoImage != null)
              pw.Container(
                width: 60,
                height: 60,
                margin: const pw.EdgeInsets.only(right: 15),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              )
            else
              pw.Container(
                width: 60,
                height: 60,
                margin: const pw.EdgeInsets.only(right: 15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    invoice.companyName.isNotEmpty ? invoice.companyName[0].toUpperCase() : 'E',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
            // Infos entreprise
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
          ],
        ),
        // Badge FACTURE
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
            pw.Text('Date: ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}'),
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
            _buildPdfTableCell('${item.unitPrice.toStringAsFixed(2)} EUR'),
            _buildPdfTableCell('${(item.quantity * item.unitPrice).toStringAsFixed(2)} EUR'),
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
        pw.Text('Sous-total: ${invoice.subtotal.toStringAsFixed(2)} EUR'),
        if (invoice.taxAmount > 0)
          pw.Text('TVA (${(invoice.taxRate! * 100).toStringAsFixed(0)}%): ${invoice.taxAmount.toStringAsFixed(2)} EUR'),
        if (invoice.discountAmount > 0)
          pw.Text('Remise: -${invoice.discountAmount.toStringAsFixed(2)} EUR'),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey800, width: 2),
          ),
          child: pw.Text(
            'TOTAL: ${invoice.total.toStringAsFixed(2)} EUR',
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
        // Signature VoxIn pour utilisateurs gratuits
        if (!_isPremium)
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(20),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'Genere avec ',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'VoxIn',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Widget - Logo de l'entreprise
  Widget _buildCompanyLogo(ResponsiveUtils responsive) {
    final logoUrl = _userProfile?.companyLogo;
    final companyName = _userProfile?.companyName ?? 
                        widget.invoiceData['companyName'] ?? 
                        'Mon Entreprise';
    final companyInitial = companyName.isNotEmpty 
        ? companyName[0].toUpperCase() 
        : 'E';

    return Row(
      children: [
        // Logo ou placeholder
        if (_isLoadingProfile)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (logoUrl != null && logoUrl.isNotEmpty)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                logoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('⚠️ Erreur chargement logo: $error');
                  return Container(
                    color: const Color(0xFF5B5FC7),
                    child: Center(
                      child: Text(
                        companyInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        else
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF5B5FC7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                companyInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        SizedBox(width: responsive.getAdaptiveSpacing(12)),
        Expanded(
          child: Text(
            companyName,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(20),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Widget - Informations de la facture
  Widget _buildInvoiceInfo(ResponsiveUtils responsive) {
    final clientName = widget.invoiceData['clientName'] ?? 'Client';
    final clientAddress = widget.invoiceData['clientAddress'] ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Partie gauche - Info facture
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Facture',
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(16),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: responsive.getAdaptiveSpacing(8)),
              _buildInfoRow('No Facture :', '09-0639', responsive),
              _buildInfoRow('Date :', '22/04/2023', responsive),
            ],
          ),
        ),

        // Partie droite - Info client
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Facture à :',
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(12),
                  color: const Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: responsive.getAdaptiveSpacing(4)),
              Text(
                clientName,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(14),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              if (clientAddress.isNotEmpty) ...[
                SizedBox(height: responsive.getAdaptiveSpacing(4)),
                Text(
                  clientAddress,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(12),
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
              SizedBox(height: responsive.getAdaptiveSpacing(4)),
              Text(
                '214-625-8894',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(12),
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget - Ligne d'information
  Widget _buildInfoRow(String label, String value, ResponsiveUtils responsive) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.getAdaptiveSpacing(4)),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(12),
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(width: responsive.getAdaptiveSpacing(8)),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(12),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget - Tableau des articles
  Widget _buildItemsTable(List<Map<String, dynamic>> items, ResponsiveUtils responsive) {
    return Column(
      children: [
        // En-tête
        Container(
          padding: EdgeInsets.symmetric(
            vertical: responsive.getAdaptiveSpacing(12),
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Description',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(12),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  'Qté',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(12),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'Prix Unit',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(12),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'Sub Total',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(12),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Articles
        ...items.map((item) => _buildItemTableRow(item, responsive)),
      ],
    );
  }

  /// Widget - Ligne d'article dans le tableau
  Widget _buildItemTableRow(Map<String, dynamic> item, ResponsiveUtils responsive) {
    final description = item['description'] ?? '';
    final quantity = item['quantity'] ?? 0;
    final unitPrice = item['unitPrice'] ?? 0.0;
    final subTotal = quantity * unitPrice;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: responsive.getAdaptiveSpacing(12),
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(13),
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(13),
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '${unitPrice.toStringAsFixed(2)}€',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(13),
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '${subTotal.toStringAsFixed(2)}€',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(13),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget - Section des totaux
  Widget _buildTotals(double subTotal, double tax, double total, ResponsiveUtils responsive) {
    return Column(
      children: [
        _buildTotalRow('Sub Total:', '${subTotal.toStringAsFixed(2)}€', false, responsive),
        SizedBox(height: responsive.getAdaptiveSpacing(8)),
        _buildTotalRow('Tax', '${tax.toStringAsFixed(2)}€', false, responsive),
        SizedBox(height: responsive.getAdaptiveSpacing(12)),
        Container(
          padding: EdgeInsets.symmetric(
            vertical: responsive.getAdaptiveSpacing(12),
          ),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFE5E7EB), width: 2),
            ),
          ),
          child: _buildTotalRow('Total     :', '${total.toStringAsFixed(2)}€', true, responsive),
        ),
      ],
    );
  }

  /// Widget - Ligne de total
  Widget _buildTotalRow(String label, String amount, bool isBold, ResponsiveUtils responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(isBold ? 16 : 14),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(width: responsive.getAdaptiveSpacing(16)),
        Text(
          amount,
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(isBold ? 18 : 14),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  /// Widget - Informations de pied de page
  Widget _buildFooterInfo(ResponsiveUtils responsive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contact Us
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(14),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: responsive.getAdaptiveSpacing(8)),
              _buildContactInfo(Icons.location_on_outlined, '765 Grove Ave,\nChandler, AZ 85224', responsive),
              SizedBox(height: responsive.getAdaptiveSpacing(4)),
              _buildContactInfo(Icons.email_outlined, 'contact@gmail.com', responsive),
              SizedBox(height: responsive.getAdaptiveSpacing(4)),
              _buildContactInfo(Icons.phone_outlined, '316-395-9538', responsive),
            ],
          ),
        ),

        // Manager
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Maxine Watson',
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(14),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: responsive.getAdaptiveSpacing(4)),
            Text(
              'Manager',
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(12),
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Widget - Ligne d'information de contact
  Widget _buildContactInfo(IconData icon, String text, ResponsiveUtils responsive) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        SizedBox(width: responsive.getAdaptiveSpacing(8)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(12),
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  /// Affiche les options de templates
  void _showTemplateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Afficher d\'autres formats de factures',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Fonctionnalité à venir',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}