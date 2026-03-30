import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../../features/invoicing/models/invoice_model.dart';
import 'tracking_service.dart';

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
  /// Nouveau : compteur global jamais décrémenté
  static const String TOTAL_INVOICES_CREATED_KEY = 'totalInvoicesCreated'; // garder pour historique
  static String get _monthlyCountKey {
    final now = DateTime.now();
    return 'invoiceCount_${now.year}_${now.month}'; // ex: invoiceCount_2026_3
  }

  /// Récupère l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  /// Constructeur - N'initialise PAS Storage ici
  FirebaseInvoiceService() {
    // On initialise Storage de manière synchrone
    _initializeStorageSync();
  }

  Future<void> updateInvoiceTemplate(String invoiceId, String templateName) async {
    try {
      debugPrint('🎨 Mise à jour du template pour la facture $invoiceId: $templateName');

      await _database
          .ref('invoices/$invoiceId')
          .update({'template': templateName});

      debugPrint('✅ Template mis à jour avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du template: $e');
      rethrow;
    }
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

  Future<File?> downloadInvoicePdf(
      String invoiceId,
      String invoiceNumber,
      ) async {
    try {
      debugPrint('📥 Téléchargement du PDF pour la facture: $invoiceNumber');

      final userId = currentUser?.uid;
      if (userId == null) {
        debugPrint('❌ Utilisateur non connecté');
        return null;
      }

      // Vérifier Storage
      final isAvailable = await _ensureStorageIsAvailable();
      if (!isAvailable) {
        debugPrint('❌ Firebase Storage non disponible');
        return null;
      }

      // Référence du fichier dans Storage
      final storagePath = 'invoices/$userId/$invoiceId.pdf';
      final storageRef = _storage!.ref().child(storagePath);

      // Créer un fichier local temporaire
      final tempDir = await Directory.systemTemp.createTemp('invoice_pdf_');
      final localFile = File('${tempDir.path}/$invoiceNumber.pdf');

      debugPrint('📥 Téléchargement depuis: $storagePath');
      debugPrint('💾 Sauvegarde locale: ${localFile.path}');

      // Télécharger le fichier
      await storageRef.writeToFile(localFile);

      final fileSize = await localFile.length();
      debugPrint('✅ PDF téléchargé avec succès ($fileSize bytes)');

      return localFile;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur downloadInvoicePdf: $e');
      debugPrint('📍 StackTrace: $stackTrace');
      return null;
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

      final userRef = _database.ref('users/$userId');
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        await _createUserDocument(userId);
        return true;
      }

      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      final isPremium = userData['isPremium'] as bool? ?? false;
      // Limite du plan (Firebase mis à jour par syncSubscriptionStatus)
      final monthlyLimit = userData['monthlyInvoiceLimit'] as int? ?? FREE_INVOICE_LIMIT;
      // ✅ Compteur MENSUEL — se remet à zéro chaque mois automatiquement
      final monthlyCount = userData[_monthlyCountKey] as int? ?? 0;

      if (isPremium) {
        final canCreate = monthlyCount < monthlyLimit;
        debugPrint('🔒 Premium check: $monthlyCount/$monthlyLimit factures ce mois');
        return canCreate;
      }

      // Plan gratuit
      final canCreate = monthlyCount < FREE_INVOICE_LIMIT;
      debugPrint('🔒 Free check: $monthlyCount/$FREE_INVOICE_LIMIT factures ce mois');
      return canCreate;

    } catch (e) {
      debugPrint('❌ Erreur canCreateInvoice: $e');
      return false;
    }
  }

  Future<int> getUserInvoiceLimit() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return FREE_INVOICE_LIMIT;

      final userRef = _database.ref('users/$userId');
      final snapshot = await userRef.get();

      if (!snapshot.exists) return FREE_INVOICE_LIMIT;

      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      return userData['monthlyInvoiceLimit'] as int? ?? FREE_INVOICE_LIMIT;

    } catch (e) {
      debugPrint('❌ Error getting user limit: $e');
      return FREE_INVOICE_LIMIT;
    }
  }
  /// ✅ NOUVEAU : Mettre à jour le plan utilisateur
  Future<void> updateUserPlan({
    required bool isPremium,
    required int monthlyInvoiceLimit,
    required String planName,
    required int allowedTemplatesCount, // ✅ NOUVEAU
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return;

      final userRef = _database.ref('users/$userId');

      await userRef.update({
        'isPremium': isPremium,
        'monthlyInvoiceLimit': monthlyInvoiceLimit,
        'planName': planName,
        'allowedTemplatesCount': allowedTemplatesCount, // ✅ NOUVEAU
        'lastUpdated': ServerValue.timestamp,
      });

      debugPrint('✅ User plan updated in Firebase');
      debugPrint('   Plan: $planName');
      debugPrint('   Invoices limit: $monthlyInvoiceLimit/month');
      debugPrint('   Templates limit: ${allowedTemplatesCount == -1 ? "Unlimited" : allowedTemplatesCount}');

    } catch (e) {
      debugPrint('❌ Error updating user plan: $e');
      rethrow;
    }
  }

  Future<int> getUserTemplatesLimit() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return 2; // Par défaut : plan gratuit

      final userRef = _database.ref('users/$userId');
      final snapshot = await userRef.get();

      if (!snapshot.exists) return 2;

      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      return userData['allowedTemplatesCount'] as int? ?? 2;

    } catch (e) {
      debugPrint('❌ Error getting templates limit: $e');
      return 2;
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
      final monthlyCount = userData[_monthlyCountKey] as int? ?? 0;

      if (isPremium) {
        final monthlyLimit = userData['monthlyInvoiceLimit'] as int? ?? FREE_INVOICE_LIMIT;
        return (monthlyLimit - monthlyCount).clamp(0, monthlyLimit);
      }

      return (FREE_INVOICE_LIMIT - monthlyCount).clamp(0, FREE_INVOICE_LIMIT);

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

      debugPrint('📋 saveInvoice appelé pour: ${invoice.clientName}');
      debugPrint('   UserId: $userId');
      debugPrint('   PDF fourni: ${pdfFile != null ? 'OUI' : 'NON'}');

      // Vérifier la limite
      final canCreate = await canCreateInvoice();
      if (!canCreate) {
        debugPrint('⚠️ Limite de factures atteinte');
        throw Exception('LIMIT_REACHED');
      }

      // Créer un ID unique pour la facture
      final invoiceRef = _database.ref('invoices').push();
      final invoiceId = invoiceRef.key!;
      debugPrint('🆔 ID de facture généré: $invoiceId');

      // Upload PDF si fourni
      String? pdfUrl;
      if (pdfFile != null) {
        debugPrint('📤 Tentative d\'upload du PDF...');

        // ✅ CRITIQUE : Vérifier que le fichier existe avant l'upload
        if (!await pdfFile.exists()) {
          debugPrint('❌ ERREUR : Le fichier PDF n\'existe pas: ${pdfFile.path}');
          throw Exception('Le fichier PDF n\'existe pas');
        }

        final fileSize = await pdfFile.length();
        debugPrint('   Taille du fichier: $fileSize bytes');

        if (fileSize == 0) {
          debugPrint('❌ ERREUR : Le fichier PDF est vide');
          throw Exception('Le fichier PDF est vide');
        }

        // Vérifier Storage AVANT l'upload
        final isAvailable = await _ensureStorageIsAvailable();

        if (isAvailable) {
          debugPrint('✅ Storage disponible, démarrage upload...');
          pdfUrl = await uploadPDF(userId, invoiceId, pdfFile);

          if (pdfUrl != null) {
            debugPrint('✅ PDF uploadé avec succès!');
            debugPrint('   URL: $pdfUrl');
          } else {
            debugPrint('⚠️ L\'upload a retourné null');
          }
        } else {
          debugPrint('❌ Storage non configuré, PDF non uploadé');
        }
      } else {
        debugPrint('ℹ️ Aucun fichier PDF fourni');
      }

      // Préparer les données
      debugPrint('💾 Sauvegarde des métadonnées dans Realtime Database...');
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
        'pdfUrl': pdfUrl,  // ✅ Peut être null si Storage non configuré
        'createdAt': ServerValue.timestamp,
      };

      // Sauvegarder dans Realtime Database
      await invoiceRef.set(invoiceData);
      debugPrint('✅ Métadonnées sauvegardées dans Realtime Database');

      // ✅ NOUVEAU : Créer une référence dans le profil utilisateur
      final userInvoiceRef = _database.ref('users/$userId/invoices/$invoiceId');
      await userInvoiceRef.set(true); // Juste une référence booléenne
      debugPrint('✅ Référence ajoutée dans le profil utilisateur');

      // Incrémenter le compteur de factures
      await _incrementInvoiceCount(userId);
      debugPrint('✅ Compteur de factures incrémenté');

      await _incrementTotalInvoicesCreated(userId);
      debugPrint('✅ Compteur de factures incrémenté');

      // 📊 Tracker la création de facture (Google Ads + Facebook Ads)
      await TrackingService().logCreateInvoice(
        amount: invoice.total,
        currency: 'EUR',
      );

      debugPrint('✅ Facture sauvegardée avec succès: $invoiceId');
      if (pdfUrl != null) {
        debugPrint('📄 PDF URL: $pdfUrl');
      } else {
        debugPrint('⚠️ Facture sauvegardée SANS URL de PDF');
      }

      return invoiceId;

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur saveInvoice: $e');
      debugPrint('📍 StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Upload le PDF sur Firebase Storage
  Future<String?> uploadPDF(String userId, String invoiceId, File pdfFile) async {
    try {
      debugPrint('📤 _uploadPDF appelé');
      debugPrint('   UserId: $userId');
      debugPrint('   InvoiceId: $invoiceId');
      debugPrint('   Fichier: ${pdfFile.path}');

      // ✅ Vérifications de sécurité
      if (!await pdfFile.exists()) {
        debugPrint('❌ Le fichier n\'existe pas');
        return null;
      }

      final fileSize = await pdfFile.length();
      debugPrint('   Taille: $fileSize bytes');

      if (fileSize == 0) {
        debugPrint('❌ Le fichier est vide');
        return null;
      }

      // Chemin dans Storage : invoices/{userId}/{invoiceId}.pdf
      final storagePath = 'invoices/$userId/$invoiceId.pdf';
      debugPrint('   Chemin Storage: $storagePath');
      debugPrint('   Bucket: gs://facturezen-558b0.firebasestorage.app');

      final storageRef = _storage!.ref().child(storagePath);

      // Upload avec metadata
      debugPrint('🚀 Démarrage de l\'upload...');
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

      debugPrint('✅ Upload terminé, récupération de l\'URL...');

      // Récupérer l'URL de téléchargement
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('✅ PDF uploadé avec succès sur Storage');
      debugPrint('   URL de téléchargement: $downloadUrl');
      return downloadUrl;

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur upload PDF: $e');
      debugPrint('   Type d\'erreur: ${e.runtimeType}');
      debugPrint('📍 StackTrace: $stackTrace');

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
    if (userId == null) {
      debugPrint('❌ [getUserInvoices] Utilisateur non connecté');
      return [];
    }

    debugPrint('📋 [getUserInvoices] Récupération factures pour: $userId');

    // Alternative : Récupérer les IDs des factures depuis users/{userId}/invoices
    // puis charger chaque facture individuellement
    final userInvoicesRef = _database.ref('users/$userId/invoices');
    
    DataSnapshot userSnapshot;
    try {
      userSnapshot = await userInvoicesRef.get();
      
      if (!userSnapshot.exists || userSnapshot.value == null) {
        debugPrint('📋 [getUserInvoices] Aucune facture dans le profil utilisateur');
        // Essayer l'ancienne méthode avec query
        return await _getUserInvoicesWithQuery(userId);
      }
      
      // Récupérer les IDs de factures depuis le profil utilisateur
      final invoiceIds = <String>[];
      final data = userSnapshot.value;
      
      if (data is Map) {
        data.forEach((key, value) {
          if (key is String) {
            invoiceIds.add(key);
          }
        });
      }
      
      debugPrint('📋 [getUserInvoices] ${invoiceIds.length} facture(s) trouvée(s) dans le profil');
      
      // Charger chaque facture individuellement
      final invoices = <InvoiceModel>[];
      for (final invoiceId in invoiceIds) {
        try {
          final invoiceRef = _database.ref('invoices/$invoiceId');
          final invoiceSnapshot = await invoiceRef.get();
          
          if (invoiceSnapshot.exists && invoiceSnapshot.value != null) {
            final data = invoiceSnapshot.value;
            
            if (data is Map) {
              final invoiceData = Map<String, dynamic>.from(data);
              
              // Vérifier que c'est bien une facture de cet utilisateur
              if (invoiceData['userId'] == userId) {
                invoices.add(InvoiceModel(
                  id: invoiceId,
                  invoiceNumber: invoiceData['invoiceNumber'] as String? ?? '',
                  invoiceDate: DateTime.fromMillisecondsSinceEpoch(
                    invoiceData['createdAt'] is int
                        ? invoiceData['createdAt'] as int
                        : DateTime.now().millisecondsSinceEpoch,
                  ),
                  clientName: invoiceData['clientName'] as String? ?? '',
                  clientAddress: invoiceData['clientAddress'] as String? ?? '',
                  items: (invoiceData['items'] as List<dynamic>? ?? [])
                      .map((item) {
                        final itemMap = Map<String, dynamic>.from(item as Map);
                        return InvoiceItem(
                          description: itemMap['description'] as String? ?? '',
                          quantity: (itemMap['quantity'] as num?)?.toInt() ?? 0,
                          unitPrice: (itemMap['unitPrice'] as num?)?.toDouble() ?? 0.0,
                        );
                      })
                      .toList(),
                  companyName: invoiceData['companyName'] as String? ?? '',
                  companyAddress: invoiceData['companyAddress'] as String? ?? '',
                  companyPhone: invoiceData['companyPhone'] as String?,
                  companyEmail: invoiceData['companyEmail'] as String?,
                  companySiret: invoiceData['companySiret'] as String?,
                  taxRate: (invoiceData['taxRate'] as num?)?.toDouble(),
                  discountRate: (invoiceData['discountRate'] as num?)?.toDouble(),
                  discountLabel: invoiceData['discountLabel'] as String?,
                  notes: invoiceData['notes'] as String?,
                ));
                debugPrint('✅ [getUserInvoices] Facture chargée: $invoiceId');
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ [getUserInvoices] Erreur chargement facture $invoiceId: $e');
          continue;
        }
      }
      
      invoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
      debugPrint('📋 [getUserInvoices] ${invoices.length} facture(s) récupérée(s)');
      return invoices;
      
    } catch (e) {
      debugPrint('⚠️ [getUserInvoices] Erreur méthode profil: $e');
      debugPrint('💡 Tentative avec query directe...');
      
      // Si la query échoue aussi, on retourne une liste vide
      try {
        return await _getUserInvoicesWithQuery(userId);
      } catch (queryError) {
        debugPrint('❌ [getUserInvoices] Query aussi échouée: $queryError');
        debugPrint('🔧 SOLUTION: Nettoyez vos données Firebase sous /invoices');
        debugPrint('   Console: https://console.firebase.google.com/project/facturezen-558b0/database');
        return [];
      }
    }

  } catch (e, stack) {
    debugPrint('❌ Erreur getUserInvoices globale: $e');
    debugPrint('Stack: $stack');
    debugPrint('🔧 SOLUTION: Nettoyez vos données Firebase');
    debugPrint('   1. Allez sur: https://console.firebase.google.com/project/facturezen-558b0/database');
    debugPrint('   2. Supprimez le nœud /invoices');
    debugPrint('   3. Créez une nouvelle facture pour repartir sur des données propres');
    return [];
  }
}

  /// Méthode alternative avec query (peut échouer si données corrompues)
  Future<List<InvoiceModel>> _getUserInvoicesWithQuery(String userId) async {
    try {
      debugPrint('📋 [_getUserInvoicesWithQuery] Tentative avec query...');
      
      final invoicesRef = _database.ref('invoices');
      final snapshot = await invoicesRef
          .orderByChild('userId')
          .equalTo(userId)
          .get();

      debugPrint('📋 [_getUserInvoicesWithQuery] Snapshot exists: ${snapshot.exists}');
      debugPrint('📋 [_getUserInvoicesWithQuery] Snapshot value type: ${snapshot.value?.runtimeType}');

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('📋 [_getUserInvoicesWithQuery] Aucune facture trouvée');
        return [];
      }

      final raw = snapshot.value;
      
      // Gérer le cas où snapshot.value est une String (erreur de structure)
      if (raw is String) {
        debugPrint('❌ [_getUserInvoicesWithQuery] Données corrompues (String): $raw');
        return [];
      }
      
      if (raw is! Map) {
        debugPrint('❌ [_getUserInvoicesWithQuery] Format inattendu: ${raw.runtimeType}');
        debugPrint('📋 [_getUserInvoicesWithQuery] Valeur brute: $raw');
        return [];
      }

    final allInvoicesMap = Map<String, dynamic>.from(raw);
    final invoices = <InvoiceModel>[];

    debugPrint('📋 [_getUserInvoicesWithQuery] Nombre de factures: ${allInvoicesMap.length}');

    allInvoicesMap.forEach((key, value) {
      try {
        if (value is! Map) {
          debugPrint('⚠️ Entrée ignorée (pas un Map): $key → ${value.runtimeType}');
          return;
        }

        final data = Map<String, dynamic>.from(value);

        // La query a déjà filtré par userId, mais on vérifie quand même
        if (data['userId'] != userId) {
          debugPrint('⚠️ Facture ignorée (userId différent): $key');
          return;
        }

        debugPrint('✅ [_getUserInvoicesWithQuery] Facture trouvée: $key - ${data['clientName']}');

        invoices.add(InvoiceModel(
          id: key,
          invoiceNumber: data['invoiceNumber'] as String? ?? '',
          invoiceDate: DateTime.fromMillisecondsSinceEpoch(
            data['createdAt'] is int
                ? data['createdAt'] as int
                : DateTime.now().millisecondsSinceEpoch,
          ),
          clientName: data['clientName'] as String? ?? '',
          clientAddress: data['clientAddress'] as String? ?? '',
          items: (data['items'] as List<dynamic>? ?? [])
              .map((item) {
                final itemMap = Map<String, dynamic>.from(item as Map);
                return InvoiceItem(
                  description: itemMap['description'] as String? ?? '',
                  quantity: (itemMap['quantity'] as num?)?.toInt() ?? 0,
                  unitPrice: (itemMap['unitPrice'] as num?)?.toDouble() ?? 0.0,
                );
              })
              .toList(),
          companyName: data['companyName'] as String? ?? '',
          companyAddress: data['companyAddress'] as String? ?? '',
          companyPhone: data['companyPhone'] as String?,
          companyEmail: data['companyEmail'] as String?,
          companySiret: data['companySiret'] as String?,
          taxRate: (data['taxRate'] as num?)?.toDouble(),
          discountRate: (data['discountRate'] as num?)?.toDouble(),
          discountLabel: data['discountLabel'] as String?,
          notes: data['notes'] as String?,
        ));
      } catch (e) {
        debugPrint('⚠️ [_getUserInvoicesWithQuery] Erreur parsing facture $key: $e');
      }
    });

    invoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

    debugPrint('📋 [_getUserInvoicesWithQuery] ${invoices.length} facture(s) récupérée(s)');
    return invoices;

  } catch (e, stack) {
    debugPrint('❌ Erreur _getUserInvoicesWithQuery: $e');
    debugPrint('Stack: $stack');
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

      // ✅ NOUVEAU : Supprimer la référence du profil utilisateur
      final userInvoiceRef = _database.ref('users/$userId/invoices/$invoiceId');
      await userInvoiceRef.remove();
      debugPrint('✅ Référence supprimée du profil utilisateur');

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

  /// Incrémente le compteur global de factures créées (jamais décrémenté)
  Future<void> _incrementTotalInvoicesCreated(String userId) async {
    // Garder le compteur global historique
    final totalRef = _database.ref('users/$userId/$TOTAL_INVOICES_CREATED_KEY');
    await totalRef.set(ServerValue.increment(1));
    // ✅ Incrémenter le compteur mensuel
    final monthlyRef = _database.ref('users/$userId/$_monthlyCountKey');
    await monthlyRef.set(ServerValue.increment(1));
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

  /// ✅ NOUVEAU : Récupère une référence Storage
  Future<Reference?> getStorageReference(String path) async {
    try {
      final isAvailable = await _ensureStorageIsAvailable();
      if (!isAvailable || _storage == null) {
        return null;
      }
      return _storage!.ref().child(path);
    } catch (e) {
      debugPrint('❌ Erreur getStorageReference: $e');
      return null;
    }
  }


  /// ✅ NOUVEAU : Met à jour l'URL du PDF dans une facture existante
  Future<void> updateInvoicePdfUrl(String invoiceId, String pdfUrl) async {
    try {
      final invoiceRef = _database.ref('invoices/$invoiceId');
      await invoiceRef.update({'pdfUrl': pdfUrl});
      debugPrint('✅ URL du PDF mise à jour pour la facture: $invoiceId');
    } catch (e) {
      debugPrint('❌ Erreur updateInvoicePdfUrl: $e');
      rethrow;
    }
  }

  /// Met à jour une facture complète
  Future<void> updateInvoice(InvoiceModel invoice) async {
    try {
      final invoiceRef = _database.ref('invoices/${invoice.id}');

      final invoiceData = {
        'id': invoice.id,
        'invoiceNumber': invoice.invoiceNumber,
        'invoiceDate': invoice.invoiceDate.toIso8601String(),
        'clientName': invoice.clientName,
        'clientAddress': invoice.clientAddress,
        'items': invoice.items.map((item) => {
          'description': item.description,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
        }).toList(),
        'notes': invoice.notes,
        'companyName': invoice.companyName,
        'companyAddress': invoice.companyAddress,
        'companyPhone': invoice.companyPhone,
        'companyEmail': invoice.companyEmail,
        'companySiret': invoice.companySiret,
        'companyLogo': invoice.companyLogo,
        'taxRate': invoice.taxRate,
        'discountRate': invoice.discountRate,
        'discountLabel': invoice.discountLabel,
      };

      await invoiceRef.update(invoiceData);
      debugPrint('✅ Facture mise à jour: ${invoice.id}');
    } catch (e) {
      debugPrint('❌ Erreur updateInvoice: $e');
      rethrow;
    }
  }
}