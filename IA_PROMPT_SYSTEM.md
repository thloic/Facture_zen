# Système d'IA et Prompts - Facture Zen

## 📋 Vue d'ensemble

L'application Facture Zen utilise deux services d'IA pour transformer la voix en facture :

1. **Groq Whisper API** → Transcription audio-to-text
2. **OpenAI GPT** → Extraction des données de facture depuis le texte

---

## 🎙️ Étape 1 : Transcription Vocale (Groq Whisper)

### Service utilisé
- **API** : Groq Whisper
- **Modèle** : `whisper-large-v3`
- **Endpoint** : `https://api.groq.com/openai/v1/audio/transcriptions`

### Flux de données

```
📱 Utilisateur enregistre sa voix
    ↓
🎵 Fichier audio (.m4a) sauvegardé localement
    ↓
📤 Envoi à Groq Whisper API
    ↓
📝 Réception du texte transcrit
```

### Code (lib/features/invoicing/services/groq_voice_service.dart)

```dart
Future<String?> transcribeAudio(String audioPath) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
  );
  
  request.files.add(await http.MultipartFile.fromPath('file', audioPath));
  request.fields['model'] = 'whisper-large-v3';
  request.fields['language'] = 'fr'; // Français
  request.headers['Authorization'] = 'Bearer $apiKey';
  
  final response = await request.send();
  final jsonResponse = json.decode(responseBody);
  return jsonResponse['text']; // Texte transcrit
}
```

### Exemple

**Audio** : "Créez-moi une facture pour Jean Dupont de 1500 euros avec TVA à 20%"

**Résultat** : `"Créez-moi une facture pour Jean Dupont de 1500 euros avec TVA à 20%"`

---

## 🤖 Étape 2 : Génération de Facture (GPT)

### Service utilisé
- **API** : OpenAI
- **Modèle** : `gpt-3.5-turbo`
- **Endpoint** : `https://api.openai.com/v1/chat/completions`

### Prompt System

Le prompt est conçu pour extraire uniquement les données structurées nécessaires à une facture.

#### Prompt complet (lib/features/invoicing/views/text_preview_screen.dart)

```dart
final prompt = '''
Tu es un assistant qui extrait les informations d'une facture depuis un texte en français.

RÈGLES STRICTES :
1. Retourne UNIQUEMENT un JSON valide
2. Ne génère AUCUNE information inventée
3. Si une info n'est pas mentionnée, mets null
4. Les montants sont TOUJOURS en euros (€)
5. Format de réponse EXACT :

{
  "clientName": "string ou null",
  "clientAddress": "string ou null",
  "items": [
    {
      "description": "string (si vide, mets '')",
      "quantity": number (minimum 1),
      "unitPrice": number
    }
  ],
  "taxRate": number ou null (si "TVA 20%" → 0.20),
  "discountRate": number ou null (si "remise 10%" → 0.10)
}

EXEMPLES :

Texte : "Facture pour Martin de 500€"
→ {"clientName": "Martin", "clientAddress": null, "items": [{"description": "", "quantity": 1, "unitPrice": 500.00}], "taxRate": null, "discountRate": null}

Texte : "2 prestations de consulting à 300€ chacune pour Entreprise ABC, TVA 20%"
→ {"clientName": "Entreprise ABC", "clientAddress": null, "items": [{"description": "Prestation de consulting", "quantity": 2, "unitPrice": 300.00}], "taxRate": 0.20, "discountRate": null}

MAINTENANT, extrait les données de :
"$transcribedText"

Réponds UNIQUEMENT avec le JSON, sans texte avant ou après.
''';
```

### Paramètres de l'appel API

```dart
final response = await http.post(
  Uri.parse('https://api.openai.com/v1/chat/completions'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  },
  body: json.encode({
    'model': 'gpt-3.5-turbo',
    'messages': [
      {
        'role': 'system',
        'content': 'Tu es un assistant de facturation précis.',
      },
      {
        'role': 'user',
        'content': prompt,
      }
    ],
    'temperature': 0.3, // Basse pour plus de précision
    'max_tokens': 1000,
  }),
);
```

### Réponse GPT attendue

**Format JSON strict :**

```json
{
  "clientName": "Jean Dupont",
  "clientAddress": null,
  "items": [
    {
      "description": "Prestation",
      "quantity": 1,
      "unitPrice": 1500.00
    }
  ],
  "taxRate": 0.20,
  "discountRate": null
}
```

### Nettoyage de la réponse

GPT peut parfois entourer le JSON de backticks Markdown. On les retire :

```dart
String cleanedContent = gptContent.trim();
if (cleanedContent.startsWith('```json')) {
  cleanedContent = cleanedContent
      .replaceFirst('```json', '')
      .replaceFirst('```', '')
      .trim();
}
```

---

## 🔄 Flux Complet

```
🎤 Utilisateur : "Facture pour Loic de 5000€"
    ↓
📝 Groq Whisper : "Facture pour Loic de 5000€"
    ↓
🤖 GPT (avec prompt) : {
      "clientName": "Loic",
      "clientAddress": null,
      "items": [{
        "description": "Prestation",
        "quantity": 1,
        "unitPrice": 5000.00
      }],
      "taxRate": null,
      "discountRate": null
    }
    ↓
📊 InvoiceModel créé avec les données
    ↓
🏢 Enrichissement avec profil entreprise
    ↓
👁️ Prévisualisation affichée
    ↓
