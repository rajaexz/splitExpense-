import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/config/firebase_emulator.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String name, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithFacebook();
  Future<String> verifyPhoneNumber(String phoneNumber);
  Future<UserModel> signInWithPhoneCredential(String verificationId, String smsCode);
  Future<UserModel> updateProfile({String? name, String? photoUrl});
  Stream<UserModel?> authStateChanges();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  
  AuthRemoteDataSourceImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;
  
  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Login failed: User is null');
      }
      
      return _userFromFirebase(credential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }
  
  @override
  Future<UserModel> register(String email, String name, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Registration failed: User is null');
      }
      
      // Update display name
      await credential.user!.updateDisplayName(name);
      await credential.user!.reload();
      
      return _userFromFirebase(credential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      // On some Android emulator images, Google Play broker throws SecurityException.
      // Ignore Google sign-out failure if Play services is not available.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }
  
  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _userFromFirebase(user);
  }
  
  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      if (kUseFirebaseEmulator) {
        throw Exception(
          'Google Sign-In is disabled in emulator mode. Use email/phone login for local testing.',
        );
      }
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw Exception('Google sign in failed: User is null');
      }
      
      return _userFromFirebase(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }
  
  @override
  Future<UserModel> signInWithFacebook() async {
    // TODO: Implement Facebook sign in when facebook_auth package is added
    throw UnimplementedError('Facebook sign in is not yet implemented');
  }

  @override
  Future<String> verifyPhoneNumber(String phoneNumber) async {
    final completer = Completer<String>();
    final normalized = phoneNumber.startsWith('+') ? phoneNumber : '+$phoneNumber';

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: normalized,
      verificationCompleted: (credential) async {
        if (!completer.isCompleted) {
          await _firebaseAuth.signInWithCredential(credential);
          completer.complete('AUTO_VERIFIED');
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(_handleFirebaseAuthException(e));
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    return completer.future;
  }

  @override
  Future<UserModel> signInWithPhoneCredential(String verificationId, String smsCode) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Phone sign in failed: User is null');
      }

      return _userFromFirebase(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Phone sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateProfile({String? name, String? photoUrl}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('Not logged in');
    if (name == null && photoUrl == null) return _userFromFirebase(user);

    try {
      await user.updateProfile(
        displayName: name ?? user.displayName,
        photoURL: photoUrl ?? user.photoURL,
      );
      await user.reload();
      return _userFromFirebase(_firebaseAuth.currentUser!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _userFromFirebase(firebaseUser);
    });
  }
  
  UserModel _userFromFirebase(firebase_auth.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      phoneNumber: user.phoneNumber,
      name: user.displayName,
      photoUrl: user.photoURL,
    );
  }
  
  Exception _handleFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'email-already-in-use':
        return Exception('An account already exists for that email.');
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'invalid-email':
        return Exception('The email address is invalid.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many requests. Please try again later.');
      case 'operation-not-allowed':
        return Exception('This operation is not allowed.');
      case 'invalid-verification-code':
        return Exception('Invalid verification code. Please try again.');
      case 'invalid-verification-id':
        return Exception('Verification expired. Please request a new code.');
      case 'invalid-phone-number':
        return Exception('Invalid phone number. Use country code (e.g. +92...).');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }
}
