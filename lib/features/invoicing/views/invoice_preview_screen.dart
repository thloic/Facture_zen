import 'package:flutter/material.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/utils/responsive_utils.dart';
import 'invoice_final_screen.dart';

/// InvoicePreviewScreen
/// Écran d'aperçu de la facture extraite du texte
/// Affiche les informations parsées (client, marchandises, montants)
class InvoicePreviewScreen extends StatelessWidget {
  final Map<String, dynamic> invoiceData;

  const InvoicePreviewScreen({
    Key? key,
    required this.invoiceData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final items = invoiceData['items'] as List<Map<String, dynamic>>? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Génération du texte',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(responsive.horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Client
                    _buildClientSection(responsive),

                    SizedBox(height: responsive.getAdaptiveSpacing(32)),

                    // En-tête du tableau
                    _buildTableHeader(responsive),

                    SizedBox(height: responsive.getAdaptiveSpacing(16)),

                    // Liste des articles
                    ...items.map((item) => _buildItemRow(item, responsive)),
                  ],
                ),
              ),
            ),

            // Bouton "Générer la facture"
            Padding(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              child: PrimaryButton(
                text: 'Générer la facture',
                onPressed: () => _showCreationModalAndGenerate(context),
                height: responsive.getAdaptiveHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget - Section informations client
  Widget _buildClientSection(ResponsiveUtils responsive) {
    final clientName = invoiceData['clientName'] ?? 'Client inconnu';
    final clientAddress = invoiceData['clientAddress'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(14),
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: responsive.getAdaptiveSpacing(8)),
        Text(
          clientName,
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(16),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5B5FC7),
          ),
        ),
        if (clientAddress.isNotEmpty) ...[
          SizedBox(height: responsive.getAdaptiveSpacing(4)),
          Text(
            clientAddress,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(14),
              color: const Color(0xFF5B5FC7),
            ),
          ),
        ],
      ],
    );
  }

  /// Widget - En-tête du tableau des marchandises
  Widget _buildTableHeader(ResponsiveUtils responsive) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Marchandises',
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(14),
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            'Qté',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(14),
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          width: 80,
          child: Text(
            'Prix Unit. (€)',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: responsive.getAdaptiveTextSize(14),
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Widget - Ligne d'article
  Widget _buildItemRow(Map<String, dynamic> item, ResponsiveUtils responsive) {
    final description = item['description'] ?? '';
    final quantity = item['quantity']?.toString() ?? '0';
    final unitPrice = item['unitPrice']?.toStringAsFixed(2) ?? '0.00';

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: responsive.getAdaptiveSpacing(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(15),
                color: const Color(0xFF1F2937),
              ),
            ),
          ),

          // Quantité
          SizedBox(
            width: 60,
            child: Text(
              quantity,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(15),
                color: const Color(0xFF1F2937),
              ),
            ),
          ),

          // Prix unitaire
          SizedBox(
            width: 80,
            child: Text(
              unitPrice,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(15),
                color: const Color(0xFF5B5FC7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche le modal de création puis navigue vers la facture finale
  Future<void> _showCreationModalAndGenerate(BuildContext context) async {
    // Afficher le modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const InvoiceCreationModal(),
    );

    // Simuler la création du PDF (3 secondes)
    await Future.delayed(const Duration(seconds: 3));

    // Fermer le modal
    if (context.mounted) {
      Navigator.of(context).pop();

      // Naviguer vers l'aperçu final de la facture
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceFinalScreen(
            invoiceData: invoiceData,
          ),
        ),
      );
    }
  }
}

/// InvoiceCreationModal
/// Modal de création de la facture PDF
class InvoiceCreationModal extends StatelessWidget {
  const InvoiceCreationModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: responsive.horizontalPadding,
        ),
        padding: EdgeInsets.all(responsive.getAdaptiveSpacing(32)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône des ondes sonores (animation)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF5B5FC7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.graphic_eq,
                color: Color(0xFF5B5FC7),
                size: 32,
              ),
            ),

            SizedBox(height: responsive.getAdaptiveSpacing(24)),

            // Titre
            Text(
              'Création de la facture',
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(18),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),

            SizedBox(height: responsive.getAdaptiveSpacing(12)),

            // Description
            Text(
              'Patientez pendant que nous mettons votre\nfacture en format PDF',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(14),
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),

            SizedBox(height: responsive.getAdaptiveSpacing(24)),

            // Bouton Annuler
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(16),
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}