💾 Sauvegarde → Génération PDF
```

---

## 📊 Structure des Données

### InvoiceModel (après traitement GPT)

```dart
InvoiceModel(
  invoiceNumber: 'FACT-202601-462',        // Généré auto
  clientName: 'Loic',                       // Depuis GPT
  clientAddress: '',                        // Depuis GPT (vide si null)
  items: [
    InvoiceItem(
      description: 'Prestation',            // Depuis GPT
      quantity: 1,                          // Depuis GPT
      unitPrice: 5000.0,                    // Depuis GPT
    )
  ],
  taxRate: null,                            // Depuis GPT
  discountRate: null,                       // Depuis GPT
  // Champs entreprise vides ici, enrichis plus tard
  companyName: '',
  companyAddress: '',
  companyPhone: '',
  companyEmail: '',
  companySiret: '',
)
```

### Enrichissement avec profil

Le profil entreprise est chargé depuis Firebase et ajouté à la facture :

```dart
// Avant enrichissement
companyName: ''
companyAddress: ''

// Après enrichissement (InvoicePreviewScreen + saveInvoiceWithPdf)
companyName: 'SARL'
companyAddress: '10 rue'
companyPhone: '+336985231456'
companyEmail: 'contact@sarl.fr'
companySiret: '12364507'
```

---

## 🔑 Clés API

### Configuration requise

Les clés API doivent être stockées dans Firebase Realtime Database :

```
/users/{userId}/apiKeys/
  ├── groqApiKey: "gsk_..."
  └── openaiApiKey: "sk-..."
```

### Récupération dans le code

```dart
// lib/features/invoicing/services/groq_voice_service.dart
final snapshot = await _database.ref('users/$userId/apiKeys/groqApiKey').get();
final apiKey = snapshot.value as String?;
```

---

## ⚠️ Gestion des Erreurs

### Erreurs courantes

1. **Clé API manquante** → "Aucune clé API configurée"
2. **Réponse GPT invalide** → "Format JSON invalide"
3. **Transcription vide** → "Aucun texte détecté"
4. **Timeout API** → "Délai d'attente dépassé"

### Logs de débogage

```dart
debugPrint('🎯 Début transcription avec Groq Whisper...');
debugPrint('📦 Taille fichier: ${fileSize / 1024 / 1024} MB');
debugPrint('📤 Envoi à Groq Whisper API...');
debugPrint('✅ Transcription réussie: $text');
debugPrint('🤖 Génération facture avec GPT...');
debugPrint('📄 Réponse GPT: $gptContent');
debugPrint('✅ Facture générée: $invoiceData');
```

---

## 🎯 Optimisations

### Température GPT

```dart
'temperature': 0.3  // Basse = plus précis, moins créatif
```

- **0.0** : Totalement déterministe (toujours la même réponse)
- **0.3** : Précis mais flexible (recommandé pour facturation)
- **1.0** : Créatif mais imprévisible

### Tokens

```dart
'max_tokens': 1000  // Suffisant pour une facture
```

Une facture simple = ~100-200 tokens

---

## 📝 Exemples de Prompts Utilisateur

| Prompt vocal | GPT extraction |
|-------------|----------------|
| "Facture de 100€ pour Loic" | `clientName: "Loic", items: [{unitPrice: 100}]` |
| "2 articles à 50€ chacun pour Martin" | `clientName: "Martin", items: [{quantity: 2, unitPrice: 50}]` |
| "Prestation consulting 1500€ avec TVA 20%" | `items: [{description: "Prestation consulting", unitPrice: 1500}], taxRate: 0.20` |
| "Facture ABC Entreprise, 3 licences logiciel à 200€, remise 10%" | `clientName: "ABC Entreprise", items: [{description: "Licence logiciel", quantity: 3, unitPrice: 200}], discountRate: 0.10` |

---

## 🔐 Sécurité

### Stockage des clés API

- ✅ **Stockées dans Firebase** (accès authentifié uniquement)
- ❌ **Jamais en dur dans le code**
- ✅ **Récupérées dynamiquement** pour chaque utilisateur

### Validation des données

```dart
// Validation côté client avant envoi
if (value == null || value.trim().isEmpty) {
  return 'Ce champ est requis';
}
```

---

## 📚 Fichiers Concernés

| Fichier | Rôle |
|---------|------|
| `lib/features/invoicing/services/groq_voice_service.dart` | Service de transcription Groq Whisper |
| `lib/features/invoicing/views/text_preview_screen.dart` | Appel GPT + prompt + génération facture |
| `lib/features/invoicing/views/invoice_preview_screen.dart` | Prévisualisation + enrichissement profil |
| `lib/common/services/firebase_invoice_service.dart` | Sauvegarde + enrichissement final + PDF |
| `lib/features/invoicing/models/invoice_model.dart` | Modèle de données facture |

---

## 🚀 Améliorations Futures

### Possibilités d'évolution

1. **Multi-langues** : Support de l'anglais, espagnol, etc.
2. **GPT-4** : Plus précis pour des factures complexes
3. **Fine-tuning** : Modèle personnalisé spécifique à la facturation
4. **Validation IA** : Vérification automatique des erreurs
5. **Suggestions** : GPT propose des corrections si données incohérentes

### Exemple de validation avancée

```dart
// Prompt additionnel de validation
'''
Vérifie cette facture et signale les problèmes :
- Prix incohérents
- Quantités négatives
- TVA invalide
'''
```

---

## 📖 Ressources

- [Groq API Documentation](https://console.groq.com/docs)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Whisper Model Info](https://github.com/openai/whisper)

---

**Dernière mise à jour** : 27 janvier 2026
