import 'package:facture_zen/common/services/firebase_invoice_service.dart';
import 'package:flutter/material.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/utils/responsive_utils.dart';
import '../../invoicing/models/invoice_model.dart';
import 'invoice_final_screen.dart';

/// InvoicePreviewScreen
/// Aperçu de la facture générée par l'IA
/// Sauvegarde dans Firebase SANS le PDF (le PDF sera uploadé au téléchargement)
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
  final FirebaseInvoiceService _invoiceService = FirebaseInvoiceService();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final items = widget.invoiceData['items'] as List<Map<String, dynamic>>? ?? [];

    // Calcul des totaux
    double subTotal = 0;
    for (var item in items) {
      subTotal += (item['quantity'] ?? 0) * (item['unitPrice'] ?? 0.0);
    }
    final tax = subTotal * 0.02;
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
          'Aperçu Facture',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
                          _buildHeader(responsive),
                          SizedBox(height: responsive.getAdaptiveSpacing(24)),
                          _buildClientInfo(responsive),
                          SizedBox(height: responsive.getAdaptiveSpacing(24)),
                          _buildItemsTable(items, responsive),
                          SizedBox(height: responsive.getAdaptiveSpacing(24)),
                          _buildTotals(subTotal, tax, total, responsive),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(responsive.horizontalPadding),
                  child: PrimaryButton(
                    text: _isSaving ? 'Sauvegarde...' : 'Continuer',
                    onPressed: _isSaving ? null : _saveAndContinue,
                    height: responsive.getAdaptiveHeight(56),
                  ),
                ),
              ],
            ),

            if (_isSaving) _buildLoadingModal(responsive),
          ],
        ),
      ),
    );
  }

  /// ✅ Sauvegarde la facture dans Firebase SANS le PDF
  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);

    try {
      debugPrint('💾 Sauvegarde de la facture dans Firebase...');

      // Créer le modèle de facture
      final invoice = _createInvoiceModel();

      // ✅ Sauvegarder SANS le PDF (pdfFile: null)
      final invoiceId = await _invoiceService.saveInvoice(invoice);

      if (invoiceId != null) {
        debugPrint('✅ Facture sauvegardée avec ID: $invoiceId');

        // ✅ Passer l'ID de la facture à l'écran final pour l'upload ultérieur
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceFinalScreen(
                invoiceData: widget.invoiceData,
                invoiceId: invoiceId,  // ✅ Passer l'ID pour l'upload futur
              ),
            ),
          );
        }
      } else {
        throw Exception('La sauvegarde a échoué');
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la sauvegarde: $e');
      debugPrint('📍 StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  InvoiceModel _createInvoiceModel() {
    final items = widget.invoiceData['items'] as List<Map<String, dynamic>>? ?? [];

    return InvoiceModel(
      id: '',
      invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      invoiceDate: DateTime.now(),
      clientName: widget.invoiceData['clientName'] ?? 'Client',
      clientAddress: widget.invoiceData['clientAddress'] ?? '',
      items: items.map((item) {
        return InvoiceItem(
          description: item['description'] ?? '',
          quantity: item['quantity'] ?? 0,
          unitPrice: (item['unitPrice'] ?? 0.0).toDouble(),
        );
      }).toList(),
      companyName: 'Stark Industries',
      companyAddress: '765 Grove Ave, Chandler, AZ 85224',
      companyPhone: '316-395-9538',
      companyEmail: 'contact@starkindustries.com',
      companySiret: '123 456 789 00001',
      taxRate: 2.0,
      notes: 'Merci pour votre confiance !',
    );
  }

  Widget _buildLoadingModal(ResponsiveUtils responsive) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: responsive.horizontalPadding * 2,
          ),
          padding: EdgeInsets.all(responsive.getAdaptiveSpacing(32)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
              ),
              SizedBox(height: responsive.getAdaptiveSpacing(20)),
              Text(
                'Sauvegarde en cours',
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(18),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: responsive.getAdaptiveSpacing(12)),
              Text(
                'Enregistrement de votre facture...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(14),
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ResponsiveUtils responsive) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF5B5FC7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.receipt_long,
            color: Colors.white,
            size: 28,
          ),
        ),
        SizedBox(width: responsive.getAdaptiveSpacing(16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Facture',
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(20),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Text(
                'INV-${DateTime.now().millisecondsSinceEpoch}',
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

  Widget _buildClientInfo(ResponsiveUtils responsive) {
    final clientName = widget.invoiceData['clientName'] ?? 'Client';
    final clientAddress = widget.invoiceData['clientAddress'] ?? '';

    return Container(
      padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client',
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(12),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: responsive.getAdaptiveSpacing(8)),
          Text(
            clientName,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(16),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          if (clientAddress.isNotEmpty) ...[
            SizedBox(height: responsive.getAdaptiveSpacing(4)),
            Text(
              clientAddress,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(14),
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsTable(List<Map<String, dynamic>> items, ResponsiveUtils responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Articles',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(14),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(12)),
        ...items.map((item) => _buildItemRow(item, responsive)),
      ],
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item, ResponsiveUtils responsive) {
    final description = item['description'] ?? '';
    final quantity = item['quantity'] ?? 0;
    final unitPrice = item['unitPrice'] ?? 0.0;
    final total = quantity * unitPrice;

    return Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(14),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: responsive.getAdaptiveSpacing(4)),
                Text(
                  '$quantity x ${unitPrice.toStringAsFixed(2)}€',
                  style: TextStyle(
                    fontSize: responsive.getAdaptiveTextSize(12),
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${total.toStringAsFixed(2)}€',
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(16),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(double subTotal, double tax, double total, ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTotalRow('Sous-total', '${subTotal.toStringAsFixed(2)}€', false, responsive),
          SizedBox(height: responsive.getAdaptiveSpacing(8)),
          _buildTotalRow('Taxe (2%)', '${tax.toStringAsFixed(2)}€', false, responsive),
          SizedBox(height: responsive.getAdaptiveSpacing(12)),
          Container(
            padding: EdgeInsets.only(top: responsive.getAdaptiveSpacing(12)),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFD1D5DB), width: 2),
              ),
            ),
            child: _buildTotalRow('Total', '${total.toStringAsFixed(2)}€', true, responsive),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String amount, bool isBold, ResponsiveUtils responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(isBold ? 16 : 14),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF1F2937),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(isBold ? 18 : 16),
            fontWeight: FontWeight.bold,
            color: isBold ? const Color(0xFF5B5FC7) : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}