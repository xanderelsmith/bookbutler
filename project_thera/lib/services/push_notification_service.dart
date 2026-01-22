import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import '../main.dart';
import 'notification_service.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();
  String? _currentToken;
  bool _isInitialized = false;

  /// Initialize push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('User granted provisional notification permission');
      } else {
        print('User declined or has not accepted notification permission');
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle notification taps when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // Get and store FCM token
      await _getToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Subscribe to all_users topic
      await subscribeToTopic('all_users');

      _isInitialized = true;
      print('PushNotificationService initialized successfully');
    } catch (e) {
      print('Error initializing PushNotificationService: $e');
    }
  }

  /// Get FCM token
  Future<void> _getToken() async {
    try {
      // For iOS, get APNs token first
      if (Platform.isIOS) {
        String? apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          // Wait a bit and try again - APNs token might not be ready immediately
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _messaging.getAPNSToken();
        }
        print('APNs Token: $apnsToken');
      }

      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        print('FCM Token: $_currentToken');
        await sendTokenToServer(_currentToken!);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String token) {
    print('FCM Token refreshed: $token');
    _currentToken = token;
    sendTokenToServer(token);
  }

  /// Send token to server for storing
  Future<void> sendTokenToServer(String token) async {
    try {
      // Get the platform
      final platform = Platform.isAndroid ? 'android' : 'ios';

      // Send token to Serverpod server
      await client.notification.registerDeviceToken(token, platform);

      print('Successfully sent token to server: $token (platform: $platform)');
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message:');
    print('  Title: ${message.notification?.title}');
    print('  Body: ${message.notification?.body}');
    print('  Data: ${message.data}');

    // Show local notification when app is in foreground
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        data: message.data,
      );
    }
  }

  /// Handle when user taps notification to open app
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app:');
    print('  Data: ${message.data}');

    // Navigate based on message data
    _handleNotificationNavigation(message.data);
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Use a unique ID based on current time
      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // Access the private method through the notification service
      // For now, we'll create a simple notification
      await _notificationService.sendFcmNotification(
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  /// Handle navigation based on notification data
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Extract navigation info from data
    final String? route = data['route'];
    final String? type = data['type'];

    if (route != null) {
      // TODO: Implement navigation based on route
      print('Should navigate to: $route');
    }

    if (type != null) {
      switch (type) {
        case 'achievement':
          // Navigate to achievements
          print('Navigate to achievements');
          break;
        case 'leaderboard':
          // Navigate to leaderboard
          print('Navigate to leaderboard');
          break;
        case 'book':
          // Navigate to book details
          final bookId = data['bookId'];
          print('Navigate to book: $bookId');
          break;
        default:
          print('Unknown notification type: $type');
      }
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Get current FCM token
  String? get currentToken => _currentToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
