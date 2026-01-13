import 'package:flutter/material.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/utils/responsive_utils.dart';

/// InvoiceFinalScreen
/// Écran d'aperçu final de la facture au format PDF
/// Permet de télécharger ou changer de templates
class InvoiceFinalScreen extends StatelessWidget {
  final Map<String, dynamic> invoiceData;

  const InvoiceFinalScreen({
    Key? key,
    required this.invoiceData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final items = invoiceData['items'] as List<Map<String, dynamic>>? ?? [];

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
              child: PrimaryButton(
                text: 'Télécharger la facture',
                onPressed: () => _downloadInvoice(context),
                height: responsive.getAdaptiveHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget - Logo de l'entreprise
  Widget _buildCompanyLogo(ResponsiveUtils responsive) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: responsive.getAdaptiveSpacing(12)),
        Text(
          'Stark Industries',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(20),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  /// Widget - Informations de la facture
  Widget _buildInvoiceInfo(ResponsiveUtils responsive) {
    final clientName = invoiceData['clientName'] ?? 'Client';
    final clientAddress = invoiceData['clientAddress'] ?? '';

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
            // TODO: Liste des templates disponibles
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

  /// Télécharge la facture en PDF
  void _downloadInvoice(BuildContext context) {
    // TODO: Générer et télécharger le PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Téléchargement de la facture en cours...'),
        backgroundColor: Color(0xFF5B5FC7),
      ),
    );
  }
}