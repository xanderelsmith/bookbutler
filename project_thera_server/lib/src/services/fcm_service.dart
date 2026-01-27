import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

/// Service for sending Firebase Cloud Messaging notifications
///
/// This service uses a Firebase service account to send push notifications
/// to Android and iOS devices via FCM HTTP v1 API.
class FCMService {
  static FCMService instance = FCMService._();

  FCMService._();

  factory FCMService() => instance;

  /// Cache for the access token to avoid repeated authentication
  String? _cachedAccessToken;
  DateTime? _tokenExpiryTime;

  /// Get Firebase access token using service account credentials
  ///
  /// The service account JSON file should be placed in:
  /// project_thera_server/config/firebase-service-account.json
  Future<(String, String)> _getAccessToken() async {
    try {
      // Check if we have a valid cached token
      if (_cachedAccessToken != null &&
          _tokenExpiryTime != null &&
          DateTime.now().isBefore(_tokenExpiryTime!)) {
        final serviceAccount = await _loadServiceAccount();
        return (_cachedAccessToken!, serviceAccount["project_id"] as String);
      }

      // Get new token
      const firebaseMessagingScope =
          'https://www.googleapis.com/auth/firebase.messaging';

      final serviceAccount = await _loadServiceAccount();

      final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(serviceAccount),
        [firebaseMessagingScope],
      );

      final accessToken = client.credentials.accessToken.data;
      final expiryTime = client.credentials.accessToken.expiry;

      // Cache the token
      _cachedAccessToken = accessToken;
      _tokenExpiryTime = expiryTime;

      // Close the client
      client.close();

      return (accessToken, serviceAccount["project_id"] as String);
    } catch (e) {
      print('Error getting FCM access token: $e');
      return ("", "");
    }
  }

  /// Load service account credentials from file
  ///
  /// Expected location: config/firebase-service-account.json
  Future<Map<String, dynamic>> _loadServiceAccount() async {
    try {
      final jsonString = Platform.environment['FIREBASE_SERVICE_ACCOUNT'];
      if (jsonString == null || jsonString.isEmpty) {
        throw Exception(
          'FIREBASE_SERVICE_ACCOUNT environment variable not set. '
          'Create it with `scloud secret create FIREBASE_SERVICE_ACCOUNT --from-file firebase-service-account.json`.',
        );
      }

      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // same validation as before...
      final requiredFields = [
        'type',
        'project_id',
        'private_key_id',
        'private_key',
        'client_email',
        'client_id',
      ];

      for (final field in requiredFields) {
        if (!jsonData.containsKey(field)) {
          throw Exception('Missing required field in service account: $field');
        }
      }

      return {
        "type": jsonData["type"],
        "project_id": jsonData["project_id"],
        "private_key_id": jsonData["private_key_id"],
        "private_key": jsonData["private_key"],
        "client_email": jsonData["client_email"],
        "client_id": jsonData["client_id"],
      };
    } catch (e) {
      throw Exception('Error loading service account: $e');
    }
  }

  /// Send a push notification to a specific device token
  ///
  /// [deviceToken] - The FCM device token
  /// [title] - Notification title
  /// [body] - Notification body
  /// [data] - Optional custom data payload
  ///
  /// Returns true if successful, false otherwise
  Future<bool> sendNotificationToDevice({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    Session? session,
  }) async {
    try {
      final tokenData = await _getAccessToken();
      final String accessToken = tokenData.$1;
      final String projectId = tokenData.$2;

      if (accessToken.isEmpty || projectId.isEmpty) {
        session?.log(
          'Failed to get FCM access token',
          level: LogLevel.error,
        );
        return false;
      }

      final fcmEndpoint = "https://fcm.googleapis.com/v1/projects/$projectId";
      final url = Uri.parse('$fcmEndpoint/messages:send');

      // Build FCM v1 message payload
      final payload = {
        "message": {
          "token": deviceToken,
          "notification": {
            "title": title,
            "body": body,
          },
          "data": data ?? {},
          "android": {
            "priority": "high",
            "notification": {
              "channel_id": "book_notifications",
              "sound": "default",
            },
          },
          "apns": {
            "payload": {
              "aps": {
                "sound": "default",
                "badge": 1,
              },
            },
          },
        },
      };

      final headers = {
        HttpHeaders.contentTypeHeader: 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        session?.log(
          'Successfully sent notification to device',
          level: LogLevel.info,
        );
        return true;
      } else {
        session?.log(
          'Failed to send notification: ${response.statusCode} - ${response.body}',
          level: LogLevel.error,
        );
        return false;
      }
    } catch (e) {
      session?.log(
        'Error sending notification: $e',
        level: LogLevel.error,
      );
      return false;
    }
  }

  /// Send notification using custom payload
  ///
  /// This allows for more flexibility in constructing the FCM message.
  /// The payload should follow FCM v1 API format.
  ///
  /// [payload] - Complete FCM message payload
  Future<bool> sendNotificationWithPayload({
    required Map<String, dynamic> payload,
    Session? session,
  }) async {
    try {
      final tokenData = await _getAccessToken();
      final String accessToken = tokenData.$1;
      final String projectId = tokenData.$2;

      if (accessToken.isEmpty || projectId.isEmpty) {
        session?.log(
          'Failed to get FCM access token',
          level: LogLevel.error,
        );
        return false;
      }

      final fcmEndpoint = "https://fcm.googleapis.com/v1/projects/$projectId";
      final url = Uri.parse('$fcmEndpoint/messages:send');

      final headers = {
        HttpHeaders.contentTypeHeader: 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        session?.log(
          'Successfully sent notification',
          level: LogLevel.info,
        );
        return true;
      } else {
        session?.log(
          'Failed to send notification: ${response.statusCode} - ${response.body}',
          level: LogLevel.error,
        );
        return false;
      }
    } catch (e) {
      session?.log(
        'Error sending notification: $e',
        level: LogLevel.error,
      );
      return false;
    }
  }

  /// Send notification to multiple devices
  ///
  /// [deviceTokens] - List of FCM device tokens
  /// [title] - Notification title
  /// [body] - Notification body
  /// [data] - Optional custom data payload
  ///
  /// Returns a map of token -> success status
  Future<Map<String, bool>> sendNotificationToMultipleDevices({
    required List<String> deviceTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    Session? session,
  }) async {
    final results = <String, bool>{};

    for (final token in deviceTokens) {
      final success = await sendNotificationToDevice(
        deviceToken: token,
        title: title,
        body: body,
        data: data,
        session: session,
      );
      results[token] = success;
    }

    return results;
  }

  /// Send notification to a topic
  ///
  /// [topic] - The FCM topic name
  /// [title] - Notification title
  /// [body] - Notification body
  /// [data] - Optional custom data payload
  Future<bool> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    Session? session,
  }) async {
    try {
      final tokenData = await _getAccessToken();
      final String accessToken = tokenData.$1;
      final String projectId = tokenData.$2;

      if (accessToken.isEmpty || projectId.isEmpty) {
        return false;
      }

      final fcmEndpoint = "https://fcm.googleapis.com/v1/projects/$projectId";
      final url = Uri.parse('$fcmEndpoint/messages:send');

      final payload = {
        "message": {
          "topic": topic,
          "notification": {
            "title": title,
            "body": body,
          },
          "data": data ?? {},
        },
      };

      final headers = {
        HttpHeaders.contentTypeHeader: 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      session?.log(
        'Error sending topic notification: $e',
        level: LogLevel.error,
      );
      return false;
    }
  }
}
