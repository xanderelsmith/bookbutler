# Push Notifications Implementation Guide for Serverpod

## Overview

Serverpod doesn't have built-in push notifications. You need to integrate with:
- **Firebase Cloud Messaging (FCM)** for Android
- **Apple Push Notification Service (APNs)** for iOS

This guide shows you how to implement push notifications that can be triggered from your Serverpod server.

## Architecture

```
Flutter App → Gets FCM/APNs Token → Sends to Serverpod
                                          ↓
                                     Stores Token in DB
                                          ↓
Serverpod → Sends HTTP Request → FCM/APNs → Device
```

## Step 1: Flutter Client Setup

### 1.1 Add Dependencies

Add to `project_thera/pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
```

### 1.2 Initialize Firebase

1. Create a Firebase project at https://console.firebase.google.com
2. Add Android app: Download `google-services.json` → place in `android/app/`
3. Add iOS app: Download `GoogleService-Info.plist` → place in `ios/Runner/`
4. Follow Firebase setup guides for both platforms

### 1.3 Create Notification Service Extension

Create `project_thera/lib/services/push_notification_service.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'serverpod_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _currentToken;

  // Background message handler (must be top-level function)
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Handling background message: ${message.messageId}');
  }

  Future<void> initialize() async {
    // Request permission (iOS)
    if (Platform.isIOS) {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Show local notification using your NotificationService
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Navigate to relevant screen based on message data
    });

    // Get FCM token
    await _refreshToken();
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _sendTokenToServer(newToken);
    });
  }

  Future<void> _refreshToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        print('FCM Token: $_currentToken');
        await _sendTokenToServer(_currentToken!);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      // TODO: Send token to Serverpod
      // await serverpodService.updateDeviceToken(token, Platform.isAndroid ? 'android' : 'ios');
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }

  String? get currentToken => _currentToken;
}
```

### 1.4 Initialize in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize push notifications
  await PushNotificationService().initialize();
  
  runApp(ProviderScope(child: MyApp()));
}
```

## Step 2: Server-Side Setup

### 2.1 Create Device Token Model

Create `project_thera_server/lib/src/userdevice/userdevice.spy.yaml`:

```yaml
# Device token model for storing FCM/APNs tokens
class: UserDevice

table: user_device

fields:
  ### The user ID this device belongs to (links to User.authUserId)
  userId: String
  ### FCM token (Android) or APNs token (iOS)
  deviceToken: String
  ### Platform: 'android' or 'ios'
  platform: String
  ### When the token was registered
  createdAt: DateTime?
  ### When the token was last updated
  updatedAt: DateTime?

indexes:
  - userId
  - deviceToken
