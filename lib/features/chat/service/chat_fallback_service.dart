// lib/features/chat/services/chat_fallback_service.dart
class ChatFallbackService {
  final Map<String, String> _faq = {
    'comment créer devis vocal': 
        '🎤 Pour créer un devis avec la voix :\n\n'
        '1. Appuyez sur le micro 🎤 en bas de l\'écran\n'
        '2. Dites "Créer un devis pour [client]" \n'
        '3. L\'IA transcrit automatiquement\n'
        '4. Vérifiez les informations\n'
        '5. Appuyez sur "Générer PDF"',
    
    'prix abonnement': 
        '💰 Nos offres :\n\n'
        '• Gratuit : 3 factures/mois\n'
        '• ESSENTIEL : 200 factures/mois (19,99€)\n'
        '• PRO : 500 factures/mois (49,99€)\n'
        '• ILLIMITÉ : factures illimitées (79,99€)\n\n'
        'Voir détails dans l\'onglet "Abonnement"',
    
    'supprimer devis': 
        '🗑️ Supprimer un devis :\n\n'
        '1. Allez dans "Historique"\n'
        '2. Glissez le devis vers la gauche\n'
        '3. Confirmez la suppression',
    
    'modifier devis': 
        '✏️ Modifier un devis :\n\n'
        '1. Ouvrez le devis dans "Historique"\n'
        '2. Appuyez sur "Modifier"\n'
        '3. Faites vos modifications\n'
        '4. Régénérez le PDF',
    
    'problème microphone': 
        '🎙️ Problème de micro ?\n\n'
        'Solutions :\n'
        '• Vérifiez les permissions dans les paramètres\n'
        '• Redémarrez l\'application\n'
        '• Mettez à jour l\'app',
  };

  String? getAnswer(String question) {
    final lowerQuestion = question.toLowerCase();
    
    for (final entry in _faq.entries) {
      if (lowerQuestion.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}