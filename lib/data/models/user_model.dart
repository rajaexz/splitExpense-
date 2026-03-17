import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String? phoneNumber;
  final String? name;
  final String? photoUrl;

  const UserModel({
    required this.uid,
    required this.email,
    this.phoneNumber,
    this.name,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [uid, email, phoneNumber, name, photoUrl];

  UserModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? name,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
