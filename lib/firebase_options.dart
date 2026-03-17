// File generated using data from google-services.json
// Note: iOS appId needs to be obtained from Firebase Console
// Go to Firebase Console → Project Settings → Your iOS app → Copy the App ID

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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        // Check if iOS App ID is still a placeholder
        if (ios.appId.contains('YOUR_IOS_APP_ID_HASH')) {
          throw UnsupportedError(
            'iOS Firebase configuration is incomplete. '
            'Please get the iOS App ID from Firebase Console:\n'
            '1. Go to https://console.firebase.google.com/\n'
            '2. Select project: chatter-dc034\n'
            '3. Go to Project Settings → Your iOS app\n'
            '4. Copy the App ID (format: 1:493504389166:ios:XXXXXXXX)\n'
            '5. Update firebase_options.dart line 64 with the actual App ID\n'
            'Or run: flutterfire configure',
          );
        }
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDHNyG3MKwz5FPkTAxItOkxE5fce865Hvk',
    appId: '1:493504389166:android:a986b6b83503dc3c107fbf',
    messagingSenderId: '493504389166',
    projectId: 'chatter-dc034',
    storageBucket: 'chatter-dc034.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDHNyG3MKwz5FPkTAxItOkxE5fce865Hvk',
    appId: '1:493504389166:ios:03964d604f02951c107fbf', // TODO: Replace with actual iOS App ID from Firebase Console
    messagingSenderId: '493504389166',
    projectId: 'chatter-dc034',
    storageBucket: 'chatter-dc034.firebasestorage.app',
    iosBundleId: 'com.example.jobcrak',
  );
}

