import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

/// Service pour gérer l'upload d'images vers Firebase Storage
class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload le logo de l'entreprise
  /// Retourne l'URL Firebase Storage du logo
  Future<String?> uploadCompanyLogo({
    required File imageFile,
    required String userId,
  }) async {
    try {
      // 1. Validation de l'image
      if (!await _validateImage(imageFile)) {
        throw Exception('Image invalide ou trop volumineuse');
      }

      // 2. Compression de l'image
      final compressedImage = await _compressImage(imageFile);
      if (compressedImage == null) {
        throw Exception('Erreur lors de la compression de l\'image');
      }

      // 3. Générer le chemin Firebase Storage
      final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('users/$userId/company/$fileName');

      // 4. Upload vers Firebase Storage
      final uploadTask = storageRef.putData(
        compressedImage,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // 5. Attendre la fin de l'upload
      final snapshot = await uploadTask;

      // 6. Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('❌ Erreur upload logo: $e');
      return null;
    }
  }

  /// Supprime le logo de l'entreprise
  Future<bool> deleteCompanyLogo(String logoUrl) async {
    try {
      final storageRef = _storage.refFromURL(logoUrl);
      await storageRef.delete();
      return true;
    } catch (e) {
      print('❌ Erreur suppression logo: $e');
      return false;
    }
  }

  /// Valide le format et la taille de l'image
  Future<bool> _validateImage(File imageFile) async {
    try {
      // Vérifier la taille du fichier (max 5 MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        print('❌ Image trop volumineuse: ${fileSize / (1024 * 1024)} MB');
        return false;
      }

      // Vérifier l'extension
      final extension = path.extension(imageFile.path).toLowerCase();
      if (!['.jpg', '.jpeg', '.png'].contains(extension)) {
        print('❌ Format non supporté: $extension');
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Erreur validation: $e');
      return false;
    }
  }

  /// Compresse l'image avant upload
  Future<Uint8List?> _compressImage(File imageFile) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
      );

      return result;
    } catch (e) {
      print('❌ Erreur compression: $e');
      return null;
    }
  }
}