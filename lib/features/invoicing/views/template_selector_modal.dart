import 'package:flutter/material.dart';
import '../services/subscription_sync_service.dart';
import '../templates/invoice_template_base.dart';

/// Modal de sélection de template avec défilement horizontal
class TemplateSelectorModal extends StatefulWidget {
  final InvoiceTemplateType currentTemplate;
  final Function(InvoiceTemplateType) onTemplateSelected;
  final Function(InvoiceTemplateType) onPreviewTap;

  const TemplateSelectorModal({
    Key? key,
    required this.currentTemplate,
    required this.onTemplateSelected,
    required this.onPreviewTap,
  }) : super(key: key);

  @override
  State<TemplateSelectorModal> createState() => _TemplateSelectorModalState();
}

class _TemplateSelectorModalState extends State<TemplateSelectorModal> {
  late InvoiceTemplateType _viewedTemplate;
  late PageController _pageController;
  final SubscriptionSyncService _syncService = SubscriptionSyncService();
  List<InvoiceTemplateType> _accessibleTemplates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _viewedTemplate = widget.currentTemplate;
    final initialIndex = InvoiceTemplateType.values.indexOf(widget.currentTemplate);
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: initialIndex,
    );
    _loadAccessibleTemplates();
  }

  Future<void> _loadAccessibleTemplates() async {
    try {
      final templates = await _syncService.getAccessibleTemplates();
      if (mounted) {
        setState(() {
          _accessibleTemplates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading accessible templates: $e');
      if (mounted) {
        setState(() {
          _accessibleTemplates = InvoiceTemplateType.values.take(2).toList();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// ✅ Vérifier si un template est accessible
  bool _isTemplateAccessible(InvoiceTemplateType templateType) {
    return _accessibleTemplates.contains(templateType);
  }

  /// ✅ Afficher le dialog de mise à niveau
  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Template Premium',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'Ce template nécessite un abonnement Premium.\n\nPassez à un plan supérieur pour débloquer tous les templates !',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              Navigator.pop(context); // Fermer le modal
               Navigator.pushNamed(context, '/subscription-screen');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B5FC7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Voir les offres',style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = InvoiceTemplateFactory.getAllTemplates();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.palette, color: Color(0xFF5B5FC7), size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Afficher d\'autres formats',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Loader pendant le chargement
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5B5FC7),
                ),
              ),
            )
          else
          // Défilement horizontal des templates
            Expanded(
              child: PageView.builder(
                itemCount: templates.length,
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _viewedTemplate = InvoiceTemplateType.values[index];
                  });
                },
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final templateType = InvoiceTemplateType.values[index];
                  final isSelected = templateType == _viewedTemplate;
                  final isAccessible = _isTemplateAccessible(templateType); // ✅ NOUVEAU

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: _TemplateCard(
                      template: template,
                      isSelected: isSelected,
                      isAccessible: isAccessible, // ✅ NOUVEAU
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  );
                },
              ),
            ),

          // Bouton de sélection
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Bouton "Voir"
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                        // ✅ Vérifier l'accès avant la prévisualisation
                        if (_isTemplateAccessible(_viewedTemplate)) {
                          Navigator.pop(context);
                          widget.onPreviewTap(_viewedTemplate);
                        } else {
                          _showUpgradeDialog(context);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B5FC7),
                        side: const BorderSide(color: Color(0xFF5B5FC7), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text(
                        'Voir',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Bouton "Enregistrer"
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                        // ✅ Vérifier l'accès avant la sélection
                        if (_isTemplateAccessible(_viewedTemplate)) {
                          widget.onTemplateSelected(_viewedTemplate);
                        } else {
                          _showUpgradeDialog(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B5FC7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Enregistrer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
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

/// Widget de carte de template
class _TemplateCard extends StatelessWidget {
  final InvoiceTemplate template;
  final bool isSelected;
  final bool isAccessible; // ✅ NOUVEAU
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.isAccessible, // ✅ NOUVEAU
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack( // ✅ MODIFIÉ : Wrapped dans Stack pour l'overlay
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? template.primaryColor : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? template.primaryColor.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isSelected ? 20 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Badge sélectionné
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: template.primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Sélectionné',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Aperçu miniature (taille fixe)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: template.buildThumbnail(context),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Informations du template
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: template.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          template.icon,
                          size: 18,
                          color: template.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              template.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              template.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ✅ NOUVEAU : Badge Premium en haut à droite si non accessible
          if (!isAccessible)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ✅ NOUVEAU : Overlay grisé si non accessible
          if (!isAccessible)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: Color(0xFFFFD700),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Passer à Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}