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
    apiKey: 'AIzaSyBYOc1krSL1sxwYOOy4OOHZFKLYzQy6hbA',
    appId: '1:844484131381:web:76c5682a87fabb0e6d0f7c',
    messagingSenderId: '844484131381',
    projectId: 'jointventure-91001',
    authDomain: 'jointventure-91001.firebaseapp.com',
    storageBucket: 'jointventure-91001.appspot.com',
    measurementId: 'G-BW6X3BGW6F',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD1teJTD3GlfJwqN4KLqOsm90KP5SJTMkU',
    appId: '1:844484131381:ios:4e98f7e8e770604a6d0f7c',
    messagingSenderId: '844484131381',
    projectId: 'jointventure-91001',
    storageBucket: 'jointventure-91001.appspot.com',
    iosBundleId: 'com.example.jointventureapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD1teJTD3GlfJwqN4KLqOsm90KP5SJTMkU',
    appId: '1:844484131381:ios:4e98f7e8e770604a6d0f7c',
    messagingSenderId: '844484131381',
    projectId: 'jointventure-91001',
    storageBucket: 'jointventure-91001.appspot.com',
    iosBundleId: 'com.example.jointventureapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBYOc1krSL1sxwYOOy4OOHZFKLYzQy6hbA',
    appId: '1:844484131381:web:22e9b6a7dbd925e16d0f7c',
    messagingSenderId: '844484131381',
    projectId: 'jointventure-91001',
    authDomain: 'jointventure-91001.firebaseapp.com',
    storageBucket: 'jointventure-91001.appspot.com',
    measurementId: 'G-ZRHBP5Z2LL',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDCQt9s9t_4hLHTbvLxR1iYe6jFMF65Jh4',
    appId: '1:844484131381:android:a9337df6819c96246d0f7c',
    messagingSenderId: '844484131381',
    projectId: 'jointventure-91001',
    storageBucket: 'jointventure-91001.appspot.com',
  );

}