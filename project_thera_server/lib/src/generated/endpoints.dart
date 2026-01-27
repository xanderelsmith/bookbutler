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
import 'package:serverpod/serverpod.dart' as _i1;
import '../ai/ai_endpoint.dart' as _i2;
import '../auth/auth_endpoint.dart' as _i3;
import '../auth/email_idp_endpoint.dart' as _i4;
import '../auth/jwt_refresh_endpoint.dart' as _i5;
import '../greetings/greeting_endpoint.dart' as _i6;
import '../leaderboardentry/leaderboardentry_endpoint.dart' as _i7;
import '../notifications/notification_endpoint.dart' as _i8;
import '../user/user_endpoint.dart' as _i9;
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as _i10;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i11;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i12;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'ai': _i2.AiEndpoint()
        ..initialize(
          server,
          'ai',
          null,
        ),
      'auth': _i3.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'emailIdp': _i4.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _i5.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'greeting': _i6.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
      'leaderboardEntry': _i7.LeaderboardEntryEndpoint()
        ..initialize(
          server,
          'leaderboardEntry',
          null,
        ),
      'notification': _i8.NotificationEndpoint()
        ..initialize(
          server,
          'notification',
          null,
        ),
      'user': _i9.UserEndpoint()
        ..initialize(
          server,
          'user',
          null,
        ),
    };
    connectors['ai'] = _i1.EndpointConnector(
      name: 'ai',
      endpoint: endpoints['ai']!,
      methodConnectors: {
        'askAboutPage': _i1.MethodConnector(
          name: 'askAboutPage',
          params: {
            'pageContent': _i1.ParameterDescription(
              name: 'pageContent',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'userQuestion': _i1.ParameterDescription(
              name: 'userQuestion',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _i2.AiEndpoint).askAboutPage(
                session,
                params['pageContent'],
                params['userQuestion'],
              ),
        ),
      },
    );
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'createAccountDirectly': _i1.MethodConnector(
          name: 'createAccountDirectly',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i3.AuthEndpoint).createAccountDirectly(
                    session,
                    email: params['email'],
                    password: params['password'],
                  ),
        ),
      },
    );
    connectors['emailIdp'] = _i1.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'rememberMe': _i1.ParameterDescription(
              name: 'rememberMe',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i4.EmailIdpEndpoint).login(
                session,
                email: params['email'],
                password: params['password'],
                rememberMe: params['rememberMe'],
              ),
        ),
        'startRegistration': _i1.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i4.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _i1.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _i1.ParameterDescription(
              name: 'accountRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i4.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _i1.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _i1.ParameterDescription(
              name: 'registrationToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i4.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _i1.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i4.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _i1.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _i1.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i4.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _i1.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _i1.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i4.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
      },
    );
    connectors['jwtRefresh'] = _i1.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _i1.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['jwtRefresh'] as _i5.JwtRefreshEndpoint)
                  .refreshAccessToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['greeting'] as _i6.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
    connectors['leaderboardEntry'] = _i1.EndpointConnector(
      name: 'leaderboardEntry',
      endpoint: endpoints['leaderboardEntry']!,
      methodConnectors: {
        'getTopEntries': _i1.MethodConnector(
          name: 'getTopEntries',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['leaderboardEntry']
                          as _i7.LeaderboardEntryEndpoint)
                      .getTopEntries(
                        session,
                        limit: params['limit'],
                      ),
        ),
        'getCurrentUserEntry': _i1.MethodConnector(
          name: 'getCurrentUserEntry',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['leaderboardEntry']
                          as _i7.LeaderboardEntryEndpoint)
                      .getCurrentUserEntry(session),
        ),
        'getUserRank': _i1.MethodConnector(
          name: 'getUserRank',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['leaderboardEntry']
                          as _i7.LeaderboardEntryEndpoint)
                      .getUserRank(session),
        ),
        'upsertEntry': _i1.MethodConnector(
          name: 'upsertEntry',
          params: {
            'points': _i1.ParameterDescription(
              name: 'points',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'books': _i1.ParameterDescription(
              name: 'books',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'pages': _i1.ParameterDescription(
              name: 'pages',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['leaderboardEntry']
                          as _i7.LeaderboardEntryEndpoint)
                      .upsertEntry(
                        session,
                        points: params['points'],
                        name: params['name'],
                        books: params['books'],
                        pages: params['pages'],
                        email: params['email'],
                      ),
        ),
        'getEntriesAroundUser': _i1.MethodConnector(
          name: 'getEntriesAroundUser',
          params: {
            'range': _i1.ParameterDescription(
              name: 'range',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['leaderboardEntry']
                          as _i7.LeaderboardEntryEndpoint)
                      .getEntriesAroundUser(
                        session,
                        range: params['range'],
                      ),
        ),
        'getEntries': _i1.MethodConnector(
          name: 'getEntries',
          params: {
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['leaderboardEntry']
                          as _i7.LeaderboardEntryEndpoint)
                      .getEntries(
                        session,
                        offset: params['offset'],
                        limit: params['limit'],
                      ),
        ),
        'streamTopEntries': _i1.MethodStreamConnector(
          name: 'streamTopEntries',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'updateIntervalSeconds': _i1.ParameterDescription(
              name: 'updateIntervalSeconds',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _i1.MethodStreamReturnType.streamType,
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) =>
                  (endpoints['leaderboardEntry']
                          as _i7.LeaderboardEntryEndpoint)
                      .streamTopEntries(
                        session,
                        limit: params['limit'],
                        updateIntervalSeconds: params['updateIntervalSeconds'],
                      ),
        ),
      },
    );
    connectors['notification'] = _i1.EndpointConnector(
      name: 'notification',
      endpoint: endpoints['notification']!,
      methodConnectors: {
        'registerDeviceToken': _i1.MethodConnector(
          name: 'registerDeviceToken',
          params: {
            'deviceToken': _i1.ParameterDescription(
              name: 'deviceToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'platform': _i1.ParameterDescription(
              name: 'platform',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i8.NotificationEndpoint)
                  .registerDeviceToken(
                    session,
                    params['deviceToken'],
                    params['platform'],
                  ),
        ),
        'deactivateDeviceToken': _i1.MethodConnector(
          name: 'deactivateDeviceToken',
          params: {
            'deviceToken': _i1.ParameterDescription(
              name: 'deviceToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i8.NotificationEndpoint)
                  .deactivateDeviceToken(
                    session,
                    params['deviceToken'],
                  ),
        ),
        'sendNotificationToUser': _i1.MethodConnector(
          name: 'sendNotificationToUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'body': _i1.ParameterDescription(
              name: 'body',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i8.NotificationEndpoint)
                  .sendNotificationToUser(
                    session,
                    params['userId'],
                    params['title'],
                    params['body'],
                    data: params['data'],
                  ),
        ),
        'sendNotificationToMe': _i1.MethodConnector(
          name: 'sendNotificationToMe',
          params: {
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'body': _i1.ParameterDescription(
              name: 'body',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i8.NotificationEndpoint)
                  .sendNotificationToMe(
                    session,
                    params['title'],
                    params['body'],
                    data: params['data'],
                  ),
        ),
        'sendNotificationToMultipleUsers': _i1.MethodConnector(
          name: 'sendNotificationToMultipleUsers',
          params: {
            'userIds': _i1.ParameterDescription(
              name: 'userIds',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'body': _i1.ParameterDescription(
              name: 'body',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i8.NotificationEndpoint)
                  .sendNotificationToMultipleUsers(
                    session,
                    params['userIds'],
                    params['title'],
                    params['body'],
                    data: params['data'],
                  ),
        ),
        'sendNotificationToTopic': _i1.MethodConnector(
          name: 'sendNotificationToTopic',
          params: {
            'topic': _i1.ParameterDescription(
              name: 'topic',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'body': _i1.ParameterDescription(
              name: 'body',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i8.NotificationEndpoint)
                  .sendNotificationToTopic(
                    session,
                    params['topic'],
                    params['title'],
                    params['body'],
                    data: params['data'],
                  ),
        ),
        'getMyDevices': _i1.MethodConnector(
          name: 'getMyDevices',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i8.NotificationEndpoint)
                  .getMyDevices(session),
        ),
        'sendNotificationToAllUsers': _i1.MethodConnector(
          name: 'sendNotificationToAllUsers',
          params: {
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'body': _i1.ParameterDescription(
              name: 'body',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i8.NotificationEndpoint)
                  .sendNotificationToAllUsers(
                    session,
                    params['title'],
                    params['body'],
                    data: params['data'],
                  ),
        ),
        'sendReadingStartedNotification': _i1.MethodConnector(
          name: 'sendReadingStartedNotification',
          params: {
            'bookTitle': _i1.ParameterDescription(
              name: 'bookTitle',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i8.NotificationEndpoint)
                  .sendReadingStartedNotification(
                    session,
                    params['bookTitle'],
                  ),
        ),
        'cleanupOldDevices': _i1.MethodConnector(
          name: 'cleanupOldDevices',
          params: {
            'daysOld': _i1.ParameterDescription(
              name: 'daysOld',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notification'] as _i8.NotificationEndpoint)
                  .cleanupOldDevices(
                    session,
                    daysOld: params['daysOld'],
                  ),
        ),
      },
    );
    connectors['user'] = _i1.EndpointConnector(
      name: 'user',
      endpoint: endpoints['user']!,
      methodConnectors: {
        'getCurrentUser': _i1.MethodConnector(
          name: 'getCurrentUser',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['user'] as _i9.UserEndpoint).getCurrentUser(
                session,
              ),
        ),
        'updateProfile': _i1.MethodConnector(
          name: 'updateProfile',
          params: {
            'username': _i1.ParameterDescription(
              name: 'username',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'bio': _i1.ParameterDescription(
              name: 'bio',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['user'] as _i9.UserEndpoint).updateProfile(
                session,
                username: params['username'],
                bio: params['bio'],
              ),
        ),
      },
    );
    modules['serverpod_auth'] = _i10.Endpoints()..initializeEndpoints(server);
    modules['serverpod_auth_idp'] = _i11.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i12.Endpoints()
      ..initializeEndpoints(server);
  }
}
