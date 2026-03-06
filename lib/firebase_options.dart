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
    storageBucket: 'gs://facturezen-558b0.firebasestorage.app'
  );

  // Configuration iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBiS7H_6ipVVOsT6tsBtgVi6WlReCW_zUc',
    appId: '1:664151721016:ios:60650982293da7184152cd',
    messagingSenderId: '664151721016',
    projectId: 'facturezen-558b0',
    databaseURL: 'https://facturezen-558b0-default-rtdb.firebaseio.com',
    iosBundleId: 'com.example.factureZen',
    storageBucket: 'facturezen-558b0.firebasestorage.app',
  );
}