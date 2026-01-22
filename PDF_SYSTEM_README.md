# Système de Génération et Sauvegarde de PDF

## 📋 Vue d'ensemble

Ce système permet de :
- ✅ Générer des PDFs professionnels pour les factures
- ✅ Uploader automatiquement les PDFs sur Firebase Storage
- ✅ Sauvegarder les métadonnées dans Realtime Database
- ✅ Télécharger et visualiser les PDFs
- ✅ Partager et imprimer les PDFs

## 🏗️ Architecture

### Services

1. **PdfGeneratorService** (`lib/features/invoicing/services/pdf_generator_service.dart`)
   - Génère des PDFs à partir d'InvoiceModel
   - Utilise le package `pdf` pour créer le document
   - Crée des fichiers temporaires

2. **FirebaseInvoiceService** (`lib/common/services/firebase_invoice_service.dart`)
   - Gère la sauvegarde dans Realtime Database
   - Upload des PDFs sur Firebase Storage
   - Téléchargement des PDFs
   - Suppression des factures et PDFs

### Écrans

1. **PdfViewerScreen** (`lib/features/invoicing/views/pdf_viewer_screen.dart`)
   - Affiche les PDFs
   - Permet le partage
   - Permet l'impression

2. **InvoiceHistoryScreen** (`lib/features/invoicing/views/invoice_history_screen.dart`)
   - Liste les factures
   - Permet de télécharger et visualiser les PDFs

## 🚀 Utilisation

### 1. Créer et sauvegarder une facture avec PDF

```dart
final invoiceService = FirebaseInvoiceService();

// Créer le modèle
final invoice = InvoiceModel(
  id: '',
  invoiceNumber: 'FACT-2026-001',
  invoiceDate: DateTime.now(),
  clientName: 'Client Test',
  clientAddress: '123 Rue Example\n75001 Paris',
  items: [
    InvoiceItem(
      description: 'Service',
      quantity: 2,
      unitPrice: 150.0,
    ),
  ],
  companyName: 'Mon Entreprise',
  companyAddress: '456 Avenue Test\n75002 Paris',
  companyPhone: '+33 1 23 45 67 89',
  companyEmail: 'contact@entreprise.fr',
  taxRate: 20.0,
);

// Sauvegarder avec génération automatique du PDF
final invoiceId = await invoiceService.saveInvoiceWithPdf(invoice);

if (invoiceId != null) {
  print('✅ Facture créée : $invoiceId');
} else {
  print('❌ Erreur lors de la création');
}
```

### 2. Télécharger et afficher un PDF

```dart
final invoiceService = FirebaseInvoiceService();

// Télécharger le PDF
final pdfFile = await invoiceService.downloadInvoicePdf(
  invoiceId,
  invoiceNumber,
);

if (pdfFile != null) {
  // Ouvrir le viewer
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PdfViewerScreen(
        pdfFile: pdfFile,
        title: invoiceNumber,
      ),
    ),
  );
}
```

### 3. Vérifier les limites

```dart
final invoiceService = FirebaseInvoiceService();

// Vérifier si l'utilisateur peut créer une facture
final canCreate = await invoiceService.canCreateInvoice();

if (!canCreate) {
  // Afficher message de limite atteinte
  // Rediriger vers écran d'abonnement
}

// Obtenir le nombre de factures restantes
final remaining = await invoiceService.getRemainingInvoices();

if (remaining == -1) {
  print('✨ Utilisateur Premium - Illimité');
} else {
  print('📊 Factures restantes : $remaining / 3');
}
```

## 📦 Structure Firebase

### Realtime Database

```
/invoices
  /{invoiceId}
    - userId: "abc123"
    - invoiceNumber: "FACT-2026-001"
    - clientName: "Client Test"
    - clientAddress: "..."
    - items: [...]
    - subtotal: 300.0
    - taxRate: 20.0
    - taxAmount: 60.0
    - total: 360.0
    - companyName: "Mon Entreprise"
    - companyAddress: "..."
    - pdfUrl: "https://firebasestorage.googleapis.com/..."
    - createdAt: 1234567890

/users
  /{userId}
    - invoiceCount: 2
    - isPremium: false
```

