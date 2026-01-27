import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'dart:convert';
import 'push_notification_service.dart';
import 'secure_cache_service.dart';
import 'package:alarm/alarm.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final SecureCacheService _cacheService = SecureCacheService();

  static const String _firstDocumentOpenedKey = 'first_document_opened';

  // Initialize notification service
  Future<void> initialize() async {
    await Alarm.init();

    // Request notification permission (only needed for Android 13+)
    if (Platform.isAndroid) {
      try {
        final status = await Permission.notification.status;
        if (status.isDenied) {
          await Permission.notification.request();
        }

        // Request exact alarm permission for Android 12+ (API 31+)
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        if (exactAlarmStatus.isDenied) {
          await Permission.scheduleExactAlarm.request();
        }
      } catch (e) {
        // Permission might not be available on older Android versions
        // This is fine
      }
    }

    // Android initialization settings
    // Use white notification icon for proper display when expanded
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Initialization settings for both platforms
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'book_notifications',
      'Book Notifications',
      description: 'Notifications for book reading activities',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        PushNotificationService().handleNotificationNavigation(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  // Check and send first app launch notification
  Future<void> sendFirstLaunchNotification() async {
    try {
      // Check if this is the first launch
      final isFirstLaunch = await _cacheService.isFirstLaunch();

      if (!isFirstLaunch) {
        // Not first launch, don't send notification
        return;
      }

      // Request permission if not granted (only for Android 13+)
      if (Platform.isAndroid) {
        try {
          final status = await Permission.notification.status;
          if (status.isDenied) {
            await Permission.notification.request();
          }
        } catch (e) {
          // Permission might not be available on older Android versions
          // Continue anyway - notifications work without explicit permission on Android 12 and below
        }
      }

      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'book_notifications',
            'Book Notifications',
            channelDescription: 'Notifications for book reading activities',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: 'ic_notification',
            styleInformation: BigTextStyleInformation(''),
          );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Notification details for both platforms
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show welcome notification
      await _notifications.show(
        0, // Use ID 0 for first launch notification
        'Welcome to The Flutter Butler! 📚',
        'Start your reading journey by adding your first book from the Library tab.',
        notificationDetails,
      );

      // Mark first launch as complete
      await _cacheService.markFirstLaunchComplete();
    } catch (e) {
      // Handle error silently
    }
  }

  // Check and send first document opened notification
  Future<void> sendFirstDocumentOpenedNotification(String bookTitle) async {
    try {
      // Check if first document notification was already sent
      final firstDocumentOpened = await _cacheService.getCachedBookMetadata(
        _firstDocumentOpenedKey,
      );

      if (firstDocumentOpened != null) {
        // Already sent, don't send again
        return;
      }

      // Request permission if not granted (only for Android 13+)
      if (Platform.isAndroid) {
        try {
          final status = await Permission.notification.status;
          if (status.isDenied) {
            await Permission.notification.request();
          }
        } catch (e) {
          // Permission might not be available on older Android versions
          // Continue anyway - notifications work without explicit permission on Android 12 and below
        }
      }

      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'book_notifications',
            'Book Notifications',
            channelDescription: 'Notifications for book reading activities',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: 'ic_notification',
            styleInformation: BigTextStyleInformation(''),
          );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Notification details for both platforms
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _notifications.show(
        1,
        'Welcome to The Butler! 📖',
        'You\'ve opened your first document: "$bookTitle". Let\'s start your reading journey!',
        notificationDetails,
      );

      // Mark as sent in cache
      await _cacheService.cacheBookMetadata(_firstDocumentOpenedKey, {
        'sent': true,
        'sentAt': DateTime.now().toIso8601String(),
        'firstBookTitle': bookTitle,
      });
    } catch (e) {
      // Handle error silently
    }
  }

  // Send book completed notification
  Future<void> sendBookCompletedNotification(String bookTitle) async {
    try {
      await _showNotification(
        id: 2,
        title: '🎉 Magnificent Achievement!',
        body:
            'You\'ve completed "$bookTitle"! The Butler is most impressed, Sir.',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> sendFcmNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final payload = data != null ? jsonEncode(data) : null;
      await _showNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      // Handle error silently
    }
  }

  // Send halfway milestone notification
  Future<void> sendHalfwayMilestoneNotification(String bookTitle) async {
    try {
      await _showNotification(
        id: 3,
        title: '🎯 Halfway Milestone!',
        body:
            'You\'ve reached the midpoint of "$bookTitle". Excellent progress!',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  // Send session complete notification
  Future<void> sendSessionCompleteNotification({
    required int pagesRead,
    required int durationMinutes,
    required double pagesPerMinute,
  }) async {
    try {
      final timeText = durationMinutes > 0
          ? '$durationMinutes ${durationMinutes == 1 ? 'minute' : 'minutes'}'
          : 'quick session';

      await _showNotification(
        id: 4,
        title: '📚 Session Complete!',
        body:
            '$pagesRead ${pagesRead == 1 ? 'page' : 'pages'} read in $timeText. Reading speed: ${pagesPerMinute.toStringAsFixed(1)} pages/min.',
      );

      // Send exceptional velocity notification if reading speed is high
      if (pagesPerMinute > 2.0) {
        Future.delayed(const Duration(seconds: 2), () {
          _showNotification(
            id: 5,
            title: '⚡ Exceptional Reading Velocity!',
            body: 'Your focus today is remarkable, Sir.',
          );
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Send reading streak notification
  Future<void> sendReadingStreakNotification(int streakDays) async {
    try {
      if (streakDays >= 7) {
        await _showNotification(
          id: 6,
          title: '🏆 Milestone Unlocked!',
          body:
              'You\'ve achieved a $streakDays-day reading streak. The Butler is most impressed, Sir!',
        );
      } else {
        await _showNotification(
          id: 7,
          title: '📖 Reading Streak',
          body:
              'Your current $streakDays-day streak is promising. Aim for 7 consecutive days to establish a robust habit, Sir.',
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Send goal achievement notification
  Future<void> sendGoalAchievementNotification({
    required int projectedBooks,
    required int readingGoal,
    required bool onTrack,
  }) async {
    try {
      if (onTrack) {
        await _showNotification(
          id: 8,
          title: '🎯 Excellent Pace!',
          body:
              'At this rate, you\'ll read $projectedBooks books this year, surpassing your goal of $readingGoal. Excellent work, Sir!',
        );
      } else {
        final increaseNeeded =
            ((readingGoal - projectedBooks) / projectedBooks * 100).round();
        await _showNotification(
          id: 9,
          title: '📊 Goal Progress Update',
          body:
              'You\'re on track for $projectedBooks books. To reach your goal of $readingGoal, increase your pace by $increaseNeeded%.',
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Send weekly forecast notification
  Future<void> sendWeeklyForecastNotification({
    required int averagePagesPerDay,
    required int estimatedBooksThisWeek,
  }) async {
    try {
      await _showNotification(
        id: 10,
        title: '📅 Weekly Forecast',
        body:
            'At your current pace of $averagePagesPerDay pages daily, you\'ll complete approximately $estimatedBooksThisWeek ${estimatedBooksThisWeek == 1 ? 'book' : 'books'} this week.',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  // Send reading velocity notification
  Future<void> sendReadingVelocityNotification(
    double averagePagesPerMinute,
  ) async {
    try {
      final message = averagePagesPerMinute > 1.5
          ? 'Remarkable concentration, Sir!'
          : 'Consider minimizing distractions to improve focus.';

      await _showNotification(
        id: 11,
        title: '📈 Reading Velocity',
        body:
            'Your average reading speed is ${averagePagesPerMinute.toStringAsFixed(1)} pages per minute. $message',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  // Helper method to show notifications
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Request permission if not granted (only for Android 13+)
      if (Platform.isAndroid) {
        try {
          final status = await Permission.notification.status;
          if (status.isDenied) {
            await Permission.notification.request();
          }
        } catch (e) {
          // Permission might not be available on older Android versions
          // Continue anyway - notifications work without explicit permission on Android 12 and below
        }
      }

      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'book_notifications',
            'Book Notifications',
            channelDescription: 'Notifications for book reading activities',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: 'ic_notification',
            styleInformation: BigTextStyleInformation(''),
          );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Notification details for both platforms
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      // Handle error silently
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> checkAndroidScheduleExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    debugPrint('Schedule exact alarm permission: $status.');
    if (status.isDenied) {
      debugPrint('Requesting schedule exact alarm permission...');
      final res = await Permission.scheduleExactAlarm.request();
      debugPrint(
        'Schedule exact alarm permission ${res.isGranted ? '' : 'not'} granted.',
      );
    }
  }

  /// Schedule daily offline reminder at a specific time
  /// [time] - TimeOfDay when to send the reminder
  Future<void> scheduleOfflineReminder(TimeOfDay time) async {
    try {
      final now = DateTime.now();

      // Create scheduled time for today
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await checkAndroidScheduleExactAlarmPermission();

      final alarmSettings = AlarmSettings(
        id: 12,
        dateTime: scheduledDate,
        assetAudioPath: 'asset/alarm.mp3', // Make sure to add this asset
        loopAudio: true,
        vibrate: true,

        warningNotificationOnKill: true,

        ///
        androidFullScreenIntent: true,
        volumeSettings: VolumeSettings.fade(
          volume: 0.8,
          fadeDuration: Duration(seconds: 5),
          volumeEnforced: true,
        ),
        notificationSettings: const NotificationSettings(
          title: '📚 Time to Read!',
          body: 'The Butler suggests you resume your reading journey, Sir.',
          stopButton: 'Stop the alarm',
          icon: 'ic_notification',
          iconColor: Color(0xff862778),
        ),
      );

      await Alarm.set(alarmSettings: alarmSettings);
    } catch (e) {
      // Handle error silently
      debugPrint('Error scheduling alarm: $e');
    }
  }

  /// Cancel the offline reminder
  Future<void> cancelOfflineReminder() async {
    try {
      await Alarm.stop(12);
    } catch (e) {
      // Handle error silently
    }
  }
}
