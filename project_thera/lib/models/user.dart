import 'package:project_thera_client/project_thera_client.dart';

class UserModel {
  const UserModel({
    required this.email,
    required this.authUserId,
    this.nickname,
    this.bio,
  });

  final String email;
  final UuidValue authUserId;
  final String? nickname;
  final String? bio;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'authUserId': authUserId.uuid,
      'nickname': nickname,
      'bio': bio,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] as String,
      authUserId: UuidValue.fromString(json['authUserId'] as String),
      nickname: json['nickname'] as String?,
      bio: json['bio'] as String?,
    );
  }

  @override
  String toString() {
    return 'UserModel(email: $email, authUserId: $authUserId, nickname: $nickname, bio: $bio)';
  }
}
