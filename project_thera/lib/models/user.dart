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

  @override
  String toString() {
    return 'UserModel(email: $email, authUserId: $authUserId, nickname: $nickname, bio: $bio)';
  }
}
