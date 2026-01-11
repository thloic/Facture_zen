import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  static const String _groqApiKey = '';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

  // Alternative OpenAI (payant mais moins cher avec gpt-4o-mini)
  // static const String _openaiApiKey = 'sk-...';
  // static const String _openaiEndpoint = 'https://api.openai.com/v1/chat/completions';

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
          'Texte transcrit',
          style: TextStyle(
            fontSize: responsive.getAdaptiveTextSize(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
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

                  if (_errorMessage != null) ...[
                    SizedBox(height: responsive.getAdaptiveSpacing(16)),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: responsive.getAdaptiveSpacing(24)),

                  // Bouton "Générer la facture"
                  PrimaryButton(
                    text: 'Générer la facture',
                    onPressed: _isGenerating ? null : _generateInvoiceWithGPT,
                    height: responsive.getAdaptiveHeight(56),
                  ),

                  SizedBox(height: responsive.getAdaptiveSpacing(16)),
                ],
              ),
            ),

            // Modal de chargement
            if (_isGenerating)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: responsive.horizontalPadding * 2,
                    ),
                    padding: EdgeInsets.all(responsive.getAdaptiveSpacing(32)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FC7)),
                        ),
                        SizedBox(height: responsive.getAdaptiveSpacing(20)),
                        Text(
                          'Génération de la facture',
                          style: TextStyle(
                            fontSize: responsive.getAdaptiveTextSize(18),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: responsive.getAdaptiveSpacing(12)),
                        Text(
                          'L\'IA analyse votre texte...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: responsive.getAdaptiveTextSize(14),
                            color: const Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Génère la facture via GPT (Groq ou OpenAI)
  Future<void> _generateInvoiceWithGPT() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🤖 Génération facture avec GPT...');

      // Prompt système pour structurer la facture
      final systemPrompt = '''
Tu es un assistant spécialisé dans la génération de factures professionnelles.
À partir d'une transcription vocale en français, tu dois extraire et structurer les informations de facture.

RÈGLES STRICTES:
1. Retourne UNIQUEMENT un JSON valide, sans texte avant ou après
2. Format JSON exact: {"clientName": "...", "clientAddress": "...", "items": [...]}
3. Chaque item doit avoir: description (string), quantity (number), unitPrice (number)
4. Si une info manque, mets des valeurs par défaut cohérentes
5. Les prix doivent être en nombres décimaux (ex: 7.80 pas "7,80€")

EXEMPLE DE SORTIE:
{
  "clientName": "Monsieur Dupont",
  "clientAddress": "123 Rue de Paris\\n75001 Paris",
  "items": [
    {
      "description": "Réparation fuite salle de bain",
      "quantity": 1,
      "unitPrice": 150.00
    }
  ]
}
''';

      final userPrompt = '''
Voici la transcription vocale d'un artisan pour créer une facture:

"${widget.transcribedText}"

Génère le JSON de la facture selon le format spécifié.
''';

      // Requête API
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: json.encode({
          'model': 'llama-3.3-70b-versatile', // Modèle Groq gratuit et performant
          // Alternative OpenAI: 'gpt-4o-mini' (payant mais moins cher)
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.1, // Plus déterministe
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final gptContent = jsonResponse['choices'][0]['message']['content'] as String;

        debugPrint('📄 Réponse GPT: $gptContent');

        // Parser le JSON (enlever les backticks Markdown si présents)
        String cleanedContent = gptContent.trim();
        if (cleanedContent.startsWith('```json')) {
          cleanedContent = cleanedContent
              .replaceFirst('```json', '')
              .replaceFirst('```', '')
              .trim();
        } else if (cleanedContent.startsWith('```')) {
          cleanedContent = cleanedContent
              .replaceFirst('```', '')
              .replaceFirst('```', '')
              .trim();
        }

        final rawData = json.decode(cleanedContent);

        // ✅ CORRECTION : Convertir explicitement les types
        final invoiceData = {
          'clientName': rawData['clientName'] as String? ?? '',
          'clientAddress': rawData['clientAddress'] as String? ?? '',
          'items': (rawData['items'] as List<dynamic>?)
              ?.map((item) => {
            'description': item['description'] as String? ?? '',
            'quantity': (item['quantity'] as num?)?.toInt() ?? 0,
            'unitPrice': (item['unitPrice'] as num?)?.toDouble() ?? 0.0,
          })
              .toList() ?? [],
        };

        debugPrint('✅ Facture générée: $invoiceData');

        // Navigation vers InvoicePreviewScreen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoicePreviewScreen(
                invoiceData: invoiceData,
              ),
            ),
          );
        }

      } else {
        throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
      }

    } catch (e) {
      debugPrint('❌ Erreur génération facture: $e');

      setState(() {
        _errorMessage = 'Impossible de générer la facture. Vérifiez votre clé API Groq.';
      });

      // Afficher un SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
}