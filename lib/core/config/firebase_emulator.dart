import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Set `--dart-define=USE_FIREBASE_EMULATOR=true` when using [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite) locally (no cloud deploy needed).
///
/// Optional: `--dart-define=EMULATOR_HOST=192.168.1.5` for a physical device on the same Wi‑Fi.
///
/// Port defines must match [firebase.json] `emulators.*.port`. Override if you change `firebase.json`:
/// `--dart-define=FIRESTORE_EMULATOR_PORT=56273` (same values as in json).
const bool kUseFirebaseEmulator = bool.fromEnvironment(
  'USE_FIREBASE_EMULATOR',
  defaultValue: false,
);

const String _emulatorHostOverride = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: '',
);

// Defaults = firebase.json emulators (56273–56276). Change json + these defaults together, or use dart-define.
const int _kFirestoreEmulatorPort = int.fromEnvironment(
  'FIRESTORE_EMULATOR_PORT',
  defaultValue: 56273,
);
const int _kAuthEmulatorPort = int.fromEnvironment(
  'AUTH_EMULATOR_PORT',
  defaultValue: 56274,
);
const int _kFunctionsEmulatorPort = int.fromEnvironment(
  'FUNCTIONS_EMULATOR_PORT',
  defaultValue: 56275,
);
const int _kStorageEmulatorPort = int.fromEnvironment(
  'STORAGE_EMULATOR_PORT',
  defaultValue: 56276,
);

/// Call right after [Firebase.initializeApp], before any other Firebase usage.
Future<void> connectFirebaseEmulatorsIfEnabled() async {
  if (!kUseFirebaseEmulator) return;

  final host = _resolveEmulatorHost();

  await FirebaseAuth.instance.useAuthEmulator(host, _kAuthEmulatorPort);
  FirebaseFirestore.instance.useFirestoreEmulator(host, _kFirestoreEmulatorPort);
  await FirebaseStorage.instance.useStorageEmulator(host, _kStorageEmulatorPort);
  FirebaseFunctions.instance.useFunctionsEmulator(host, _kFunctionsEmulatorPort);
}

String _resolveEmulatorHost() {
  if (_emulatorHostOverride.isNotEmpty) return _emulatorHostOverride;
  if (kIsWeb) return 'localhost';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return 'localhost';
}