```

### 2.2 Create Notification Endpoint

Create `project_thera_server/lib/src/notification/notification_endpoint.dart`:

```dart
import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationEndpoint extends Endpoint {
  // Store your Firebase Server Key in config/passwords.yaml
  // Access it via: session.serverpod.getPassword('firebaseServerKey')

  /// Registers or updates a device token for the current user
  Future<void> registerDeviceToken(
    Session session,
    String deviceToken,
    String platform, // 'android' or 'ios'
  ) async {
    final authUser = await session.auth.user();
    if (authUser == null) {
      throw Exception('User must be authenticated');
    }

    // Find existing device token
    var device = await UserDevice.findSingleRow(
      session,
      where: (d) => d.deviceToken.equals(deviceToken),
    );

    final now = DateTime.now().toUtc();

    if (device == null) {
      // Create new device record
      device = UserDevice(
        userId: authUser.id.value,
        deviceToken: deviceToken,
        platform: platform,
        createdAt: now,
        updatedAt: now,
      );
      await UserDevice.insert(session, device);
    } else {
      // Update existing device record
      device = device.copyWith(
        userId: authUser.id.value,
        platform: platform,
        updatedAt: now,
      );
      await UserDevice.update(session, device);
    }
  }

  /// Sends a push notification to a specific user
  Future<bool> sendNotificationToUser(
    Session session,
    String userId,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    // Get all device tokens for this user
    final devices = await UserDevice.find(
      session,
      where: (d) => d.userId.equals(userId),
    );

    bool allSuccess = true;
    for (final device in devices) {
      final success = await _sendNotification(
        session,
        device.deviceToken,
        device.platform,
        title,
        body,
        data: data,
      );
      if (!success) allSuccess = false;
    }

    return allSuccess;
  }

  /// Sends a push notification to a device token
  Future<bool> _sendNotification(
    Session session,
    String deviceToken,
    String platform,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    try {
      if (platform == 'android') {
        return await _sendFCMNotification(
          session,
          deviceToken,
          title,
          body,
          data: data,
        );
      } else if (platform == 'ios') {
        // TODO: Implement APNs notification sending
        // For now, you can also use FCM for iOS if configured
        return await _sendFCMNotification(
          session,
          deviceToken,
          title,
          body,
          data: data,
        );
      }
      return false;
    } catch (e) {
      session.log('Error sending notification: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Sends a notification via Firebase Cloud Messaging
  Future<bool> _sendFCMNotification(
    Session session,
    String deviceToken,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get Firebase Server Key from passwords.yaml
      final serverKey = session.serverpod.getPassword('firebaseServerKey');
      if (serverKey == null) {
        session.log('Firebase Server Key not configured', level: LogLevel.error);
        return false;
      }

      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      
      final payload = {
        'to': deviceToken,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
        },
        'data': data ?? {},
        'priority': 'high',
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        session.log('Notification sent successfully', level: LogLevel.info);
        return true;
      } else {
        session.log(
          'Failed to send notification: ${response.statusCode} - ${response.body}',
          level: LogLevel.error,
        );
        return false;
      }
    } catch (e) {
      session.log('Error sending FCM notification: $e', level: LogLevel.error);
      return false;
    }
  }
}
```

### 2.3 Add Firebase Server Key to Passwords

Add to `project_thera_server/config/passwords.yaml`:

```yaml
firebaseServerKey: YOUR_FIREBASE_SERVER_KEY_HERE
```

To get your Firebase Server Key:
1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Copy the "Server key" from Cloud Messaging API (Legacy)

## Step 3: Integration

### 3.1 Update Flutter Service

Update `serverpod_service.dart`:

```dart
/// Registers device token for push notifications
Future<void> registerDeviceToken(String token, String platform) async {
  if (!_isInitialized) await initialize();
  await _client.notification.registerDeviceToken(token, platform);
}
```

### 3.2 Update Push Notification Service

Update `_sendTokenToServer` in `push_notification_service.dart`:

```dart
Future<void> _sendTokenToServer(String token) async {
  try {
    final service = ServerpodService();
    await service.initialize();
    await service.registerDeviceToken(
      token,
      Platform.isAndroid ? 'android' : 'ios',
    );
  } catch (e) {
    print('Error sending token to server: $e');
  }
}
```

## Step 4: Sending Notifications

You can now send notifications from anywhere in your Serverpod endpoints:

```dart
// Example: Send notification when user achieves a milestone
class AchievementEndpoint extends Endpoint {
  Future<void> awardAchievement(Session session, String achievementId) async {
    final authUser = await session.auth.user();
    if (authUser == null) return;

    // ... award logic ...

    // Send notification
    await session.serverpod.endpoints['notification']
        ?.sendNotificationToUser(
      session,
      authUser.id.value,
      'Achievement Unlocked!',
      'You just unlocked a new achievement!',
      data: {'type': 'achievement', 'id': achievementId},
    );
  }
}
```

## Step 5: iOS APNs Setup (Optional but Recommended)

For production iOS apps, you should use native APNs instead of FCM:

1. **Generate APNs Key**:
   - Go to Apple Developer → Certificates, Identifiers & Profiles → Keys
   - Create a new key with "Apple Push Notifications service (APNs)" enabled
   - Download the .p8 file

2. **Add APNs package**:
   Add to `project_thera_server/pubspec.yaml`:
   ```yaml
   dependencies:
     apns: ^2.0.0
   ```

3. **Implement APNs sender**:
   Similar to FCM, but use the `apns` package to send to Apple's servers.

## Testing

1. Run your app and check logs for FCM token
2. Verify token is saved in database
3. Send test notification from Firebase Console
4. Test sending from Serverpod endpoint

## Troubleshooting

- **Token not received**: Check Firebase setup and permissions
- **Notifications not received**: Verify server key is correct
- **Android issues**: Check `google-services.json` is in correct location
- **iOS issues**: Ensure APNs certificates are configured

## Security Notes

- Never expose Firebase Server Key in client code
- Store sensitive keys only in `config/passwords.yaml`
- Consider rate limiting notification sending
- Validate user permissions before sending notifications
