import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final firebase_auth.FirebaseAuth firebaseAuth;
  final FirebaseStorage storage;
  final FirebaseFirestore firestore;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.firebaseAuth,
    required this.storage,
    required this.firestore,
  });
  
  @override
  Future<UserModel> login(String email, String password) async {
    final user = await remoteDataSource.login(email, password);
    await _syncUserToFirestore(user);
    return user;
  }
  
  @override
  Future<bool> isUsernameAvailable(String username) async {
    if (username.trim().isEmpty) return false;
    final normalized = username.trim();
    final doc = await firestore.collection('usernames').doc(normalized).get();
    return !doc.exists;
  }

  @override
  Future<UserModel> register(String email, String name, String password) async {
    final username = name.trim();
    final available = await isUsernameAvailable(username);
    if (!available) {
      throw Exception('Username "$username" is already taken. Choose a unique one like Raja123.');
    }
    final user = await remoteDataSource.register(email, username, password);
    await _syncUserToFirestore(user);
    return user;
  }
  
  @override
  Future<void> logout() async {
    return await remoteDataSource.logout();
  }
  
  @override
  Future<UserModel?> getCurrentUser() async {
    return await remoteDataSource.getCurrentUser();
  }
  
  @override
  Future<UserModel> signInWithGoogle() async {
    final user = await remoteDataSource.signInWithGoogle();
    await _syncUserToFirestore(user);
    return user;
  }
  
  @override
  Future<UserModel> signInWithFacebook() async {
    return await remoteDataSource.signInWithFacebook();
  }

  @override
  Future<String> verifyPhoneNumber(String phoneNumber) async {
    return await remoteDataSource.verifyPhoneNumber(phoneNumber);
  }

  @override
  Future<UserModel> signInWithPhoneCredential(String verificationId, String smsCode) async {
    final user = await remoteDataSource.signInWithPhoneCredential(verificationId, smsCode);
    await _syncUserToFirestore(user);
    return user;
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    File? photoFile,
    String? phone,
    String? upiId,
  }) async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null) throw Exception('Not logged in');

    String? photoUrl;
    if (photoFile != null) {
      final ref = storage.ref().child('users/$userId/profile/avatar.jpg');
      await ref.putFile(photoFile);
      photoUrl = await ref.getDownloadURL();
    }

    final user = await remoteDataSource.updateProfile(name: name, photoUrl: photoUrl);

    // Sync to Firestore for app-wide consistency (phone stored here for email-login users)
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['avatarUrl'] = photoUrl;
      if (phone != null) updates['phone'] = phone.isEmpty ? null : phone;
      if (upiId != null) updates['upiId'] = upiId.trim().isEmpty ? null : upiId.trim();
      final userDoc = await firestore.collection('users').doc(userId).get();
      final oldName = userDoc.data()?['name'] as String?;
      if (oldName != null && oldName.trim().isNotEmpty && oldName != name) {
        await firestore.collection('usernames').doc(oldName.trim()).delete();
      }
      await firestore.collection('users').doc(userId).set(updates, SetOptions(merge: true));
      if (name != null && name.trim().isNotEmpty) {
        await firestore.collection('usernames').doc(name.trim()).set(
          {'userId': userId},
          SetOptions(merge: true),
        );
      }
    } catch (_) {
      // Non-fatal: Auth update succeeded
    }

    return user;
  }

  Future<void> _syncUserToFirestore(UserModel user) async {
    try {
      final updates = <String, dynamic>{
        'email': user.email,
        'name': user.name,
        'avatarUrl': user.photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        updates['phone'] = user.phoneNumber;
      }
      await firestore.collection('users').doc(user.uid).set(
            updates,
            SetOptions(merge: true),
          );
      if (user.name != null && user.name!.isNotEmpty) {
        final normalized = user.name!.trim();
        await firestore.collection('usernames').doc(normalized).set(
          {'userId': user.uid},
          SetOptions(merge: true),
        );
      }
    } catch (_) {
      // Non-fatal: Auth succeeded, Firestore sync can retry later
    }
  }

  @override
  Future<String?> getProfilePhone(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      return doc.data()?['phone'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getUpiId(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      return doc.data()?['upiId'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return remoteDataSource.authStateChanges();
  }
}
