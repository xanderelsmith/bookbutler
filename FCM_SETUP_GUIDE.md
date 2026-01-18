# 🔔 FCM Push Notifications Setup Guide

## ✅ What's Been Configured

Your FCM push notifications are now properly structured with:

### Client-Side (Flutter App)
- ✅ **PushNotificationService** - Receives FCM notifications, gets device tokens
- ✅ **NotificationService** - Shows local notifications
- ✅ Firebase initialized in `main.dart`
- ✅ iOS background modes configured
- ✅ Android notification permissions configured

### Server-Side (Serverpod)
- ✅ **FCMService** - Sends notifications via FCM HTTP v1 API
- ✅ **NotificationEndpoint** - Manages device tokens and sends notifications
- ✅ **UserDevice** model - Stores device tokens in database

---

## 📋 Required Setup Steps

### 1. Download iOS Firebase Configuration

**You must do this for iOS to work:**

1. Go to [Firebase Console](https://console.firebase.google.com) → **bookbutler-dfb30**
2. Click ⚙️ **Project Settings** → **General**
3. Scroll to **Your apps** → Select the **iOS app**
4. Click **Download GoogleService-Info.plist**
5. Place it in: `project_thera/ios/Runner/GoogleService-Info.plist`

---

### 2. Download Firebase Service Account (Server)

**Required for the server to send notifications:**

1. Go to [Firebase Console](https://console.firebase.google.com) → **bookbutler-dfb30**
2. Click ⚙️ **Project Settings** → **Service accounts**
3. Click **Generate new private key**
4. Save the downloaded JSON file
5. Rename it to: `firebase-service-account.json`
6. Place it in: `project_thera_server/config/firebase-service-account.json`

**Important:** Add this file to `.gitignore` to keep credentials secure!

```gitignore
# Add to .gitignore
config/firebase-service-account.json
```

---

### 3. Generate Serverpod Models

Run this to generate the UserDevice model from the YAML:

```bash
cd project_thera_server
serverpod generate
```

This will create the database model and client code for the UserDevice entity.

---

### 4. Apply Database Migrations

Create and apply the migration for the new `user_device` table:

```bash
cd project_thera_server
serverpod create-migration
serverpod migrate
```

Or if running the server:
```bash
dart bin/main.dart --apply-migrations
```

---

### 5. Install Dependencies

**Client:**
```bash
cd project_thera
flutter pub get
```

**Server:**
```bash
cd project_thera_server
dart pub get
```

---

## 🚀 Usage

### Client-Side: Getting FCM Token

The token is automatically retrieved and sent to the server when the app starts:

```dart
// Already implemented in main.dart
await PushNotificationService().initialize();
```

The token is automatically sent to your server via:
```dart
await client.notification.registerDeviceToken(token, platform);
```

---

### Server-Side: Sending Notifications

#### Send to a specific user:

```dart
// In any endpoint
await session.serverpod.endpoints.notification.sendNotificationToUser(
  session,
  userId,
  'Achievement Unlocked! 🏆',
  'You just earned the "Book Worm" badge!',
  data: {
    'type': 'achievement',
    'achievementId': '123',
  },
);
```

#### Send to current authenticated user:

```dart
await session.serverpod.endpoints.notification.sendNotificationToMe(
  session,
  'Reading Streak! 🔥',
  'You\'ve read for 7 days straight!',
);
```

#### Send to multiple users:

```dart
final results = await session.serverpod.endpoints.notification
  .sendNotificationToMultipleUsers(
    session,
    ['userId1', 'userId2', 'userId3'],
    'Weekly Leaderboard Update',
    'Check out this week\'s top readers!',
  );
```

#### Send to a topic:

```dart
await session.serverpod.endpoints.notification.sendNotificationToTopic(
  session,
  'all_users',
  'New Feature Available! ✨',
  'Check out the new reading statistics!',
);
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      FLUTTER APP (CLIENT)                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  PushNotificationService                                     │
│  ├─ Gets FCM token from Firebase                            │
│  ├─ Sends token to server (registerDeviceToken)             │
│  ├─ Listens for incoming notifications                      │
│  └─ Handles notification taps                               │
│                                                              │
│  NotificationService                                         │
│  └─ Shows local notifications                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │ FCM token
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   SERVERPOD SERVER                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  NotificationEndpoint                                        │
│  ├─ registerDeviceToken() - Stores FCM tokens               │
│  ├─ sendNotificationToUser() - Send to specific user        │
│  ├─ sendNotificationToMe() - Send to current user           │
│  └─ sendNotificationToTopic() - Send to topic               │
│                                                              │
│  FCMService                                                  │
│  ├─ Authenticates with Firebase service account             │
│  ├─ Sends notifications via FCM HTTP v1 API                 │
│  └─ Caches access tokens                                    │
│                                                              │
│  Database: user_device table                                │
│  └─ Stores device tokens linked to users                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   FIREBASE CLOUD MESSAGING                   │
│                                                              │
│  Delivers notifications to devices                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧪 Testing

### 1. Test from Firebase Console

1. Go to Firebase Console → **Cloud Messaging**
2. Click **Send your first message**
3. Enter title and body
4. Click **Send test message**
5. Enter your FCM token (check app logs)
6. Send

### 2. Test from Server Endpoint

Create a test endpoint:

```dart
class TestEndpoint extends Endpoint {
  Future<void> sendTestNotification(Session session) async {
    await session.serverpod.endpoints.notification.sendNotificationToMe(
      session,
      'Test Notification',
      'If you see this, FCM is working! 🎉',
    );
  }
}
```

Call it from your Flutter app:
```dart
await client.test.sendTestNotification();
```

---

## 🔍 Troubleshooting

### iOS: Notifications not received

- ✅ Check `GoogleService-Info.plist` is in `ios/Runner/`
- ✅ Verify APNs key is configured in Firebase Console
- ✅ Check iOS device has notifications enabled in Settings
- ✅ Check logs for APNs token

### Android: Notifications not received

- ✅ Verify `google-services.json` is in `android/app/`
- ✅ Check notification permission is granted (Android 13+)
- ✅ Look for FCM token in logs

### Server: Failed to send notifications

- ✅ Check `firebase-service-account.json` exists in `config/`
- ✅ Verify service account has proper permissions
- ✅ Check server logs for errors
- ✅ Ensure device tokens are stored in database

### Token not sent to server

- ✅ Check user is authenticated
- ✅ Verify `registerDeviceToken` endpoint is called
- ✅ Look for errors in console
- ✅ Check network connectivity

---

## 📁 File Structure

```
thera_pod/
├── project_thera/                              # Flutter Client
│   ├── lib/
│   │   ├── services/
│   │   │   ├── push_notification_service.dart  # FCM receiver
│   │   │   └── notification_service.dart       # Local notifications
│   │   ├── main.dart                           # Firebase init
│   │   └── firebase_options.dart               # Firebase config
│   ├── ios/
│   │   └── Runner/
│   │       ├── GoogleService-Info.plist        # ⚠️ YOU NEED TO ADD THIS
│   │       ├── Info.plist                      # Background modes added
│   │       └── AppDelegate.swift               # Firebase init
│   └── android/
│       └── app/
│           ├── google-services.json            # ✅ Already exists
│           └── src/main/AndroidManifest.xml    # Permissions added
│
└── project_thera_server/                       # Serverpod Server
    ├── lib/src/
    │   ├── services/
    │   │   └── fcm_service.dart                # FCM sender
    │   └── notifications/
    │       ├── notification_endpoint.dart      # API endpoints
    │       └── userdevice.spy.yaml            # Device model
    └── config/
        └── firebase-service-account.json       # ⚠️ YOU NEED TO ADD THIS
```

---

## 🔐 Security Notes

- ⚠️ **Never commit** `firebase-service-account.json` to git
- ⚠️ Service account keys have full access - keep them secure
- ✅ Device tokens are stored securely in your database
- ✅ Only authenticated users can register device tokens
- ✅ Access tokens are cached and refreshed automatically

---

## 📚 Next Steps

1. Download the iOS Firebase config file
2. Download the service account JSON
3. Generate Serverpod models (`serverpod generate`)
4. Apply database migrations
5. Test notifications from Firebase Console
6. Implement notification logic in your endpoints

---

## 🎯 Example: Send Notification When User Completes a Book

```dart
// In your book completion endpoint
class BookEndpoint extends Endpoint {
  Future<void> completeBook(Session session, String bookId) async {
    final authInfo = await session.authenticated;
    if (authInfo == null) throw Exception('Not authenticated');

    // Mark book as complete (your existing logic)
    // ...

    // Send celebration notification
    await session.serverpod.endpoints.notification.sendNotificationToMe(
      session,
      '🎉 Book Completed!',
      'Congratulations! You just finished reading!',
      data: {
        'type': 'book_completed',
        'bookId': bookId,
        'route': '/book/$bookId',
      },
    );
  }
}
```

The notification will automatically be delivered to all the user's active devices!

---

Need help? Check the [Firebase Documentation](https://firebase.google.com/docs/cloud-messaging) or the logs for detailed error messages.