### Firebase Storage

```
/invoices
  /{userId}
    /{invoiceId}.pdf
```

## 🔧 Configuration requise

### packages

```yaml
dependencies:
  pdf: ^3.11.3
  printing: ^5.14.2
  firebase_storage: ^13.0.5
  firebase_database: ^12.1.1
  path_provider: ^2.1.5
```

### Firebase Storage Rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /invoices/{userId}/{invoiceId} {
      // L'utilisateur peut lire/écrire ses propres PDFs
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Realtime Database Rules

```json
{
  "rules": {
    "invoices": {
      "$invoiceId": {
        ".read": "auth != null && data.child('userId').val() == auth.uid",
        ".write": "auth != null && (!data.exists() || data.child('userId').val() == auth.uid)"
      }
    },
    "users": {
      "$userId": {
        ".read": "auth != null && auth.uid == $userId",
        ".write": "auth != null && auth.uid == $userId"
      }
    }
  }
}
```

## 🎨 Personnalisation du PDF

Le design du PDF peut être personnalisé dans `PdfGeneratorService` :

- **Couleurs** : Modifier les `PdfColors` dans `_buildHeader()`
- **Police** : Ajouter des fonts personnalisées
- **Logo** : Ajouter une image dans l'en-tête
- **Mise en page** : Modifier les `pw.Widget` dans `_buildInvoicePage()`

## ⚠️ Gestion des erreurs

### Erreurs courantes

1. **Storage non configuré**
   - Erreur : `storage/bucket-not-configured`
   - Solution : Activer Firebase Storage dans la console

2. **Fichier PDF vide**
   - Erreur : `Le fichier PDF généré est vide`
   - Solution : Vérifier que InvoiceModel contient des données valides

3. **Limite atteinte**
   - Erreur : `LIMIT_REACHED`
   - Solution : Upgrade vers Premium ou attendre le reset

4. **Permission refusée**
   - Erreur : `Permission denied`
   - Solution : Vérifier les règles de sécurité Firebase

## 🔄 Workflow complet

```
1. Utilisateur crée une facture
   ↓
2. InvoiceModel créé avec toutes les données
   ↓
3. saveInvoiceWithPdf() appelé
   ↓
4. PdfGeneratorService génère le PDF
   ↓
5. Fichier temporaire créé
   ↓
6. PDF uploadé sur Firebase Storage
   ↓
7. URL du PDF récupérée
   ↓
8. Métadonnées sauvegardées dans Realtime Database
   ↓
9. Compteur de factures incrémenté
   ↓
10. Fichier temporaire supprimé
   ↓
11. ID de la facture retourné
```

## 📱 Interface utilisateur

### Écran d'historique

- Liste des factures
- Icône PDF rouge
- Menu avec options :
  - 👁️ Voir la facture
  - 📥 Télécharger PDF
  - 📤 Partager
  - 🗑️ Supprimer

### Écran de visualisation

- Affichage du PDF complet
- Boutons :
  - Partager
  - Imprimer
  - Retour

## 🎯 Prochaines améliorations

- [ ] Templates de PDF personnalisables
- [ ] Ajout de logo d'entreprise
- [ ] Signature électronique
- [ ] Envoi par email automatique
- [ ] Export en batch (ZIP)
- [ ] Statistiques sur les factures

## 📚 Ressources

- [Package PDF](https://pub.dev/packages/pdf)
- [Package Printing](https://pub.dev/packages/printing)
- [Firebase Storage](https://firebase.google.com/docs/storage)
- [Firebase Realtime Database](https://firebase.google.com/docs/database)

## 🤝 Support

Pour toute question ou problème, consultez :
- Les logs avec `debugPrint`
- Les exemples dans `invoice_pdf_usage_example.dart`
- La documentation Firebase
