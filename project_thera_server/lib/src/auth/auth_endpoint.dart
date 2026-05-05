import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// Custom endpoint for direct account creation without email verification.
class AuthEndpoint extends Endpoint {
  /// Creates a user account directly with email and password.
  /// This bypasses email verification for development purposes.
  Future<String> createAccountDirectly(
    Session session, {
    required String email,
    required String password,
  }) async {
    try {
      // Get Email IDP admin
      final emailAdmin = AuthServices.instance.emailIdp.admin;

      // Check if account already exists
      final existingAccount = await emailAdmin.findAccount(
        session,
        email: email,
      );

      if (existingAccount != null) {
        throw Exception('An account with this email already exists.');
      }

      // Create a new AuthUser
      final authUser = await AuthServices.instance.authUsers.create(session);

      // Create the email authentication for the new user
      await emailAdmin.createEmailAuthentication(
        session,
        authUserId: authUser.id,
        email: email,
        password: password,
      );

      session.log('User account created directly: $email');

      return 'Account created successfully';
    } catch (e) {
      session.log('Error creating account: $e');
      rethrow;
    }
  }
}
