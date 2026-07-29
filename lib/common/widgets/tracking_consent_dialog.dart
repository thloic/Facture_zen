import 'package:flutter/material.dart';

import '../services/consent_service.dart';

/// Popup de consentement au tracking publicitaire, affichée une seule fois
/// (premier lancement) sur Android — iOS utilise déjà App Tracking
/// Transparency pour ce même consentement.
class TrackingConsentDialog {
  static Future<bool> showIfNeeded(BuildContext context) async {
    final service = ConsentService();
    if (await service.hasBeenAsked()) {
      return service.isGranted();
    }

    if (!context.mounted) return false;

    final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Partage de données avec nos partenaires'),
            content: const Text(
              "Nous aimerions partager certaines données d'usage avec nos "
              "partenaires publicitaires (Google, Meta) pour mesurer et "
              "améliorer nos campagnes. Vous pouvez refuser sans que cela "
              "affecte l'utilisation de l'application.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Refuser'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Accepter'),
              ),
            ],
          ),
        ) ??
        false;

    await service.setConsent(accepted);
    return accepted;
  }
}
