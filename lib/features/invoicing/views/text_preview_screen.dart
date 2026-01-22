import 'package:facture_zen/common/services/firebase_invoice_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../common/widgets/primary_button.dart';
import '../../../common/utils/responsive_utils.dart';
import 'invoice_preview_screen.dart';
import 'subscription_screen.dart';

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
  bool _isEditing = false;

  // ✅ AJOUT : Contrôleur pour éditer le texte
  late TextEditingController _textController;

  // ✅ AJOUT : Instance du service Firebase
  final FirebaseInvoiceService _invoiceService = FirebaseInvoiceService();

  // Configuration Groq API (GRATUIT)
  static const String _groqApiKey = '';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

  @override
  void initState() {
    super.initState();
    // Initialiser le contrôleur avec le texte transcrit
    _textController = TextEditingController(text: widget.transcribedText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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
        actions: [
          // ✅ AJOUT : Bouton pour basculer entre lecture et édition
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: const Color(0xFF5B5FC7),
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            tooltip: _isEditing ? 'Valider' : 'Modifier',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              child: Column(
                children: [
                  SizedBox(height: responsive.getAdaptiveSpacing(20)),

                  // ✅ MODIFIÉ : Zone de texte avec possibilité d'édition
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(responsive.getAdaptiveSpacing(20)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                        border: _isEditing
                            ? Border.all(color: const Color(0xFF5B5FC7), width: 2)
                            : null,
                      ),
                      child: _isEditing
                          ? TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        style: TextStyle(
                          fontSize: responsive.getAdaptiveTextSize(15),
                          color: const Color(0xFF1F2937),
                          height: 1.6,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Modifiez le texte transcrit...',
                        ),
                      )
                          : SingleChildScrollView(
                        child: Text(
                          _textController.text,
                          style: TextStyle(
                            fontSize: responsive.getAdaptiveTextSize(15),
                            color: const Color(0xFF1F2937),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ✅ AJOUT : Indication du mode édition
                  if (_isEditing) ...[
                    SizedBox(height: responsive.getAdaptiveSpacing(12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B5FC7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFF5B5FC7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mode édition activé - Appuyez sur ✓ pour valider',
                            style: TextStyle(
                              fontSize: responsive.getAdaptiveTextSize(12),
                              color: const Color(0xFF5B5FC7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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
    // ✅ MODIFIÉ : Utiliser le texte du contrôleur (qui peut avoir été modifié)
    final textToProcess = _textController.text.trim();

    if (textToProcess.isEmpty) {
      setState(() {
        _errorMessage = 'Le texte ne peut pas être vide';
      });
      return;
    }

    // 🔒 VÉRIFIER LA LIMITE AVANT DE GÉNÉRER
    final canCreate = await _invoiceService.canCreateInvoice();

    if (!canCreate) {
      // Afficher l'écran d'abonnement
      if (mounted) {
        final remaining = await _invoiceService.getRemainingInvoices();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubscriptionScreen(
              remainingInvoices: remaining,
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _isEditing = false; // Désactiver le mode édition pendant la génération
    });

    try {
      debugPrint('🤖 Génération facture avec GPT...');

      // Prompt système pour structurer la facture
      final systemPrompt = '''
Tu es un assistant spécialisé dans la génération de factures professionnelles.
À partir d'une transcription vocale en français, tu dois extraire et structurer les informations de facture.

RÈGLES STRICTES:
1. Retourne UNIQUEMENT un JSON valide, sans texte avant ou après
2. Format JSON exact: {"clientName": "...", "clientAddress": "...", "items": [...], "taxRate": null, "discountRate": null}
3. Chaque item doit avoir: description (string), quantity (number), unitPrice (number)
4. Les prix doivent être en nombres décimaux (ex: 7.80 pas "7,80€")

RÈGLES TVA ET RÉDUCTIONS (TRÈS IMPORTANT):
- "taxRate": SEULEMENT si l'utilisateur mentionne explicitement "TVA", "taxe", "avec TVA 20%", etc.
- Si TVA mentionnée: "taxRate": 20.0 (ou le taux indiqué)
- Si AUCUNE mention de TVA: "taxRate": null
- "discountRate": SEULEMENT si l'utilisateur mentionne "remise", "réduction", "rabais", "promotion"
- "discountLabel": texte de la réduction (ex: "Remise fidélité 10%")
- Si aucune réduction: "discountRate": null, "discountLabel": null

EXEMPLES:
1. SANS TVA (défaut):
{
  "clientName": "M. Dupont",
  "clientAddress": "123 Rue de Paris, 75001 Paris",
  "items": [{"description": "Réparation", "quantity": 1, "unitPrice": 150.00}],
  "taxRate": null,
  "discountRate": null
}

2. AVEC TVA explicite:
{
  "clientName": "M. Martin",
  "clientAddress": "456 Avenue de Lyon, 69000 Lyon",
  "items": [{"description": "Installation", "quantity": 2, "unitPrice": 200.00}],
  "taxRate": 20.0,
  "discountRate": null
}

3. AVEC RÉDUCTION:
{
  "clientName": "Mme Durand",
  "clientAddress": "789 Boulevard Marseille, 13000 Marseille",
  "items": [{"description": "Service", "quantity": 1, "unitPrice": 500.00}],
  "taxRate": null,
  "discountRate": 10.0,
  "discountLabel": "Remise client fidèle 10%"
}
''';

      final userPrompt = '''
Voici la transcription vocale d'un artisan pour créer une facture:

"$textToProcess"

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
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.1,
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

        // ✅ CORRECTION : Convertir explicitement les types pour éviter List<dynamic>
        final invoiceData = <String, dynamic>{
          'clientName': rawData['clientName'] as String? ?? 'Client inconnu',
          'clientAddress': rawData['clientAddress'] as String? ?? '',
          'items': (rawData['items'] as List<dynamic>?)
              ?.map((item) => <String, dynamic>{
            'description': item['description'] as String? ?? '',
            'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
            'unitPrice': (item['unitPrice'] as num?)?.toDouble() ?? 0.0,
          })
              .toList() ?? <Map<String, dynamic>>[],
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

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur génération facture: $e');
      debugPrint('📍 StackTrace: $stackTrace');

      setState(() {
        _errorMessage = 'Impossible de générer la facture. Vérifiez votre clé API Groq.';
      });

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