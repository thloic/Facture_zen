import 'package:flutter/material.dart';
import '../../../common/services/firebase_invoice_service.dart';
import '../models/invoice_model.dart';

/// Exemple d'utilisation du service de génération et sauvegarde de PDF
/// 
/// Ce fichier montre comment :
/// 1. Créer une facture
/// 2. Générer automatiquement le PDF
/// 3. Uploader le PDF sur Firebase Storage
/// 4. Sauvegarder les métadonnées dans Realtime Database
class InvoicePdfExample {
  final FirebaseInvoiceService _invoiceService = FirebaseInvoiceService();

  /// Exemple 1 : Sauvegarder une facture AVEC génération automatique du PDF
  /// C'est la méthode recommandée - tout est géré automatiquement
  Future<void> saveInvoiceWithAutoPdf(BuildContext context) async {
    try {
      // 1. Créer le modèle de facture
      final invoice = InvoiceModel(
        id: '', // Sera généré automatiquement
        invoiceNumber: 'FACT-2026-001',
        invoiceDate: DateTime.now(),
        clientName: 'Client Example',
        clientAddress: '123 Rue Test\n75001 Paris',
        items: [
          InvoiceItem(
            description: 'Service de consultation',
            quantity: 2,
            unitPrice: 150.0,
          ),
          InvoiceItem(
            description: 'Formation',
            quantity: 1,
            unitPrice: 500.0,
          ),
        ],
        companyName: 'Mon Entreprise',
        companyAddress: '456 Avenue Test\n75002 Paris',
        companyPhone: '+33 1 23 45 67 89',
        companyEmail: 'contact@entreprise.fr',
        companySiret: '123 456 789 00012',
        taxRate: 20.0, // TVA 20%
        discountRate: 10.0, // Réduction 10%
        discountLabel: 'Remise client fidèle',
        notes: 'Merci pour votre confiance !',
      );

      // 2. Afficher un loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
              ),
              SizedBox(height: 16),
              Text(
                'Génération et sauvegarde...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // 3. Sauvegarder avec génération automatique du PDF
      // Cette méthode :
      // - Génère le PDF
      // - L'uploade sur Firebase Storage
      // - Sauvegarde les métadonnées dans Realtime Database
      // - Nettoie le fichier temporaire
      final invoiceId = await _invoiceService.saveInvoice(invoice);

      // 4. Fermer le loader
      if (context.mounted) Navigator.pop(context);

      // 5. Vérifier le résultat
      if (invoiceId != null) {
        if (context.mounted) {
          _showSuccessMessage(context, 'Facture créée avec succès !');
        }
        debugPrint('✅ Facture sauvegardée : $invoiceId');
      } else {
        if (context.mounted) {
          _showErrorMessage(context, 'Erreur lors de la sauvegarde');
        }
      }

    } catch (e) {
      // Fermer le loader en cas d'erreur
      if (context.mounted) Navigator.pop(context);

      // Gérer les erreurs spécifiques
      if (e.toString().contains('LIMIT_REACHED')) {
        if (context.mounted) {
          _showErrorMessage(
            context,
            'Limite de factures gratuite atteinte (3 max)',
          );
        }
      } else {
        if (context.mounted) {
          _showErrorMessage(context, 'Erreur : $e');
        }
      }

      debugPrint('❌ Erreur : $e');
    }
  }

  /// Exemple 2 : Vérifier si l'utilisateur peut créer une facture
  Future<bool> checkIfCanCreateInvoice() async {
    final canCreate = await _invoiceService.canCreateInvoice();
    
    if (!canCreate) {
      debugPrint('⚠️ Limite de factures atteinte');
      // Rediriger vers l'écran d'abonnement premium
      return false;
    }
    
    return true;
  }

  /// Exemple 3 : Obtenir le nombre de factures restantes
  Future<void> displayRemainingInvoices(BuildContext context) async {
    final remaining = await _invoiceService.getRemainingInvoices();
    
    if (remaining == -1) {
      debugPrint('✨ Utilisateur Premium - Factures illimitées');
    } else {
      debugPrint('📊 Factures restantes : $remaining / 3');
      
      if (context.mounted && remaining <= 1) {
        _showWarningMessage(
          context,
          'Plus que $remaining facture(s) disponible(s) !',
        );
      }
    }
  }

  /// Exemple 4 : Télécharger et afficher un PDF existant
  Future<void> downloadAndShowPdf(
    BuildContext context,
    String invoiceId,
    String invoiceNumber,
  ) async {
    try {
      // Afficher un loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Télécharger le PDF
      final pdfFile = await _invoiceService.downloadInvoicePdf(
        invoiceId,
        invoiceNumber,
      );

      // Fermer le loader
      if (context.mounted) Navigator.pop(context);

      if (pdfFile == null) {
        if (context.mounted) {
          _showErrorMessage(context, 'PDF non disponible');
        }
        return;
      }

      // Ici, vous pouvez :
      // - Ouvrir le PDF avec un viewer (package: printing)
      // - Partager le PDF
      // - Enregistrer le PDF dans le stockage local
      debugPrint('✅ PDF téléchargé : ${pdfFile.path}');

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showErrorMessage(context, 'Erreur : $e');
      }
    }
  }

  // ============ Messages d'information ============

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
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

  void _showWarningMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
