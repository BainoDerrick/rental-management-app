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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web {
    return FirebaseOptions(
      apiKey: "AIzaSyAmSSMCH8YfFkrLdM7g3AaZw9rdOz6IzGY",
      authDomain: "rental-management-app-b0b7d.firebaseapp.com",
      projectId: "rental-management-app-b0b7d",
      storageBucket: "rental-management-app-b0b7d.firebasestorage.app",
      messagingSenderId: "280061620898",
      appId: "1:280061620898:web:bd1c798c2492e6d6ab5dfb",
    );
  }

  static FirebaseOptions get android {
    return FirebaseOptions(
      apiKey: "AIzaSyBX9GTEKZqQ9LF6RyI5QuvPN5Z9yzRidoo",
      authDomain: "rental-management-app-b0b7d.firebaseapp.com",
      projectId: "rental-management-app-b0b7d",
      storageBucket: "rental-management-app-b0b7d.firebasestorage.app",
      messagingSenderId: "280061620898",
      appId: "1:280061620898:web:bd1c798c2492e6d6ab5dfb",
    );
  }
}
