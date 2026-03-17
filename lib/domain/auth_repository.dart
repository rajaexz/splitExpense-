import 'dart:io';

import '../data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String name, String password);
  Future<bool> isUsernameAvailable(String username);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithFacebook();
  Future<String> verifyPhoneNumber(String phoneNumber);
  Future<UserModel> signInWithPhoneCredential(String verificationId, String smsCode);
  Future<UserModel> updateProfile({String? name, File? photoFile, String? phone});
  Future<String?> getProfilePhone(String uid);
  Stream<UserModel?> authStateChanges();
}
