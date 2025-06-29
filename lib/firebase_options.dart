// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
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
    apiKey: 'AIzaSyBHSvm22PZ4JqYIiHaqegab-KA_j-BdxSc',
    appId: '1:241066319910:web:c40779d046ed02adeb86e7',
    messagingSenderId: '241066319910',
    projectId: 'smartattend-5ab39',
    authDomain: 'smartattend-5ab39.firebaseapp.com',
    storageBucket: 'smartattend-5ab39.firebasestorage.app',
    measurementId: 'G-XP3FWSK4HP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDyv2k9sE2CLtxnlz_HBKkPUxUpsh9W19c',
    appId: '1:241066319910:android:f62bdc7cb2e6b455eb86e7',
    messagingSenderId: '241066319910',
    projectId: 'smartattend-5ab39',
    storageBucket: 'smartattend-5ab39.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAXFOF0O_l6qVHJvnd--If67lUCKDuXO-w',
    appId: '1:241066319910:ios:62bc578048bcee21eb86e7',
    messagingSenderId: '241066319910',
    projectId: 'smartattend-5ab39',
    storageBucket: 'smartattend-5ab39.firebasestorage.app',
    iosBundleId: 'com.example.smartAttend',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAXFOF0O_l6qVHJvnd--If67lUCKDuXO-w',
    appId: '1:241066319910:ios:62bc578048bcee21eb86e7',
    messagingSenderId: '241066319910',
    projectId: 'smartattend-5ab39',
    storageBucket: 'smartattend-5ab39.firebasestorage.app',
    iosBundleId: 'com.example.smartAttend',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBHSvm22PZ4JqYIiHaqegab-KA_j-BdxSc',
    appId: '1:241066319910:web:3caf3ac595f226f7eb86e7',
    messagingSenderId: '241066319910',
    projectId: 'smartattend-5ab39',
    authDomain: 'smartattend-5ab39.firebaseapp.com',
    storageBucket: 'smartattend-5ab39.firebasestorage.app',
    measurementId: 'G-3EJCDDSCTP',
  );
}
