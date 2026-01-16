import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/utils/responsive_utils.dart';
import 'invoice_preview_screen.dart';

/// TextPreviewScreen
/// Écran d'aperçu du texte transcrit + génération de facture par GPT
class TextPreviewScreen extends StatefulWidget {
  final String transcribedText;

  const TextPreviewScreen({
    Key? key,
    required this.transcribedText,
  }) : super(key: key);

  @override
  State<TextPreviewScreen> createState() => _TextPreviewScreenState();
}

class _TextPreviewScreenState extends State<TextPreviewScreen> {
  bool _isGenerating = false;
  String? _errorMessage;

  // Configuration Groq API (GRATUIT)
  static String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

  @override
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
                      widget.transcribedText,
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
                text: _isGenerating ? 'Génération...' : 'Générer la facture',
                onPressed: _isGenerating ? null : _generateInvoiceWithGroq,
                height: responsive.getAdaptiveHeight(56),
              ),

              SizedBox(height: responsive.getAdaptiveSpacing(16)),
            ],
          ),
        ),
      ),
    );
  }

  /// Génère la facture via Groq API (LLaMA)
  Future<void> _generateInvoiceWithGroq() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🤖 Génération facture avec Groq...');

      final prompt = '''
Tu es un assistant qui analyse des transcriptions vocales pour créer des factures.
Analyse le texte suivant et extrais les informations pour générer une facture au format JSON.

Texte: "${widget.transcribedText}"

Retourne UNIQUEMENT un objet JSON avec cette structure exacte (pas de texte avant ou après):
{
  "clientName": "nom du client",
  "clientAddress": "adresse complète du client",
  "items": [
    {
      "description": "description de l'article",
      "quantity": nombre,
      "unitPrice": prix_unitaire
    }
  ]
}

Si certaines informations manquent, utilise des valeurs par défaut raisonnables.
''';

      final requestBody = json.encode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.1,
        'max_tokens': 1000,
      });

      debugPrint('📤 Envoi à Groq API...');

      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: requestBody,
      );

      debugPrint('📡 Réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final groqContent = jsonResponse['choices'][0]['message']['content'] as String;

        debugPrint('📄 Réponse Groq: $groqContent');

        // Nettoyer et parser le JSON
        String cleanedContent = groqContent.trim();
        if (cleanedContent.startsWith('```json')) {
          cleanedContent = cleanedContent.substring(7);
        }
        if (cleanedContent.endsWith('```')) {
          cleanedContent = cleanedContent.substring(0, cleanedContent.length - 3);
        }
        cleanedContent = cleanedContent.trim();

        final invoiceData = json.decode(cleanedContent);

        debugPrint('✅ Facture générée avec succès');

        // Navigation vers l'écran de prévisualisation
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvoicePreviewScreen(
              invoiceData: invoiceData,
            ),
          ),
        );

      } else {
        debugPrint('❌ Erreur API: ${response.statusCode}');
        debugPrint('📄 Body: ${response.body}');

        setState(() {
          _errorMessage = 'Erreur lors de la génération (${response.statusCode})';
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur: $e');
      debugPrint('📍 Stack: $stackTrace');

      setState(() {
        _errorMessage = 'Erreur: $e';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la génération de la facture'),
          backgroundColor: Colors.red,
        ),
      );

    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  /// ANCIENNE MÉTHODE (données mockées) - À SUPPRIMER
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