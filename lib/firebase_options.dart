import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'

    show defaultTargetPlatform, kIsWeb, TargetPlatform;

///
/// Example:
/// ```dart
/// // ...
/// await Firebase.initializeApp(
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA6ZwwUtqOGllTfXw6EgJWUVQY8zkx-_4E',
    appId: '1:1085924811040:web:9362ceb92a758cf8a33745',
    messagingSenderId: '1085924811040',
    projectId: 'syra-ai-b562f',
    authDomain: 'syra-ai-b562f.firebaseapp.com',
    storageBucket: 'syra-ai-b562f.firebasestorage.app',
    measurementId: 'G-XBNP3NPY9P',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4khfl9h4SRdaQdBGFO6cj9ILqm0yXq-U',
    appId: '1:1085924811040:android:265fb083367285a7a33745',
    messagingSenderId: '1085924811040',
    projectId: 'syra-ai-b562f',
    storageBucket: 'syra-ai-b562f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCK5j8-NNIzQbUtK0roQzmJbugDFjfDSH4',
    appId: '1:1085924811040:ios:9a5ea2ff4da1a80aa33745',
    messagingSenderId: '1085924811040',
    projectId: 'syra-ai-b562f',
    storageBucket: 'syra-ai-b562f.firebasestorage.app',
    iosBundleId: 'com.ariksoftware.syra.RunnerTests',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCK5j8-NNIzQbUtK0roQzmJbugDFjfDSH4',
    appId: '1:1085924811040:ios:285a81600f9c89aaa33745',
    messagingSenderId: '1085924811040',
    projectId: 'syra-ai-b562f',
    storageBucket: 'syra-ai-b562f.firebasestorage.app',
    iosBundleId: 'com.example.syraNew',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA6ZwwUtqOGllTfXw6EgJWUVQY8zkx-_4E',
    appId: '1:1085924811040:web:bcad791898b253cba33745',
    messagingSenderId: '1085924811040',
    projectId: 'syra-ai-b562f',
    authDomain: 'syra-ai-b562f.firebaseapp.com',
    storageBucket: 'syra-ai-b562f.firebasestorage.app',
    measurementId: 'G-B1B6J5DGQ6',
  );
}
