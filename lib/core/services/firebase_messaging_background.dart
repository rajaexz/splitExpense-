import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level handler - MUST be top-level (not a class method) for background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background/terminated - system shows notification automatically.
  // We can't navigate here; handle in getInitialMessage when app opens.
}
