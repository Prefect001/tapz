import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions not configured for this platform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAPvxHK5_4jJVAuIYOaqcAA8pDk7NtyvP0',
    appId: '1:762424845985:android:7bec8fea9e4efc419fb2e0',
    messagingSenderId: '762424845985',
    projectId: 'carpark-df96f',
    storageBucket: 'carpark-df96f.firebasestorage.app',
  );
}