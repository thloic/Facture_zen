import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../../common/widgets/curved_bottom_nav.dart';
import '../../../common/utils/toast_utils.dart'; // Ajout import
import '../viewmodels/invoice_history_viewmodel.dart';
import '../../../common/utils/responsive_utils.dart';
import '../models/invoice_model.dart';
import '../../../common/services/firebase_invoice_service.dart';
import '../../../common/services/firebase_notification_service.dart';
import '../../notifications/models/notification_model.dart';
import 'pdf_viewer_screen.dart';
import 'invoice_preview_screen.dart';
import 'template_selector_modal.dart';
import '../templates/invoice_template_base.dart';
import 'dart:io';


class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    // Charger les factures au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceHistoryViewModel>().loadInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(responsive),
      body: Consumer<InvoiceHistoryViewModel>(
        builder: (context, viewModel, child) {
          // Afficher le loader uniquement si ce n'est pas un retry
          if (viewModel.isLoading && !_isRetrying) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5B5FC7),
              ),
            );
          }

          if (viewModel.hasError) {
            return _buildErrorState(viewModel.errorMessage!, responsive);
          }

          if (viewModel.filteredInvoices.isEmpty) {
            return _buildEmptyState(responsive);
          }

          return Column(
            children: [
              // Barre de recherche et filtre
              _buildSearchAndFilter(viewModel, responsive),

              SizedBox(height: responsive.getAdaptiveSpacing(16)),

              // Liste des factures
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalPadding,
                  ),
                  itemCount: viewModel.filteredInvoices.length,
                  separatorBuilder: (context, index) => SizedBox(
                    height: responsive.getAdaptiveSpacing(12),
                  ),
                  itemBuilder: (context, index) {
                    final invoice = viewModel.filteredInvoices[index];
                    return _buildInvoiceCard(invoice, responsive);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const CurvedBottomNav(
        currentIndex: 2, // Index 2 = Historique
      ),
    );
  }

  /// Widget - AppBar personnalisée
  PreferredSizeWidget _buildAppBar(ResponsiveUtils responsive) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Historique des factures',
        style: TextStyle(
          fontSize: responsive.getAdaptiveTextSize(18),
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F2937),
        ),
      ),
      centerTitle: true,
    );
  }

  /// Widget - Barre de recherche et bouton filtre
  Widget _buildSearchAndFilter(
      InvoiceHistoryViewModel viewModel,
      ResponsiveUtils responsive,
      ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
      ),
      child: Row(
        children: [
          // Champ de recherche
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: viewModel.searchInvoices,
                decoration: InputDecoration(
                  hintText: 'Recherchez une facture',
                  hintStyle: TextStyle(
                    color: const Color(0xFF9CA3AF),
                    fontSize: responsive.getAdaptiveTextSize(14),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(14),
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
          ),

          SizedBox(width: responsive.getAdaptiveSpacing(12)),

          // Bouton filtre
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showFilterBottomSheet(context, viewModel),
                borderRadius: BorderRadius.circular(12),
                child: const Icon(
                  Icons.tune,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget - Card d'une facture
  Widget _buildInvoiceCard(dynamic invoice, ResponsiveUtils responsive) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openInvoiceDetail(invoice),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(responsive.getAdaptiveSpacing(16)),
            child: Row(
              children: [
                // Icône PDF
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFFEF4444),
                    size: 24,
                  ),
                ),

                SizedBox(width: responsive.getAdaptiveSpacing(16)),

                // Informations de la facture
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.clientName,
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(16),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: responsive.getAdaptiveSpacing(4)),
                      Text(
                        '${invoice.formattedDate} | ${invoice.total.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(13),
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu 3 points
                IconButton(
                  onPressed: () => _showInvoiceOptions(context, invoice),
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget - État vide (aucune facture)
  Widget _buildEmptyState(ResponsiveUtils responsive) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: const Color(0xFFE5E7EB),
            ),
            SizedBox(height: responsive.getAdaptiveSpacing(24)),
            Text(
              'Aucune facture',
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(18),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: responsive.getAdaptiveSpacing(8)),
            Text(
              'Commencez par créer votre première facture\nen utilisant l\'enregistrement vocal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(14),
                color: const Color(0xFF9CA3AF),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget - État d'erreur
  Widget _buildErrorState(String message, ResponsiveUtils responsive) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            SizedBox(height: responsive.getAdaptiveSpacing(24)),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(18),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: responsive.getAdaptiveSpacing(8)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(14),
                color: const Color(0xFF9CA3AF),
                height: 1.5,
              ),
            ),
            SizedBox(height: responsive.getAdaptiveSpacing(24)),
            ElevatedButton(
              onPressed: _isRetrying
                  ? null
                  : () async {
                      debugPrint('🔄 Bouton Réessayer cliqué');
                      setState(() {
                        _isRetrying = true;
                        debugPrint('🔄 _isRetrying = true');
                      });
                      
                      await context.read<InvoiceHistoryViewModel>().loadInvoices();
                      
                      if (mounted) {
                        setState(() {
                          _isRetrying = false;
                          debugPrint('🔄 _isRetrying = false');
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5FC7),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF5B5FC7).withOpacity(0.6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isRetrying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Réessayer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche le bottom sheet de filtres
  void _showFilterBottomSheet(
      BuildContext context,
      InvoiceHistoryViewModel viewModel,
      ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final responsive = ResponsiveUtils(context);
        return Padding(
          padding: EdgeInsets.all(responsive.horizontalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poignée
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Filtrer par',
                style: TextStyle(
                  fontSize: responsive.getAdaptiveTextSize(18),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: responsive.getAdaptiveSpacing(20)),
              _buildFilterOption('Date la plus récente', responsive),
              _buildFilterOption('Date la plus ancienne', responsive),
              _buildFilterOption('Nom (A-Z)', responsive),
              _buildFilterOption('Nom (Z-A)', responsive),
              SizedBox(height: responsive.getAdaptiveSpacing(20)),
            ],
          ),
        );
      },
    );
  }

  /// Widget - Option de filtre
  Widget _buildFilterOption(String label, ResponsiveUtils responsive) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        
        // Déterminer le type de filtre selon le label
        String filterType;
        switch (label) {
          case 'Date la plus récente':
            filterType = 'date_recent';
            break;
          case 'Date la plus ancienne':
            filterType = 'date_old';
            break;
          case 'Nom (A-Z)':
            filterType = 'name_asc';
            break;
          case 'Nom (Z-A)':
            filterType = 'name_desc';
            break;
          default:
            return;
        }
        
        // Appliquer le filtre via le ViewModel
        context.read<InvoiceHistoryViewModel>().filterInvoices(filterType);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: responsive.getAdaptiveSpacing(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(16),
            color: const Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }

  /// Affiche le menu d'options d'une facture
  void _showInvoiceOptions(BuildContext context, InvoiceModel invoice) {
    final responsive = ResponsiveUtils(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(responsive.horizontalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _buildMenuOption(
                icon: Icons.visibility_outlined,
                label: 'Voir la facture',
                onTap: () {
                  Navigator.pop(context);
                  _previewInvoice(invoice);
                },
                responsive: responsive,
              ),
              _buildMenuOption(
                icon: Icons.palette_outlined,
                label: 'Changer de template',
                onTap: () {
                  Navigator.pop(context);
                  _changeTemplate(invoice);
                },
                responsive: responsive,
              ),
              _buildMenuOption(
                icon: Icons.edit_outlined,
                label: 'Modifier le nom',
                onTap: () {
                  Navigator.pop(context);
                  _renameInvoice(invoice);
                },
                responsive: responsive,
              ),
              // _buildMenuOption(
              //   icon: Icons.picture_as_pdf_outlined,
              //   label: 'Voir le PDF',
              //   onTap: () {
              //     Navigator.pop(context);
              //     _downloadAndViewPdf(invoice);
              //   },
              //   responsive: responsive,
              // ),
              _buildMenuOption(
                icon: Icons.share_outlined,
                label: 'Partager',
                onTap: () {
                  Navigator.pop(context);
                  _shareInvoice(invoice);
                },
                responsive: responsive,
              ),
              _buildMenuOption(
                icon: Icons.delete_outline,
                label: 'Supprimer',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, invoice);
                },
                responsive: responsive,
              ),
              SizedBox(height: responsive.getAdaptiveSpacing(10)),
            ],
          ),
        );
      },
    );
  }

  /// Widget - Option de menu
  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ResponsiveUtils responsive,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: responsive.getAdaptiveSpacing(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : const Color(0xFF6B7280),
              size: 24,
            ),
            SizedBox(width: responsive.getAdaptiveSpacing(16)),
            Text(
              label,
              style: TextStyle(
                fontSize: responsive.getAdaptiveTextSize(16),
                color: isDestructive ? Colors.red : const Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre le détail d'une facture
  void _openInvoiceDetail(InvoiceModel invoice) {
    _previewInvoice(invoice);
  }

  /// Prévisualise la facture avec le template actuel
  void _previewInvoice(InvoiceModel invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicePreviewScreen(
          invoiceData: {
            'id': invoice.id,
            'invoiceNumber': invoice.invoiceNumber,
            'clientName': invoice.clientName,
            'clientAddress': invoice.clientAddress,
            'items': invoice.items.map((item) => {
              'description': item.description,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
            }).toList(),
            'companyName': invoice.companyName,
            'companyAddress': invoice.companyAddress,
            'companyPhone': invoice.companyPhone,
            'companyEmail': invoice.companyEmail,
            'companySiret': invoice.companySiret,
            'taxRate': invoice.taxRate,
            'discountRate': invoice.discountRate,
            'discountLabel': invoice.discountLabel,
            'notes': invoice.notes,
            'template': invoice.templateType.name,
          },
        ),
      ),
    );
  }

  /// Change le template de la facture
  void _changeTemplate(InvoiceModel invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: TemplateSelectorModal(
          currentTemplate: invoice.templateType,
          onPreviewTap: (selectedTemplate) {
            // Ouvrir la prévisualisation SANS sauvegarder
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvoicePreviewScreen(
                  invoiceData: {
                    'id': invoice.id,
                    'invoiceNumber': invoice.invoiceNumber,
                    'clientName': invoice.clientName,
                    'clientAddress': invoice.clientAddress,
                    'items': invoice.items
                        .map((item) => {
                              'description': item.description,
                              'quantity': item.quantity,
                              'unitPrice': item.unitPrice,
                            })
                        .toList(),
                    'companyName': invoice.companyName,
                    'companyAddress': invoice.companyAddress,
                    'companyPhone': invoice.companyPhone,
                    'companyEmail': invoice.companyEmail,
                    'companySiret': invoice.companySiret,
                    'taxRate': invoice.taxRate,
                    'discountRate': invoice.discountRate,
                    'discountLabel': invoice.discountLabel,
                    'notes': invoice.notes,
                    'template': selectedTemplate.name, // Utiliser le template choisi
                  },
                ),
              ),
            );
          },
          onTemplateSelected: (selectedTemplate) async {
            debugPrint('🎨 [HISTORY] Template sélectionné: ${selectedTemplate.name}');
            debugPrint('🎨 [HISTORY] InvoiceId: ${invoice.id}');
            
            // Fermer le modal d'abord
            Navigator.pop(context);

            try {
              debugPrint('💾 [HISTORY] Appel updateInvoiceTemplate...');
              
              // Sauvegarde via le ViewModel
              await context
                  .read<InvoiceHistoryViewModel>()
                  .updateInvoiceTemplate(invoice.id, selectedTemplate);

              debugPrint('✅ [HISTORY] updateInvoiceTemplate terminé');
              
              // Vérification mounted CRITIQUE
              if (!mounted) {
                debugPrint('⚠️ [HISTORY] Widget démonté, pas de toast');
                return;
              }

              debugPrint('🎉 [HISTORY] Affichage toast succès');
              // Toast Succès
              ToastUtils.showSuccess(context, "Format modifié avec succès !");

            } catch (e, stack) {
              debugPrint('❌ [HISTORY] Erreur lors de la sauvegarde: $e');
              debugPrint('❌ [HISTORY] Stack: $stack');
              
              if (!mounted) {
                debugPrint('⚠️ [HISTORY] Widget démonté, pas de toast d\'erreur');
                return;
              }
              
              // Toast Erreur
              ToastUtils.showError(context, "Impossible de modifier le format");
            }
          },
        ),
      ),
    );
  }

  /// Prévisualise la facture avec un template spécifique
  void _previewInvoiceWithTemplate(InvoiceModel invoice, InvoiceTemplateType templateType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _InvoiceTemplatePreview(
          invoice: invoice,
          initialTemplate: templateType,
        ),
      ),
    );
  }

  /// Renommer la facture
  Future<void> _renameInvoice(InvoiceModel invoice) async {
    final TextEditingController controller = TextEditingController(text: invoice.invoiceNumber);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B5FC7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF5B5FC7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Modifier le numéro',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Numéro de facture',
                  hintText: 'Ex: FAC-2026-001',
                  prefixIcon: const Icon(Icons.tag, color: Color(0xFF5B5FC7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF5B5FC7), width: 2),
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.pop(context, value.trim());
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isNotEmpty) {
                          Navigator.pop(context, value);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B5FC7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (newName != null && newName != invoice.invoiceNumber && mounted) {
      // Afficher un loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
          ),
        ),
      );

      try {
        // Mettre à jour la facture avec le nouveau nom
        final updatedInvoice = InvoiceModel(
          id: invoice.id,
          invoiceNumber: newName,
          invoiceDate: invoice.invoiceDate,
          clientName: invoice.clientName,
          clientAddress: invoice.clientAddress,
          items: invoice.items,
          notes: invoice.notes,
          companyName: invoice.companyName,
          companyAddress: invoice.companyAddress,
          companyPhone: invoice.companyPhone,
          companyEmail: invoice.companyEmail,
          companySiret: invoice.companySiret,
          companyLogo: invoice.companyLogo,
          taxRate: invoice.taxRate,
          discountRate: invoice.discountRate,
          discountLabel: invoice.discountLabel,
        );

        // Mettre à jour dans Firebase
        await context.read<FirebaseInvoiceService>().updateInvoice(updatedInvoice);
        
        // Créer une notification
        await FirebaseNotificationService().createNotification(
          type: NotificationType.invoiceUpdated,
          title: 'Facture modifiée',
          message: 'Le numéro de facture a été changé en $newName',
          invoiceId: invoice.id,
          invoiceNumber: newName,
        );

        if (mounted) {
          Navigator.pop(context); // Fermer le loader
          
          // Recharger la liste
          await context.read<InvoiceHistoryViewModel>().loadInvoices();
          
          ToastUtils.showSuccess(context, '✅ Numéro de facture modifié avec succès');
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Fermer le loader
          _showErrorSnackBar('Erreur lors de la modification: $e');
        }
      }
    }
  }

  /// Partage la facture
  Future<void> _shareInvoice(InvoiceModel invoice) async {
    try {
      final invoiceService = context.read<FirebaseInvoiceService>();
      
      // Télécharger le PDF
      final pdfFile = await invoiceService.downloadInvoicePdf(
        invoice.id,
        invoice.invoiceNumber,
      );

      if (pdfFile == null) {
        if (mounted) {
          _showErrorSnackBar('PDF non disponible');
        }
        return;
      }

      final pdfBytes = await pdfFile.readAsBytes();
      
      // Partager avec printing
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${invoice.invoiceNumber}.pdf',
      );

      if (mounted) {
        ToastUtils.showSuccess(context, '📤 Partage en cours...');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors du partage : $e');
      }
    }
  }

  /// Confirme la suppression d'une facture avec un design premium
  void _confirmDelete(BuildContext context, InvoiceModel invoice) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEF4444),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête rouge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Supprimer la facture',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Êtes-vous sûr de vouloir supprimer cette facture ?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invoice.clientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  invoice.invoiceNumber,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cette action est irréversible',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Boutons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _DeleteDialogButton(
                        onPressed: () => Navigator.pop(context),
                        text: 'Annuler',
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DeleteDialogButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          
                          // Supprimer la facture
                          await context
                              .read<InvoiceHistoryViewModel>()
                              .deleteInvoice(invoice.id);
                          
                          // Créer une notification
                          await FirebaseNotificationService().createNotification(
                            type: NotificationType.invoiceDeleted,
                            title: 'Facture supprimée',
                            message: 'La facture ${invoice.invoiceNumber} a été supprimée',
                            invoiceId: invoice.id,
                            invoiceNumber: invoice.invoiceNumber,
                          );
                          
                          if (mounted) {
                            ToastUtils.showSuccess(context, '✅ Facture supprimée avec succès');
                          }
                        },
                        text: 'Supprimer',
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Télécharge et affiche le PDF d'une facture
  Future<void> _downloadAndViewPdf(InvoiceModel invoice) async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
        ),
      ),
    );

    try {
      final invoiceService = context.read<FirebaseInvoiceService>();
      
      // Télécharger le PDF
      final pdfFile = await invoiceService.downloadInvoicePdf(
        invoice.id,
        invoice.invoiceNumber,
      );

      // Fermer le loader
      if (mounted) Navigator.pop(context);

      if (pdfFile == null) {
        // Erreur : PDF non trouvé
        if (mounted) {
          _showErrorSnackBar('PDF non disponible pour cette facture');
        }
        return;
      }

      // Vérifier que le fichier existe
      if (!await pdfFile.exists()) {
        if (mounted) {
          _showErrorSnackBar('Erreur : fichier PDF introuvable');
        }
        return;
      }

      // Ouvrir le PDF dans le viewer
      if (mounted) {
        // Afficher un Toast de succès
        ToastUtils.showSuccess(context, '📄 PDF chargé avec succès');
        
        // Petite pause pour laisser le Toast s'afficher
        await Future.delayed(const Duration(milliseconds: 300));
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              pdfFile: pdfFile,
              title: invoice.invoiceNumber,
            ),
          ),
        );
      }

    } catch (e) {
      // Fermer le loader
      if (mounted) Navigator.pop(context);
      
      // Afficher l'erreur
      if (mounted) {
        _showErrorSnackBar('Erreur lors du téléchargement : $e');
      }
    }
  }

  /// Affiche un message d'erreur
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Affiche un message de succès
  // ToastUtils.showSuccess est utilisé pour affichage centré
}

