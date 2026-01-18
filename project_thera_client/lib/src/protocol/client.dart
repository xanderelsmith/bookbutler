/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:project_thera_client/src/protocol/greetings/greeting.dart'
    as _i5;
import 'package:project_thera_client/src/protocol/leaderboardentry/leaderboardentry.dart'
    as _i6;
import 'package:project_thera_client/src/protocol/notifications/userdevice.dart'
    as _i7;
import 'package:project_thera_client/src/protocol/user/user.dart' as _i8;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as _i9;
import 'protocol.dart' as _i10;

/// Custom endpoint for direct account creation without email verification.
/// {@category Endpoint}
class EndpointAuth extends _i1.EndpointRef {
  EndpointAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Creates a user account directly with email and password.
  /// This bypasses email verification for development purposes.
  _i2.Future<String> createAccountDirectly({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<String>(
    'auth',
    'createAccountDirectly',
    {
      'email': email,
      'password': password,
    },
  );
}

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i3.EndpointEmailIdpBase {
  EndpointEmailIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i2.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i2.Future<_i1.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i1.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i2.Future<String> verifyRegistrationCode({
    required _i1.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i2.Future<_i4.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i2.Future<_i1.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i1.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i2.Future<String> verifyPasswordResetCode({
    required _i1.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i2.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i2.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i5.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i5.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

/// Endpoint for managing leaderboard entries.
/// Access this endpoint as `client.leaderboardEntry` from the Flutter client.
/// {@category Endpoint}
class EndpointLeaderboardEntry extends _i1.EndpointRef {
  EndpointLeaderboardEntry(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'leaderboardEntry';

  /// Gets the top N leaderboard entries, ordered by points (descending).
  /// [limit] defaults to 10 if not provided.
  _i2.Future<List<_i6.LeaderboardEntry>> getTopEntries({required int limit}) =>
      caller.callServerEndpoint<List<_i6.LeaderboardEntry>>(
        'leaderboardEntry',
        'getTopEntries',
        {'limit': limit},
      );

  /// Gets the current authenticated user's leaderboard entry.
  _i2.Future<_i6.LeaderboardEntry?> getCurrentUserEntry() =>
      caller.callServerEndpoint<_i6.LeaderboardEntry?>(
        'leaderboardEntry',
        'getCurrentUserEntry',
        {},
      );

  /// Gets the rank of the current authenticated user.
  _i2.Future<int?> getUserRank() => caller.callServerEndpoint<int?>(
    'leaderboardEntry',
    'getUserRank',
    {},
  );

  /// Creates or updates a leaderboard entry for the current authenticated user.
  _i2.Future<_i6.LeaderboardEntry> upsertEntry({
    required int points,
    required String name,
    required int books,
    required int pages,
    String? email,
  }) => caller.callServerEndpoint<_i6.LeaderboardEntry>(
    'leaderboardEntry',
    'upsertEntry',
    {
      'points': points,
      'name': name,
      'books': books,
      'pages': pages,
      'email': email,
    },
  );

  /// Gets leaderboard entries around a specific user's position.
  _i2.Future<List<_i6.LeaderboardEntry>> getEntriesAroundUser({
    required int range,
  }) => caller.callServerEndpoint<List<_i6.LeaderboardEntry>>(
    'leaderboardEntry',
    'getEntriesAroundUser',
    {'range': range},
  );

  /// Gets all leaderboard entries for pagination.
  _i2.Future<List<_i6.LeaderboardEntry>> getEntries({
    required int offset,
    required int limit,
  }) => caller.callServerEndpoint<List<_i6.LeaderboardEntry>>(
    'leaderboardEntry',
    'getEntries',
    {
      'offset': offset,
      'limit': limit,
    },
  );

  /// Streams leaderboard entries with periodic updates.
  /// Yields the top N entries every [updateInterval] seconds.
  _i2.Stream<List<_i6.LeaderboardEntry>> streamTopEntries({
    required int limit,
    required int updateIntervalSeconds,
  }) =>
      caller.callStreamingServerEndpoint<
        _i2.Stream<List<_i6.LeaderboardEntry>>,
        List<_i6.LeaderboardEntry>
      >(
        'leaderboardEntry',
        'streamTopEntries',
        {
          'limit': limit,
          'updateIntervalSeconds': updateIntervalSeconds,
        },
        {},
      );
}

/// Endpoint for managing push notifications
///
/// Handles device token registration and sending notifications to users
/// {@category Endpoint}
class EndpointNotification extends _i1.EndpointRef {
  EndpointNotification(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'notification';

  /// Register or update a device token for the current user
  ///
  /// [deviceToken] - The FCM device token
  /// [platform] - The platform ('android' or 'ios')
  ///
  /// Call this from the Flutter app after getting the FCM token
  _i2.Future<void> registerDeviceToken(
    String deviceToken,
    String platform,
  ) => caller.callServerEndpoint<void>(
    'notification',
    'registerDeviceToken',
    {
      'deviceToken': deviceToken,
      'platform': platform,
    },
  );

  /// Deactivate a device token (e.g., when user logs out)
  _i2.Future<void> deactivateDeviceToken(String deviceToken) =>
      caller.callServerEndpoint<void>(
        'notification',
        'deactivateDeviceToken',
        {'deviceToken': deviceToken},
      );

  /// Send a push notification to a specific user
  ///
  /// [userId] - The auth user ID
  /// [title] - Notification title
  /// [body] - Notification body
  /// [data] - Optional custom data payload
  ///
  /// Returns true if notification was sent to at least one device
  _i2.Future<bool> sendNotificationToUser(
    _i1.UuidValue userId,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) => caller.callServerEndpoint<bool>(
    'notification',
    'sendNotificationToUser',
    {
      'userId': userId,
      'title': title,
      'body': body,
      'data': data,
    },
  );

  /// Send a notification to the current authenticated user
  _i2.Future<bool> sendNotificationToMe(
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) => caller.callServerEndpoint<bool>(
    'notification',
    'sendNotificationToMe',
    {
      'title': title,
      'body': body,
      'data': data,
    },
  );

  /// Send notification to multiple users
  ///
  /// [userIds] - List of auth user IDs
  /// [title] - Notification title
  /// [body] - Notification body
  /// [data] - Optional custom data payload
  ///
  /// Returns a map of userId -> success status
  _i2.Future<Map<String, bool>> sendNotificationToMultipleUsers(
    List<_i1.UuidValue> userIds,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) => caller.callServerEndpoint<Map<String, bool>>(
    'notification',
    'sendNotificationToMultipleUsers',
    {
      'userIds': userIds,
      'title': title,
      'body': body,
      'data': data,
    },
  );

  /// Send notification to a topic
  ///
  /// [topic] - The FCM topic name
  /// [title] - Notification title
  /// [body] - Notification body
  /// [data] - Optional custom data payload
  _i2.Future<bool> sendNotificationToTopic(
    String topic,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) => caller.callServerEndpoint<bool>(
    'notification',
    'sendNotificationToTopic',
    {
      'topic': topic,
      'title': title,
      'body': body,
      'data': data,
    },
  );

  /// Get all active devices for the current user
  _i2.Future<List<_i7.UserDevice>> getMyDevices() =>
      caller.callServerEndpoint<List<_i7.UserDevice>>(
        'notification',
        'getMyDevices',
        {},
      );

  /// Clean up inactive or old device tokens
  ///
  /// Removes devices that haven't been updated in the specified number of days
  _i2.Future<int> cleanupOldDevices({required int daysOld}) =>
      caller.callServerEndpoint<int>(
        'notification',
        'cleanupOldDevices',
        {'daysOld': daysOld},
      );
}

/// {@category Endpoint}
class EndpointUser extends _i1.EndpointRef {
  EndpointUser(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'user';

  _i2.Future<_i8.User?> getCurrentUser() =>
      caller.callServerEndpoint<_i8.User?>(
        'user',
        'getCurrentUser',
        {},
      );

  _i2.Future<_i8.User> updateProfile({
    String? username,
    String? bio,
  }) => caller.callServerEndpoint<_i8.User>(
    'user',
    'updateProfile',
    {
      'username': username,
      'bio': bio,
    },
  );
}

class Modules {
  Modules(Client client) {
    auth = _i9.Caller(client);
    serverpod_auth_idp = _i3.Caller(client);
    serverpod_auth_core = _i4.Caller(client);
  }

  late final _i9.Caller auth;

  late final _i3.Caller serverpod_auth_idp;

  late final _i4.Caller serverpod_auth_core;
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i10.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    auth = EndpointAuth(this);
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    greeting = EndpointGreeting(this);
    leaderboardEntry = EndpointLeaderboardEntry(this);
    notification = EndpointNotification(this);
    user = EndpointUser(this);
    modules = Modules(this);
  }

  late final EndpointAuth auth;

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointGreeting greeting;

  late final EndpointLeaderboardEntry leaderboardEntry;

  late final EndpointNotification notification;

  late final EndpointUser user;

  late final Modules modules;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'auth': auth,
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'greeting': greeting,
    'leaderboardEntry': leaderboardEntry,
    'notification': notification,
    'user': user,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {
    'auth': modules.auth,
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
