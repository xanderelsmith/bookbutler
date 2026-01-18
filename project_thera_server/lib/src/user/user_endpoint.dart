import 'package:serverpod_auth_idp_server/core.dart';

import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'dart:developer' as developer;

class UserEndpoint extends Endpoint {
  Future<User?> getCurrentUser(Session session) async {
    final authInfo = session.authenticated;
    if (authInfo == null) return null;

    // Use authUserId (UuidValue) and convert to String to match your model
    final authUserIdString = authInfo.authUserId;

    return await User.db.findFirstRow(
      session,
      where: (u) => u.authUserId.equals(authUserIdString),
      // AuthUser is the module model linked via relation
      include: User.include(authUser: AuthUser.include()),
    );
  }

  Future<User> updateProfile(
    Session session, {
    String? username,
    String? bio,
  }) async {
    final authInfo = session.authenticated;
    developer.log('updateProfile authInfo: $authInfo');
    if (authInfo == null) {
      developer.log('User must be authenticated');
      throw Exception('User must be authenticated');
    }

    final authUserIdString = authInfo.authUserId;
    var user = await User.db.findFirstRow(
      session,
      where: (u) => u.authUserId.equals(authInfo.authUserId),
    );

    final now = DateTime.now().toUtc();

    if (user == null) {
      user = User(
        authUserId: authUserIdString,
        username: username,
        bio: bio,
        createdAt: now,
        updatedAt: now,
      );
      user = await User.db.insertRow(session, user);
    } else {
      user.username = username ?? user.username;
      user.bio = bio ?? user.bio;
      user.updatedAt = now;
      user = await User.db.updateRow(session, user);
    }

    return (await User.db.findById(
      session,
      user.id!,
      include: User.include(authUser: AuthUser.include()),
    ))!;
  }
}
