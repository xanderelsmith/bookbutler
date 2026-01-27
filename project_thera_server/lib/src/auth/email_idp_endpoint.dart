import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
class EmailIdpEndpoint extends EmailIdpBaseEndpoint {
  @override
  Future<AuthSuccess> login(
    Session session, {
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    var result = await super.login(session, email: email, password: password);

    return result;
  }
}
