
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:typed_data';

/// Écran de visualisation de PDF
/// Affiche un PDF avec options de partage et impression
class PdfViewerScreen extends StatelessWidget {
  final File pdfFile;
  final String title;

  const PdfViewerScreen({
    Key? key,
    required this.pdfFile,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B5FC7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _sharePdf(context),
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: pdfFile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Aucune donnée disponible'),
            );
          }

          return PdfPreview(
            build: (format) => snapshot.data!,
            allowSharing: true,
            allowPrinting: true,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: title,
          );
        },
      ),
    );
  }

  /// Partager le PDF
  Future<void> _sharePdf(BuildContext context) async {
    try {
      await Printing.sharePdf(
        bytes: await pdfFile.readAsBytes(),
        filename: title,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
