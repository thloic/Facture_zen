import 'package:flutter/material.dart';

class ToastUtils {
  static void showSuccess(BuildContext context, String message) {
    debugPrint('🎉 [TOAST] Affichage toast succès: $message');
    show(context, message: message, isError: false);
  }

  static void showError(BuildContext context, String message) {
    debugPrint('❌ [TOAST] Affichage toast erreur: $message');
    show(context, message: message, isError: true);
  }

  static void show(BuildContext context, {required String message, required bool isError}) {
    try {
      debugPrint('📍 [TOAST] Début création overlay');
      final overlay = Overlay.of(context);
      late OverlayEntry overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) {
          debugPrint('🏗️ [TOAST] Build du widget overlay');
          return Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: 40,
            right: 40,
            child: IgnorePointer(
              ignoring: true,
              child: Material(
                color: Colors.transparent,
                child: _buildToastContent(message, isError),
              ),
            ),
          );
        },
      );

      debugPrint('➕ [TOAST] Insertion dans overlay');
      overlay.insert(overlayEntry);

      // Auto-remove après 2 secondes
      Future.delayed(const Duration(seconds: 2), () {
        debugPrint('🗑️ [TOAST] Suppression du toast');
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      });
    } catch (e, stack) {
      debugPrint('❌ [TOAST] Erreur lors de l\'affichage: $e');
      debugPrint('Stack: $stack');
    }
  }

  static Widget _buildToastContent(String message, bool isError) {
    final backgroundColor = isError ? Colors.red.shade600 : Colors.green.shade600;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isError ? 'Erreur' : 'Succès',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
