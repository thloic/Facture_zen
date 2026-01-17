import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../../features/invoicing/models/invoice_model.dart';

/// Service Firebase pour la gestion des factures
/// Utilise Realtime Database + Storage pour les PDFs
class FirebaseInvoiceService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Storage optionnel (peut être null si non configuré)
  FirebaseStorage? _storage;
  bool _storageAvailable = false;
  bool _storageInitialized = false;

  /// Limite gratuite de factures
  static const int FREE_INVOICE_LIMIT = 3;

  /// Récupère l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  /// Constructeur - N'initialise PAS Storage ici
  FirebaseInvoiceService() {
    // On initialise Storage de manière synchrone
    _initializeStorageSync();
  }

  /// Initialise Storage de manière synchrone (sans test async)
  void _initializeStorageSync() {
    try {
      _storage = FirebaseStorage.instance;
      _storageAvailable = true; // On suppose que c'est OK
      debugPrint('✅ Firebase Storage initialisé');
    } catch (e) {
      _storageAvailable = false;
      debugPrint('⚠️ Firebase Storage : Erreur d\'initialisation');
      debugPrint('   Erreur : $e');
    }
  }

  /// Vérifie VRAIMENT si Storage fonctionne (appelé avant upload)
  Future<bool> _ensureStorageIsAvailable() async {
    if (_storageInitialized) {
      return _storageAvailable;
    }

    try {
      if (_storage == null) {
        _storage = FirebaseStorage.instance;
      }

      // Test réel : essayer de lister le bucket
      final ref = _storage!.ref();
      await ref.listAll();

      _storageAvailable = true;
      _storageInitialized = true;
      debugPrint('✅ Firebase Storage disponible et configuré');
      return true;

    } catch (e) {
      _storageAvailable = false;
      _storageInitialized = true;

      final errorMsg = e.toString();

      if (errorMsg.contains('storage/bucket-not-configured') ||
          errorMsg.contains('storage-bucket-missing') ||
          errorMsg.contains('bucket is not configured')) {
        debugPrint('⚠️ Firebase Storage : Bucket non configuré');
        debugPrint('💡 Solution :');
        debugPrint('   1. Allez sur Console Firebase > Storage');
        debugPrint('   2. Cliquez sur "Commencer"');
        debugPrint('   3. Choisissez les règles de sécurité');
        debugPrint('   4. Attendez que le bucket soit créé');
        debugPrint('   5. Votre bucket: gs://facturezen-558b0.firebasestorage.app');
      } else {
        debugPrint('⚠️ Firebase Storage : Erreur');
        debugPrint('   Erreur complète : $errorMsg');
      }

      return false;
    }
  }

  /// Vérifie si l'utilisateur peut créer une facture
  Future<bool> canCreateInvoice() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return false;

      // Récupérer les données utilisateur
      final userRef = _database.ref('users/$userId');
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        // Créer l'utilisateur s'il n'existe pas
        await _createUserDocument(userId);
        return true;
      }

      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      final isPremium = userData['isPremium'] as bool? ?? false;
      final invoiceCount = userData['invoiceCount'] as int? ?? 0;

      // Si premium, pas de limite
      if (isPremium) return true;

      // Sinon, vérifier la limite
      return invoiceCount < FREE_INVOICE_LIMIT;

    } catch (e) {
      debugPrint('❌ Erreur canCreateInvoice: $e');
      return false;
    }
  }

  /// Récupère le nombre de factures restantes (pour utilisateur gratuit)
  Future<int> getRemainingInvoices() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return 0;

      final userRef = _database.ref('users/$userId');
      final snapshot = await userRef.get();

      if (!snapshot.exists) return FREE_INVOICE_LIMIT;

      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      final isPremium = userData['isPremium'] as bool? ?? false;

      if (isPremium) return -1; // -1 = illimité

      final invoiceCount = userData['invoiceCount'] as int? ?? 0;
      return (FREE_INVOICE_LIMIT - invoiceCount).clamp(0, FREE_INVOICE_LIMIT);

    } catch (e) {
      debugPrint('❌ Erreur getRemainingInvoices: $e');
      return 0;
    }
  }

  /// Sauvegarde une facture dans Realtime Database
  Future<String?> saveInvoice(InvoiceModel invoice, {File? pdfFile}) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        debugPrint('❌ Utilisateur non connecté');
        return null;
      }

      // Vérifier la limite
      final canCreate = await canCreateInvoice();
      if (!canCreate) {
        debugPrint('⚠️ Limite de factures atteinte');
        throw Exception('LIMIT_REACHED');
      }

      // Créer un ID unique pour la facture
      final invoiceRef = _database.ref('invoices').push();
      final invoiceId = invoiceRef.key!;

      // Upload PDF si fourni
      String? pdfUrl;
      if (pdfFile != null) {
        // ✅ CORRECTION : Vérifier Storage AVANT l'upload
        final isAvailable = await _ensureStorageIsAvailable();

        if (isAvailable) {
          pdfUrl = await _uploadPDF(userId, invoiceId, pdfFile);
        } else {
          debugPrint('⚠️ PDF non uploadé : Storage non configuré');
        }
      }

      // Préparer les données
      final invoiceData = {
        'userId': userId,
        'invoiceNumber': invoice.invoiceNumber,
        'clientName': invoice.clientName,
        'clientAddress': invoice.clientAddress,
        'items': invoice.items.map((item) => {
          'description': item.description,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
        }).toList(),
        'subtotal': invoice.subtotal,
        'taxRate': invoice.taxRate,
        'taxAmount': invoice.taxAmount,
        'discountRate': invoice.discountRate,
        'discountAmount': invoice.discountAmount,
        'total': invoice.total,
        'companyName': invoice.companyName,
        'companyAddress': invoice.companyAddress,
        'companyPhone': invoice.companyPhone,
        'companyEmail': invoice.companyEmail,
        'companySiret': invoice.companySiret,
        'notes': invoice.notes,
        'pdfUrl': pdfUrl,
        'createdAt': ServerValue.timestamp,
      };

      // Sauvegarder dans Realtime Database
      await invoiceRef.set(invoiceData);

      // Incrémenter le compteur de factures
      await _incrementInvoiceCount(userId);

      debugPrint('✅ Facture sauvegardée dans Firebase: $invoiceId');
      if (pdfUrl != null) {
        debugPrint('📄 PDF uploadé avec succès: $pdfUrl');
      }

      return invoiceId;

    } catch (e) {
      debugPrint('❌ Erreur saveInvoice: $e');
      rethrow;
    }
  }

  /// Upload le PDF sur Firebase Storage
  Future<String?> _uploadPDF(String userId, String invoiceId, File pdfFile) async {
    try {
      debugPrint('📤 Upload PDF vers Firebase Storage...');
      debugPrint('   Bucket: gs://facturezen-558b0.firebasestorage.app');
      debugPrint('   Chemin: invoices/$userId/$invoiceId.pdf');

      // Chemin dans Storage : invoices/{userId}/{invoiceId}.pdf
      final storageRef = _storage!.ref().child('invoices/$userId/$invoiceId.pdf');

      // Upload avec metadata
      final uploadTask = await storageRef.putFile(
        pdfFile,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'invoiceId': invoiceId,
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Récupérer l'URL de téléchargement
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('✅ PDF uploadé avec succès sur Storage');
      debugPrint('   URL: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      debugPrint('❌ Erreur upload PDF: $e');
      debugPrint('   Type d\'erreur: ${e.runtimeType}');

      final errorMsg = e.toString();

      if (errorMsg.contains('storage/bucket-not-configured') ||
          errorMsg.contains('bucket is not configured')) {
        debugPrint('💡 Le bucket Storage n\'est pas configuré dans Firebase Console');
        debugPrint('   Allez sur: https://console.firebase.google.com/project/facturezen-558b0/storage');
      } else if (errorMsg.contains('permission-denied')) {
        debugPrint('💡 Problème de permissions Storage');
        debugPrint('   Vérifiez les règles dans Firebase Console > Storage > Rules');
      }

      return null;
    }
  }

  /// Récupère toutes les factures de l'utilisateur
  Future<List<InvoiceModel>> getUserInvoices() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return [];

      // Query Realtime Database
      final invoicesRef = _database.ref('invoices');
      final query = invoicesRef.orderByChild('userId').equalTo(userId);
      final snapshot = await query.get();

      if (!snapshot.exists) return [];

      final invoicesMap = Map<String, dynamic>.from(snapshot.value as Map);
      final invoices = <InvoiceModel>[];

      invoicesMap.forEach((key, value) {
        final data = Map<String, dynamic>.from(value as Map);

        invoices.add(InvoiceModel(
          id: key,
          invoiceNumber: data['invoiceNumber'] as String,
          invoiceDate: DateTime.fromMillisecondsSinceEpoch(
            data['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
          ),
          clientName: data['clientName'] as String,
          clientAddress: data['clientAddress'] as String? ?? '',
          items: (data['items'] as List<dynamic>)
              .map((item) => InvoiceItem(
            description: item['description'] as String,
            quantity: item['quantity'] as int,
            unitPrice: (item['unitPrice'] as num).toDouble(),
          ))
              .toList(),
          companyName: data['companyName'] as String,
          companyAddress: data['companyAddress'] as String,
          companyPhone: data['companyPhone'] as String?,
          companyEmail: data['companyEmail'] as String?,
          companySiret: data['companySiret'] as String?,
          taxRate: data['taxRate'] as double?,
          discountRate: data['discountRate'] as double?,
          discountLabel: data['discountLabel'] as String?,
          notes: data['notes'] as String?,
        ));
      });

      // Trier par date décroissante
      invoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

      return invoices;

    } catch (e) {
      debugPrint('❌ Erreur getUserInvoices: $e');
      return [];
    }
  }

  /// Télécharge le PDF d'une facture
  Future<String?> getInvoicePdfUrl(String invoiceId) async {
    try {
      final invoiceRef = _database.ref('invoices/$invoiceId');
      final snapshot = await invoiceRef.get();

      if (!snapshot.exists) return null;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data['pdfUrl'] as String?;

    } catch (e) {
      debugPrint('❌ Erreur getInvoicePdfUrl: $e');
      return null;
    }
  }

  /// Supprime une facture (et son PDF)
  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return false;

      // Vérifier si Storage est disponible avant de supprimer
      final isAvailable = await _ensureStorageIsAvailable();

      if (isAvailable) {
        final storageRef = _storage!.ref().child('invoices/$userId/$invoiceId.pdf');
        try {
          await storageRef.delete();
          debugPrint('🗑️ PDF supprimé du Storage');
        } catch (e) {
          debugPrint('⚠️ PDF non trouvé ou déjà supprimé');
        }
      }

      // Supprimer de la base de données
      final invoiceRef = _database.ref('invoices/$invoiceId');
      await invoiceRef.remove();

      // Décrémenter le compteur
      await _decrementInvoiceCount(userId);

      debugPrint('✅ Facture supprimée: $invoiceId');
      return true;

    } catch (e) {
      debugPrint('❌ Erreur deleteInvoice: $e');
      return false;
    }
  }

  /// Vérifie si l'utilisateur est premium
  Future<bool> isPremiumUser() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return false;

      final userRef = _database.ref('users/$userId');
      final snapshot = await userRef.get();

      if (!snapshot.exists) return false;

      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      return userData['isPremium'] as bool? ?? false;

    } catch (e) {
      debugPrint('❌ Erreur isPremiumUser: $e');
      return false;
    }
  }

  /// Crée le document utilisateur
  Future<void> _createUserDocument(String userId) async {
    final userRef = _database.ref('users/$userId');
    await userRef.set({
      'email': currentUser?.email,
      'isPremium': false,
      'invoiceCount': 0,
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Incrémente le compteur de factures
  Future<void> _incrementInvoiceCount(String userId) async {
    final userRef = _database.ref('users/$userId/invoiceCount');
    await userRef.set(ServerValue.increment(1));
  }

  /// Décrémente le compteur de factures
  Future<void> _decrementInvoiceCount(String userId) async {
    final userRef = _database.ref('users/$userId/invoiceCount');
    await userRef.set(ServerValue.increment(-1));
  }

  /// Met à jour le statut premium (pour test)
  Future<void> setPremiumStatus(bool isPremium) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    final userRef = _database.ref('users/$userId');
    await userRef.update({'isPremium': isPremium});
  }

  /// Vérifie si Storage est disponible (pour UI)
  bool get isStorageAvailable => _storageAvailable;
}