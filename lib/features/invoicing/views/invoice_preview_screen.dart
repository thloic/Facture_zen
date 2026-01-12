import 'package:flutter/material.dart';
import '../template/invoice_model.dart';
import '../template/invoice_template_base.dart';
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
  // Template actuellement sélectionné
  InvoiceTemplateType _selectedTemplate = InvoiceTemplateType.classic;

  late InvoiceModel _invoice;

  @override
  void initState() {
    super.initState();
    // Convertir les données en modèle
    _invoice = InvoiceModel.fromMap(widget.invoiceData);
  }

  /// Affiche le modal de sélection de template
  void _showTemplateSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
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

  /// Partage la facture (TODO: implémenter avec share_plus)
  void _shareInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage bientôt disponible'),
        backgroundColor: Color(0xFF5B5FC7),
      ),
    );
  }

  /// Télécharge la facture en PDF (TODO: implémenter avec pdf package)
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Aperçu de la facture',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
        actions: [
          // Bouton info template actuel
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: template.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  template.icon,
                  size: 16,
                  color: template.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  template.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: template.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone de prévisualisation
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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

          // Barre d'actions avec les 3 boutons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Bouton 1: Changer de template
                Expanded(
                  child: _ActionButton(
                    icon: Icons.palette_outlined,
                    label: 'Template',
                    onPressed: _showTemplateSelector,
                    backgroundColor: const Color(0xFF5B5FC7),
                    textColor: Colors.white,
                  ),
                ),

                const SizedBox(width: 12),

                // Bouton 2: Partager
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'Partager',
                    onPressed: _shareInvoice,
                    backgroundColor: Colors.white,
                    textColor: const Color(0xFF5B5FC7),
                    hasBorder: true,
                  ),
                ),

                const SizedBox(width: 12),

                // Bouton 3: Télécharger PDF
                Expanded(
                  child: _ActionButton(
                    icon: Icons.download_outlined,
                    label: 'PDF',
                    onPressed: _downloadPDF,
                    backgroundColor: Colors.white,
                    textColor: const Color(0xFF5B5FC7),
                    hasBorder: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de bouton d'action personnalisé
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final bool hasBorder;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: hasBorder
                ? Border.all(color: const Color(0xFF5B5FC7), width: 2)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}