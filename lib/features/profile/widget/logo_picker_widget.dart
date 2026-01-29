import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LogoPickerWidget extends StatelessWidget {
  final File? selectedImage;
  final String? existingLogoUrl;
  final Function(File) onImageSelected;
  final VoidCallback onImageRemoved;
  final bool isUploading;

  const LogoPickerWidget({
    Key? key,
    this.selectedImage,
    this.existingLogoUrl,
    required this.onImageSelected,
    required this.onImageRemoved,
    this.isUploading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B5FC7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image_rounded,
                  color: Color(0xFF5B5FC7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Logo de l\'entreprise',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Facultatif • Recommandé : 500x500px',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Preview du logo
          _buildLogoPreview(context),

          const SizedBox(height: 16),

          // Boutons d'action
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildLogoPreview(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 2,
        ),
      ),
      child: isUploading
          ? _buildLoadingState()
          : _buildImageContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: Color(0xFF5B5FC7),
          strokeWidth: 3,
        ),
        SizedBox(height: 12),
        Text(
          'Upload en cours...',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    // Si une nouvelle image est sélectionnée
    if (selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          selectedImage!,
          fit: BoxFit.cover,
        ),
      );
    }

    // Si un logo existe déjà (URL)
    if (existingLogoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: existingLogoUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF5B5FC7),
            ),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }

    // Placeholder si pas de logo
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Aucun logo',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final hasImage = selectedImage != null || existingLogoUrl != null;

    return Row(
      children: [
        // Bouton Galerie
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isUploading ? null : () => _pickImage(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded, size: 18),
            label: const Text('Galerie'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5B5FC7),
              side: const BorderSide(color: Color(0xFF5B5FC7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Bouton Caméra
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isUploading ? null : () => _pickImage(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text('Caméra'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5B5FC7),
              side: const BorderSide(color: Color(0xFF5B5FC7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        if (hasImage) ...[
          const SizedBox(width: 12),

          // Bouton Supprimer
          IconButton(
            onPressed: isUploading
                ? null
                : () async {
                    bool confirmed = false;
                    final overlay = Overlay.of(context);
                    late OverlayEntry overlayEntry;
                    overlayEntry = OverlayEntry(
                      builder: (context) => Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          ignoring: false,
                          child: Material(
                            color: Colors.transparent,
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 320),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.shade600.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Colors.white24,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.error_outline, color: Colors.white, size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            'Confirmer la suppression du logo ?',
                                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              overlayEntry.remove();
                                            },
                                            child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              confirmed = true;
                                              overlayEntry.remove();
                                              onImageRemoved();
                                            },
                                            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                    overlay.insert(overlayEntry);
                  },
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.red,
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        
        // Vérifier la taille du fichier
        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image trop volumineuse (max 5 MB)'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        onImageSelected(imageFile);
      }
    } catch (e) {
      debugPrint('❌ Erreur sélection image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection de l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}