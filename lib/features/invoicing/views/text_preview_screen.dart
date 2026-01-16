
import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
>>>>>>> 971f1f1 (feat: Ajout clé API Groq depuis variables d'environnement (sécurisé))
import '../../../common/widgets/primary_button.dart';
import '../../../common/utils/responsive_utils.dart';
import 'invoice_preview_screen.dart';

/// TextPreviewScreen
/// Écran d'aperçu du texte généré après transcription vocale
/// Permet de voir le résultat avant de générer la facture
class TextPreviewScreen extends StatelessWidget {
  final String transcribedText;

  const TextPreviewScreen({
    Key? key,
    required this.transcribedText,
  }) : super(key: key);

  @override
<<<<<<< HEAD
=======
  State<TextPreviewScreen> createState() => _TextPreviewScreenState();
}

class _TextPreviewScreenState extends State<TextPreviewScreen> {
  bool _isGenerating = false;
  String? _errorMessage;

  // Configuration Groq API (GRATUIT)
  static String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

  @override
>>>>>>> 971f1f1 (feat: Ajout clé API Groq depuis variables d'environnement (sécurisé))
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Génération du texte',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(responsive.horizontalPadding),
          child: Column(
            children: [
              SizedBox(height: responsive.getAdaptiveSpacing(20)),

              // Zone de texte transcrit
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(responsive.getAdaptiveSpacing(20)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      transcribedText,
                      style: TextStyle(
                        fontSize: responsive.getAdaptiveTextSize(15),
                        color: const Color(0xFF1F2937),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(24)),

              // Bouton "Générer la facture"
              PrimaryButton(
                text: 'Générer la facture',
                onPressed: () {
                  // TODO: Navigation vers l'écran de génération de facture
                  _generateInvoice(context);
                },
                height: responsive.getAdaptiveHeight(56),
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(16)),
            ],
          ),
        ),
      ),
    );
  }

  /// Génère la facture à partir du texte transcrit
  void _generateInvoice(BuildContext context) {
    // TODO: Implémenter la logique de génération de facture
    // Pour l'instant, on affiche juste une confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération de la facture en cours...'),
        backgroundColor: Color(0xFF5B5FC7),
      ),
    );

    final invoiceData = {
      'clientName': 'Roger Holmes',
      'clientAddress': '139 Bedford Lane\nBrooklyn, NY 11201',
      'items': [
        {
          'description': 'Sacs de ciment 50 kg',
          'quantity': 42,
          'unitPrice': 7.80,
        },
        {
          'description': 'Barres de fer Ø12 mm',
          'quantity': 85,
          'unitPrice': 9.50,
        },
        {
          'description': 'Carreaux céramiques 40×40',
          'quantity': 520,
          'unitPrice': 0.45,
        },
        {
          'description': 'Planche de bois 4 m',
          'quantity': 190,
          'unitPrice': 6.20,
        },
        {
          'description': 'Sable (m³)',
          'quantity': 35,
          'unitPrice': 12.90,
        },
      ],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicePreviewScreen(
          invoiceData: invoiceData,
        ),
      ),
    );

    // TODO: Navigation vers InvoicePreviewScreen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => InvoicePreviewScreen(invoiceData: parsedData),
    //   ),
    // );
  }
}