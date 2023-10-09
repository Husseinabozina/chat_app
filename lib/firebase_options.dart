// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyA_Kj9-Cjm9XAwSvvZph5X-NA_XCXTGoms',
    appId: '1:805049719093:web:4ac86e9ce84098b4d8d47c',
    messagingSenderId: '805049719093',
    projectId: 'chatapp2-29a9e',
    authDomain: 'chatapp2-29a9e.firebaseapp.com',
    storageBucket: 'chatapp2-29a9e.appspot.com',
    measurementId: 'G-5J8XSYKGBG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLq0oJDw9XURFs6a2NZbrg-ulLas5EJtY',
    appId: '1:805049719093:android:e24fc45ec9b5b56fd8d47c',
    messagingSenderId: '805049719093',
    projectId: 'chatapp2-29a9e',
    storageBucket: 'chatapp2-29a9e.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzS42-lmC5vVpVxl_RycHeV3BuTP9If5s',
    appId: '1:805049719093:ios:c880b7f132734345d8d47c',
    messagingSenderId: '805049719093',
    projectId: 'chatapp2-29a9e',
    storageBucket: 'chatapp2-29a9e.appspot.com',
    iosClientId: '805049719093-80fcn10k37pv8c3jtehtnl9v6h0pjsik.apps.googleusercontent.com',
    iosBundleId: 'com.example.chatApp3',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBzS42-lmC5vVpVxl_RycHeV3BuTP9If5s',
    appId: '1:805049719093:ios:c880b7f132734345d8d47c',
    messagingSenderId: '805049719093',
    projectId: 'chatapp2-29a9e',
    storageBucket: 'chatapp2-29a9e.appspot.com',
    iosClientId: '805049719093-80fcn10k37pv8c3jtehtnl9v6h0pjsik.apps.googleusercontent.com',
    iosBundleId: 'com.example.chatApp3',
  );
}