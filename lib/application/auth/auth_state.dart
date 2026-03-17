part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthPhoneCodeSent extends AuthState {
  final String verificationId;
  final String phoneNumber;

  const AuthPhoneCodeSent(this.verificationId, this.phoneNumber);

  @override
  List<Object?> get props => [verificationId, phoneNumber];
}

class AuthSuccess extends AuthState {
  final UserModel user;
  
  const AuthSuccess(this.user);
  
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}

