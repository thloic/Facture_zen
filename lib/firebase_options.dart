import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web non supporté pour le moment');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Plateforme non supportée');
    }
  }

  // Configuration Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDOU72PP_rlXxP-6YTAG5RQBce3zf91nEY',  // ⬅️ À TROUVER
    appId: '1:664151721016:android:350facd0997f58954152cd',    // ⬅️ À TROUVER
    messagingSenderId: '664151721016', // ⬅️ À TROUVER
    projectId: 'facturezen',
    databaseURL: 'https://facturezen-558b0-default-rtdb.firebaseio.com',
  );

  // Configuration iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REMPLACE_PAR_TON_API_KEY_IOS',
    appId: 'REMPLACE_PAR_TON_APP_ID_IOS',
    messagingSenderId: 'REMPLACE_PAR_TON_SENDER_ID',
    projectId: 'facturezen',
    databaseURL: 'https://facturezen-558b0-default-rtdb.firebaseio.com',
    iosBundleId: 'com.example.factureZen',
  );
}