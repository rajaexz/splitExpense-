import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import '../../core/base/base_cubit.dart';
import '../../domain/auth_repository.dart';
import '../../data/models/user_model.dart';

part 'auth_state.dart';

class AuthCubit extends BaseCubit<AuthState> {
  final AuthRepository authRepository;
  StreamSubscription<UserModel?>? _authStateSubscription;
  
  AuthCubit({required this.authRepository}) : super(AuthInitial()) {
    // Listen to auth state changes
    _authStateSubscription = authRepository.authStateChanges().listen((user) {
      if (!isClosed) {
        if (user != null) {
          emit(AuthSuccess(user));
        } else {
          emit(AuthInitial());
        }
      }
    });
  }
  
  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
  
  Future<void> login(String email, String password) async {
    if (isClosed) return;
    emit(AuthLoading());
    try {
      final user = await authRepository.login(email, password);
      if (!isClosed) {
        emit(AuthSuccess(user));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthError(e.toString()));
      }
    }
  }
  
  Future<bool> checkUsernameAvailable(String username) async {
    try {
      return await authRepository.isUsernameAvailable(username);
    } catch (_) {
      return false;
    }
  }

  Future<void> register(String email, String name, String password) async {
    if (isClosed) return;
    emit(AuthLoading());
    try {
      final user = await authRepository.register(email, name, password);
      if (!isClosed) {
        emit(AuthSuccess(user));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthError(e.toString()));
      }
    }
  }
  
  Future<void> logout() async {
    if (isClosed) return;
    try {
      await authRepository.logout();
      if (!isClosed) {
        emit(AuthInitial());
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthError(e.toString()));
      }
    }
  }
  
  Future<void> signInWithGoogle() async {
    if (isClosed) return;
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithGoogle();
      if (!isClosed) {
        emit(AuthSuccess(user));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthError(e.toString()));
      }
    }
  }
  
  Future<void> signInWithFacebook() async {
    if (isClosed) return;
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithFacebook();
      if (!isClosed) {
        emit(AuthSuccess(user));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthError(e.toString()));
      }
    }
  }

  Future<void> verifyPhone(String phoneNumber) async {
    if (isClosed) return;
    emit(AuthLoading());
    try {
      final result = await authRepository.verifyPhoneNumber(phoneNumber);
      if (isClosed) return;
      if (result == 'AUTO_VERIFIED') {
        // User was auto-verified, authStateChanges will emit AuthSuccess
        return;
      }
      emit(AuthPhoneCodeSent(result, phoneNumber));
    } catch (e) {
      if (!isClosed) {
        emit(AuthError(e.toString()));
      }
    }
  }

  Future<void> signInWithPhoneCredential(String verificationId, String smsCode) async {
    if (isClosed) return;
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithPhoneCredential(verificationId, smsCode);
      if (!isClosed) {
        emit(AuthSuccess(user));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthError(e.toString()));
      }
    }
  }

  void resetPhoneVerification() {
    if (!isClosed) emit(AuthInitial());
  }

  Future<String?> getProfilePhone(String uid) async {
    try {
      return await authRepository.getProfilePhone(uid);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile({
    String? name,
    File? photoFile,
    String? phone,
    String? upiId,
  }) async {
    if (isClosed) return;
    try {
      final user = await authRepository.updateProfile(
        name: name,
        photoFile: photoFile,
        phone: phone,
        upiId: upiId,
      );
      if (!isClosed) {
        emit(AuthSuccess(user));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthError(e.toString()));
      }
    }
  }

  Future<String?> getUpiId(String uid) async {
    try {
      return await authRepository.getUpiId(uid);
    } catch (_) {
      return null;
    }
  }

  Future<void> checkAuthStatus() async {
    if (isClosed) return;
    try {
      final user = await authRepository.getCurrentUser();
      if (!isClosed) {
        if (user != null) {
          emit(AuthSuccess(user));
        } else {
          emit(AuthInitial());
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthError(e.toString()));
      }
    }
  }
}