/// Widget de prévisualisation avec changement de template
class _InvoiceTemplatePreview extends StatefulWidget {
  final InvoiceModel invoice;
  final InvoiceTemplateType initialTemplate;

  const _InvoiceTemplatePreview({
    required this.invoice,
    required this.initialTemplate,
  });

  @override
  State<_InvoiceTemplatePreview> createState() => _InvoiceTemplatePreviewState();
}

class _InvoiceTemplatePreviewState extends State<_InvoiceTemplatePreview> {
  late InvoiceTemplateType _selectedTemplate;
  bool _isPremium = false;
  final FirebaseInvoiceService _invoiceService = FirebaseInvoiceService();

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.initialTemplate;
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final isPremiumUser = await _invoiceService.isPremiumUser();
    if (mounted) {
      setState(() {
        _isPremium = isPremiumUser;
      });
    }
  }

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
            setState(() {
              _selectedTemplate = template;
            });
          },
        ),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1F2937)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 50),
            onSelected: (value) {
              if (value == 'templates') {
                _showTemplateSelector();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'templates',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, color: template.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    const Text('Changer de template'),
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
              child: template.buildInvoice(context, widget.invoice, isPremium: _isPremium),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton personnalisé pour le dialogue de suppression avec effet hover
class _DeleteDialogButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isPrimary;

  const _DeleteDialogButton({
    required this.onPressed,
    required this.text,
    required this.isPrimary,
  });

  @override
  State<_DeleteDialogButton> createState() => _DeleteDialogButtonState();
}

class _DeleteDialogButtonState extends State<_DeleteDialogButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isPrimary
                ? (_isHovered ? const Color(0xFFDC2626) : const Color(0xFFEF4444))
                : (_isHovered ? Colors.grey[100] : Colors.white),
            foregroundColor: widget.isPrimary ? Colors.white : Colors.grey[700],
            elevation: _isHovered ? 4 : 0,
            shadowColor: widget.isPrimary
                ? const Color(0xFFEF4444).withOpacity(0.4)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: widget.isPrimary
                  ? BorderSide.none
                  : BorderSide(
                      color: _isHovered
                          ? Colors.grey[300]!
                          : Colors.grey[200]!,
                      width: 2,
                    ),
            ),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: widget.isPrimary ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}