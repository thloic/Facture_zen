import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../../features/invoicing/models/invoice_model.dart';
import '../../features/invoicing/services/pdf_generator_service.dart';
import '../../features/profile/services/firebase_profile_service.dart';

/// Service Firebase pour la gestion des factures
/// Utilise Realtime Database + Storage pour les PDFs
class FirebaseInvoiceService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PdfGeneratorService _pdfGenerator = PdfGeneratorService();
  final FirebaseProfileService _profileService = FirebaseProfileService();

  // Storage optionnel (peut être null si non configuré)
  FirebaseStorage? _storage;
  bool _storageAvailable = false;
  bool _storageInitialized = false;

  /// Limite gratuite de factures
  static const int FREE_INVOICE_LIMIT = 3;
  /// Nouveau : compteur global jamais décrémenté
  static const String TOTAL_INVOICES_CREATED_KEY = 'totalInvoicesCreated';

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
        debugPrint(
          '   5. Votre bucket: gs://facturezen-558b0.firebasestorage.app',
        );
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
      final totalInvoicesCreated = userData[TOTAL_INVOICES_CREATED_KEY] as int? ?? 0;

      // Si premium, pas de limite
      if (isPremium) return true;

      // Sinon, vérifier la limite sur le compteur global
      return totalInvoicesCreated < FREE_INVOICE_LIMIT;
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

      final totalInvoicesCreated = userData[TOTAL_INVOICES_CREATED_KEY] as int? ?? 0;
      return (FREE_INVOICE_LIMIT - totalInvoicesCreated).clamp(0, FREE_INVOICE_LIMIT);
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
          debugPrint(
            '❌ ERREUR : Le fichier PDF n\'existe pas: ${pdfFile.path}',
          );
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
        'items': invoice.items
            .map(
              (item) => {
                'description': item.description,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
              },
            )
            .toList(),
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
        'template': invoice.templateType.name,
        'pdfUrl': pdfUrl, // ✅ Peut être null si Storage non configuré
        'createdAt': ServerValue.timestamp,
      };

      // Sauvegarder dans Realtime Database
      await invoiceRef.set(invoiceData);
      debugPrint('✅ Métadonnées sauvegardées dans Realtime Database');

      // Incrémenter le compteur de factures (actif)
      await _incrementInvoiceCount(userId);
      // Incrémenter le compteur global (jamais décrémenté)
      await _incrementTotalInvoicesCreated(userId);
      debugPrint('✅ Compteur de factures incrémenté');

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

  /// Sauvegarde une facture avec génération automatique du PDF
  /// Cette méthode génère le PDF, l'uploade sur Firebase Storage,
  /// puis sauvegarde les métadonnées dans Realtime Database
  Future<String?> saveInvoiceWithPdf(InvoiceModel invoice) async {
    File? pdfFile;

    try {
      debugPrint('🚀 saveInvoiceWithPdf - Début du processus');
      debugPrint('   Facture: ${invoice.invoiceNumber}');
      debugPrint('   Client: ${invoice.clientName}');
      debugPrint('📊 [AVANT ENRICHISSEMENT] Invoice initiale:');
      debugPrint('   - companyName: "${invoice.companyName}"');
      debugPrint('   - companyAddress: "${invoice.companyAddress}"');
      debugPrint('   - companyPhone: "${invoice.companyPhone}"');
      debugPrint('   - companyEmail: "${invoice.companyEmail}"');
      debugPrint('   - companySiret: "${invoice.companySiret}"');

      // 1. Récupérer le profil utilisateur et enrichir la facture
      debugPrint('👤 Étape 1/4: Récupération du profil entreprise...');
      final profile = await _profileService.getUserProfile();

      InvoiceModel enrichedInvoice = invoice;
      if (profile != null) {
        debugPrint('✅ Profil trouvé: ${profile.companyName ?? "Sans nom"}');
        debugPrint('📋 Détails du profil:');
        debugPrint('   - companyName: "${profile.companyName ?? ""}"');
        debugPrint('   - companyAddress: "${profile.companyAddress ?? ""}"');
        debugPrint('   - companyPhone: "${profile.companyPhone ?? ""}"');
        debugPrint('   - companyEmail: "${profile.companyEmail ?? ""}"');
        debugPrint('   - companySiret: "${profile.companySiret ?? ""}"');
        
        // Créer une nouvelle facture avec les données du profil
        enrichedInvoice = InvoiceModel(
          id: invoice.id,
          invoiceNumber: invoice.invoiceNumber,
          invoiceDate: invoice.invoiceDate,
          clientName: invoice.clientName,
          clientAddress: invoice.clientAddress,
          items: invoice.items,
          notes: invoice.notes,
          templateType: invoice.templateType,
          companyName: profile.companyName ?? '',
          companyAddress: profile.companyAddress ?? '',
          companyPhone: profile.companyPhone ?? '',
          companyEmail: profile.companyEmail ?? '',
          companySiret: profile.companySiret ?? '',
          companyLogo: profile.companyLogo,
          taxRate: invoice.taxRate,
          discountRate: invoice.discountRate,
          discountLabel: invoice.discountLabel,
        );
        debugPrint('✅ Facture enrichie avec les données du profil');
        debugPrint('📊 [APRÈS ENRICHISSEMENT] Invoice enrichie:');
        debugPrint('   - companyName: "${enrichedInvoice.companyName}"');
        debugPrint('   - companyAddress: "${enrichedInvoice.companyAddress}"');
        debugPrint('   - companyPhone: "${enrichedInvoice.companyPhone}"');
        debugPrint('   - companyEmail: "${enrichedInvoice.companyEmail}"');
        debugPrint('   - companySiret: "${enrichedInvoice.companySiret}"');
      } else {
        debugPrint('⚠️ Aucun profil trouvé, utilisation des données par défaut');
        debugPrint('⚠️ Les factures afficheront des données vides pour l\'entreprise');
      }

      // 2. Générer le PDF
      debugPrint('📄 Étape 2/4: Génération du PDF...');
      pdfFile = await _pdfGenerator.generateInvoicePdf(enrichedInvoice);
      debugPrint('✅ PDF généré: ${pdfFile.path}');

      // Vérifier que le fichier existe et n'est pas vide
      if (!await pdfFile.exists()) {
        throw Exception('Le fichier PDF généré n\'existe pas');
      }

      final fileSize = await pdfFile.length();
      if (fileSize == 0) {
        throw Exception('Le fichier PDF généré est vide');
      }

      debugPrint('   Taille du PDF: $fileSize bytes');

      // 3. Sauvegarder la facture avec le PDF
      debugPrint('💾 Étape 3/4: Sauvegarde dans Firebase...');
      final invoiceId = await saveInvoice(enrichedInvoice, pdfFile: pdfFile);

      if (invoiceId == null) {
        throw Exception('Échec de la sauvegarde de la facture');
      }

      debugPrint('✅ Facture sauvegardée avec succès: $invoiceId');

      // 4. Nettoyer le fichier temporaire
      debugPrint('🧹 Étape 4/4: Nettoyage du fichier temporaire...');
      try {
        await pdfFile.delete();
        debugPrint('✅ Fichier temporaire supprimé');
      } catch (e) {
        debugPrint('⚠️ Impossible de supprimer le fichier temporaire: $e');
      }

      debugPrint('🎉 Processus terminé avec succès!');
      return invoiceId;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur saveInvoiceWithPdf: $e');
      debugPrint('📍 StackTrace: $stackTrace');

      // Nettoyer le fichier temporaire en cas d'erreur
      if (pdfFile != null) {
        try {
          if (await pdfFile.exists()) {
            await pdfFile.delete();
            debugPrint('🧹 Fichier temporaire nettoyé après erreur');
          }
        } catch (cleanupError) {
          debugPrint('⚠️ Erreur lors du nettoyage: $cleanupError');
        }
      }

      rethrow;
    }
  }

  /// Met à jour le template d'une facture
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

  /// Upload le PDF sur Firebase Storage (publique)
  Future<String?> uploadPDF(
    String userId,
    String invoiceId,
    File pdfFile,
  ) async {
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
        debugPrint(
          '💡 Le bucket Storage n\'est pas configuré dans Firebase Console',
        );
        debugPrint(
          '   Allez sur: https://console.firebase.google.com/project/facturezen-558b0/storage',
        );
      } else if (errorMsg.contains('permission-denied')) {
        debugPrint('💡 Problème de permissions Storage');
        debugPrint(
          '   Vérifiez les règles dans Firebase Console > Storage > Rules',
        );
      }

      return null;
    }
  }

  /// Récupère toutes les factures de l'utilisateur
  Future<List<InvoiceModel>> getUserInvoices() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        debugPrint('⚠️ getUserInvoices: Aucun utilisateur connecté');
        return [];
      }

      debugPrint('📥 Chargement des factures pour userId: $userId');

      // ✅ NOUVELLE APPROCHE : Récupérer TOUTES les factures puis filtrer
      // Cela évite les problèmes de parsing lors de la requête
      final invoicesRef = _database.ref('invoices');
      
      DataSnapshot snapshot;
      try {
        snapshot = await invoicesRef.get();
      } catch (queryError) {
        debugPrint('❌ Erreur lors de la requête Firebase: $queryError');
        debugPrint('💡 La structure des données dans Firebase est peut-être corrompue');
        debugPrint('   Essayez de vérifier vos données dans Firebase Console');
        return [];
      }

      if (!snapshot.exists) {
        debugPrint('ℹ️ Aucune facture trouvée dans la base');
        return [];
      }

      // ✅ CORRECTION : Vérifier que snapshot.value est bien un Map
      final snapshotValue = snapshot.value;
      if (snapshotValue == null) {
        debugPrint('⚠️ snapshot.value est null');
        return [];
      }

      if (snapshotValue is! Map) {
        debugPrint(
          '❌ snapshot.value n\'est pas un Map: ${snapshotValue.runtimeType}',
        );
        debugPrint('   Valeur reçue: $snapshotValue');
        return [];
      }

      final allInvoicesMap = Map<String, dynamic>.from(snapshotValue as Map);
      final invoices = <InvoiceModel>[];

      debugPrint('📊 Total de factures dans Firebase: ${allInvoicesMap.length}');

      allInvoicesMap.forEach((key, value) {
        try {
          debugPrint('🔍 Traitement facture $key');
          debugPrint('   Type de value: ${value.runtimeType}');

          // ✅ CORRECTION : Vérifier que value est bien un Map avant de le convertir
          if (value is! Map) {
            debugPrint(
              '⚠️ Facture $key ignorée (valeur n\'est pas un Map): ${value.runtimeType}',
            );
            return;
          }

          final data = Map<String, dynamic>.from(value as Map);

          // ✅ FILTRAGE : Ne garder que les factures de cet utilisateur
          final invoiceUserId = data['userId'] as String?;
          if (invoiceUserId != userId) {
            debugPrint('⏭️ Facture $key ignorée (autre utilisateur)');
            return;
          }

          debugPrint('   Clés disponibles: ${data.keys.toList()}');
          debugPrint('   invoiceNumber: ${data['invoiceNumber']}');
          debugPrint('   clientName: ${data['clientName']}');

          // Vérifier les champs obligatoires
          if (data['invoiceNumber'] == null || data['clientName'] == null) {
            debugPrint(
              '⚠️ Facture $key ignorée (champs obligatoires manquants)',
            );
            debugPrint('   Données complètes: $data');
            return;
          }

          invoices.add(
            InvoiceModel(
              id: key,
              invoiceNumber: data['invoiceNumber'] as String,
              invoiceDate: DateTime.fromMillisecondsSinceEpoch(
                data['createdAt'] as int? ??
                    DateTime.now().millisecondsSinceEpoch,
              ),
              clientName: data['clientName'] as String,
              clientAddress: data['clientAddress'] as String? ?? '',
              items:
                  (data['items'] as List<dynamic>?)
                      ?.map((item) {
                        if (item is! Map) return null;
                        return InvoiceItem(
                          description: item['description'] as String? ?? '',
                          quantity: item['quantity'] as int? ?? 1,
                          unitPrice:
                              (item['unitPrice'] as num?)?.toDouble() ?? 0.0,
                        );
                      })
                      .whereType<InvoiceItem>()
                      .toList() ??
                  [],
              companyName: data['companyName'] as String? ?? '',
              companyAddress: data['companyAddress'] as String? ?? '',
              companyPhone: data['companyPhone'] as String?,
              companyEmail: data['companyEmail'] as String?,
              companySiret: data['companySiret'] as String?,
              taxRate: (data['taxRate'] as num?)?.toDouble(),
              discountRate: (data['discountRate'] as num?)?.toDouble(),
              discountLabel: data['discountLabel'] as String?,
              notes: data['notes'] as String?,
            ),
          );

          debugPrint('✅ Facture chargée: ${data['invoiceNumber']} - Client: ${data['clientName']}');
        } catch (itemError, stackTrace) {
          debugPrint(
            '⚠️ Erreur lors du parsing de la facture $key: $itemError',
          );
          debugPrint('📍 StackTrace: $stackTrace');
        }
      });

      // Trier par date décroissante
      invoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

      debugPrint('✅ ${invoices.length} facture(s) chargée(s) avec succès');
      return invoices;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur getUserInvoices: $e');
      debugPrint('📍 StackTrace: $stackTrace');
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

  /// Télécharge le PDF d'une facture et retourne le fichier local
  /// Utile pour ouvrir le PDF avec une app externe
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

  /// Supprime une facture (et son PDF)
  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return false;

      // Vérifier si Storage est disponible avant de supprimer
      final isAvailable = await _ensureStorageIsAvailable();

      if (isAvailable) {
        final storageRef = _storage!.ref().child(
          'invoices/$userId/$invoiceId.pdf',
        );
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

      debugPrint('Facture supprimée: $invoiceId');
      return true;
    } catch (e) {
      debugPrint('Erreur deleteInvoice: $e');
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
      'totalInvoicesCreated': 0,
      'createdAt': ServerValue.timestamp,
    });

  }

  /// Incrémente le compteur global de factures créées (jamais décrémenté)
  Future<void> _incrementTotalInvoicesCreated(String userId) async {
    final userRef = _database.ref('users/$userId/$TOTAL_INVOICES_CREATED_KEY');
    await userRef.set(ServerValue.increment(1));
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
