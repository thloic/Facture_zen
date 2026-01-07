import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/widgets/curved_bottom_nav.dart';
import '../viewmodels/invoice_history_viewmodel.dart';
import '../../../common/utils/responsive_utils.dart';


class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

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
          if (viewModel.isLoading) {
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
                        invoice['clientName'] ?? 'Sans nom',
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(16),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: responsive.getAdaptiveSpacing(4)),
                      Text(
                        '${invoice['date']} | ${invoice['size']}',
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
              onPressed: () {
                context.read<InvoiceHistoryViewModel>().loadInvoices();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5FC7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Réessayer'),
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
              _buildFilterOption('Montant croissant', responsive),
              _buildFilterOption('Montant décroissant', responsive),
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
        // TODO: Appliquer le filtre
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
  void _showInvoiceOptions(BuildContext context, dynamic invoice) {
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
                  _openInvoiceDetail(invoice);
                },
                responsive: responsive,
              ),
              _buildMenuOption(
                icon: Icons.share_outlined,
                label: 'Partager',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Partager la facture
                },
                responsive: responsive,
              ),
              _buildMenuOption(
                icon: Icons.download_outlined,
                label: 'Télécharger',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Télécharger la facture
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
  void _openInvoiceDetail(dynamic invoice) {
    // TODO: Navigation vers l'écran de détail
    // NavigationHelper.navigateWithArguments(
    //   context,
    //   AppRoutes.invoiceDetail,
    //   invoice['id'],
    // );
  }

  /// Confirme la suppression d'une facture
  void _confirmDelete(BuildContext context, dynamic invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la facture'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette facture ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<InvoiceHistoryViewModel>()
                  .deleteInvoice(invoice['id']);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}