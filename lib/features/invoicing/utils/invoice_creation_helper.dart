import 'package:flutter/material.dart';
import '../../../common/services/firebase_invoice_service.dart';
import '../../../common/services/firebase_notification_service.dart';
import '../../notifications/models/notification_model.dart';
import '../models/invoice_model.dart';
import '../../../common/utils/toast_utils.dart';

/// Helper pour créer des factures avec gestion automatique des messages utilisateur
class InvoiceCreationHelper {
  final FirebaseInvoiceService _invoiceService;
  final FirebaseNotificationService _notificationService;

  InvoiceCreationHelper(
    this._invoiceService, {
    FirebaseNotificationService? notificationService,
  }) : _notificationService = notificationService ?? FirebaseNotificationService();

  /// Crée une facture avec génération automatique du PDF et affichage des messages
  ///
  /// Retourne l'ID de la facture créée ou null en cas d'erreur
  Future<String?> createInvoiceWithPdf({
    required BuildContext context,
    required InvoiceModel invoice,
    bool showLoader = true,
  }) async {
    OverlayEntry? loaderOverlay;

    try {
      // 1. Afficher le loader si demandé
      if (showLoader) {
        loaderOverlay = _showLoader(context);
      }

      debugPrint('🚀 Début de la création de la facture');

      // 2. Vérifier la limite de factures
      final canCreate = await _invoiceService.canCreateInvoice();
      if (!canCreate) {
        _hideLoader(loaderOverlay);
        if (context.mounted) {
          ToastUtils.showError(
            context,
            'Limite de factures atteinte (3 max en version gratuite)',
          );
          // Rediriger vers la home après 2 secondes (toast centré)
          Future.delayed(const Duration(seconds: 2), () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            }
          });
        }
        return null;
      }

      // 3. Générer le PDF et sauvegarder la facture
      final invoiceId = await _invoiceService.saveInvoice(invoice);

      // 4. Fermer le loader
      _hideLoader(loaderOverlay);

      // 5. Créer une notification
      if (invoiceId != null) {
        await _notificationService.createNotification(
          type: NotificationType.invoiceCreated,
          title: 'Nouvelle facture créée',
          message: 'Votre facture ${invoice.invoiceNumber} a été créée avec succès',
          invoiceId: invoiceId,
          invoiceNumber: invoice.invoiceNumber,
        );
      }

      // 6. Afficher le résultat
      if (invoiceId != null && context.mounted) {
        ToastUtils.showSuccess(context, '✅ Facture créée avec succès !');
        debugPrint('✅ Facture créée : $invoiceId');
        return invoiceId;
      } else {
        if (context.mounted) {
          _showErrorToast(context, 'Erreur lors de la création de la facture');
        }
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur création facture: $e');
      debugPrint('📍 StackTrace: $stackTrace');

      // Fermer le loader
      _hideLoader(loaderOverlay);

      // Afficher l'erreur
      if (context.mounted) {
        if (e.toString().contains('LIMIT_REACHED')) {
          ToastUtils.showError(
            context,
            'Limite de factures atteinte. Passez à Premium !',
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            }
          });
        } else {
          _showErrorToast(context, 'Erreur : ${e.toString()}');
        }
      }

      return null;
    }
  }

  /// Affiche un loader en overlay
  OverlayEntry _showLoader(BuildContext context) {
    final overlay = Overlay.of(context);
    final loaderOverlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black54,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
              ),
              SizedBox(height: 16),
              Text(
                'Génération du PDF...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(loaderOverlay);
    return loaderOverlay;
  }

  /// Ferme le loader
  void _hideLoader(OverlayEntry? overlay) {
    overlay?.remove();
  }

  /// Affiche un Toast de succès (vert)
  void _showSuccessToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981), // Vert moderne
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Affiche un Toast d'erreur (rouge)
  void _showErrorToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444), // Rouge moderne
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Affiche un Toast d'avertissement (orange)
  void _showWarningToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B), // Orange
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Affiche les factures restantes si l'utilisateur est en version gratuite
  Future<void> showRemainingInvoicesIfNeeded(BuildContext context) async {
    final remaining = await _invoiceService.getRemainingInvoices();

    if (remaining > 0 && remaining <= 1 && context.mounted) {
      _showWarningToast(
        context,
        'Plus que $remaining facture(s) disponible(s) !',
      );
    }
  }
}
