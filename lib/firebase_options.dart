import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBqIt5CBrO0iuryOr10rkuYRWkKASIzhvM',
    appId: '1:221749572081:web:d042f1132c35d1b34c1450',
    messagingSenderId: '221749572081',
    projectId: 'da-saad-profiling',
    authDomain: 'da-saad-profiling.firebaseapp.com',
    storageBucket: 'da-saad-profiling.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBqIt5CBrO0iuryOr10rkuYRWkKASIzhvM',
    appId: '1:221749572081:android:d042f1132c35d1b34c1450',
    messagingSenderId: '221749572081',
    projectId: 'da-saad-profiling',
    storageBucket: 'da-saad-profiling.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCj8eI2MH-cyEYfhc0yl-UMZKtGE13Mxn4',
    appId: '1:221749572081:ios:26ce19781a849d9b4c1450',
    messagingSenderId: '221749572081',
    projectId: 'da-saad-profiling',
    storageBucket: 'da-saad-profiling.firebasestorage.app',
    iosBundleId: 'com.example.daProject1',
  );
}
