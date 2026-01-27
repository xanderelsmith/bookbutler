import 'package:serverpod_auth_idp_server/core.dart';

import '../generated/protocol.dart';
import '../services/fcm_service.dart';
import 'package:serverpod/serverpod.dart';

/// Endpoint for managing push notifications
///
/// Handles device token registration and sending notifications to users
class NotificationEndpoint extends Endpoint {
  final FCMService _fcmService = FCMService();

  /// Register or update a device token for the current user
  ///
  /// [deviceToken] - The FCM device token
  /// [platform] - The platform ('android' or 'ios')
  ///
  /// Call this from the Flutter app after getting the FCM token
  Future<void> registerDeviceToken(
    Session session,
    String deviceToken,
    String platform,
  ) async {
    try {
      final authInfo = session.authenticated;
      if (authInfo == null) {
        session.log('RegisterDeviceToken: Not authenticated. Skipping.');
        return;
      }

      final authUserId = authInfo.authUserId;
      session.log('Registering device for authUserId: $authUserId');

      // 1. Find the User row in our custom user table
      final user = await User.db.findFirstRow(
        session,
        where: (u) => u.authUserId.equals(authUserId),
      );

      if (user == null) {
        session.log(
          'RegisterDeviceToken ERROR: User profile not found in database for authUserId $authUserId. User must exist before registering a device.',
          level: LogLevel.warning,
        );
        return;
      }

      final userId = user.id;
      if (userId == null) {
        session.log('RegisterDeviceToken ERROR: User record has null ID');
        return;
      }

      session.log(
        'User found with database ID: $userId. Checking for existing device token.',
      );

      // 2. Check if this device token is already registered to ANY user
      var device = await UserDevice.db.findFirstRow(
        session,
        where: (d) => d.deviceToken.equals(deviceToken),
      );

      final now = DateTime.now().toUtc();

      if (device == null) {
        // Create new
        session.log('Device token not found. Creating new UserDevice record.');
        device = UserDevice(
          userId: userId,
          deviceToken: deviceToken,
          platform: platform,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        await UserDevice.db.insertRow(session, device);
        session.log('Successfully created new UserDevice record.');
      } else {
        // Update existing (even if it was assigned to a different user, we take ownership)
        session.log(
          'Device token already exists (ID: ${device.id}, Current Owner: ${device.userId}). Updating/Taking ownership.',
        );
        device = device.copyWith(
          userId: userId,
          platform: platform,
          isActive: true,
          updatedAt: now,
        );
        await UserDevice.db.updateRow(session, device);
        session.log('Successfully updated UserDevice record.');
      }
    } catch (e, stackTrace) {
      session.log(
        'CRITICAL ERROR in registerDeviceToken: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
      // We rethrow so the 500 persists until we see the specific error in logs
      rethrow;
    }
  }

  /// Deactivate a device token (e.g., when user logs out)
  Future<void> deactivateDeviceToken(
    Session session,
    String deviceToken,
  ) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      session.log('Not authenticated. Skipping.');
      return;
    }

    final device = await UserDevice.db.findFirstRow(
      session,
      where: (d) => d.deviceToken.equals(deviceToken),
    );

    if (device != null) {
      final updatedDevice = device.copyWith(
        isActive: false,
        updatedAt: DateTime.now().toUtc(),
      );

      await UserDevice.db.updateRow(session, updatedDevice);

      session.log(
        'Deactivated device token',
        level: LogLevel.info,
      );
    }
  }

  /// Send a push notification to a specific user
  ///
  /// [userId] - The auth user ID
  /// [title] - Notification title
  /// [body] - Notification body
  /// [data] - Optional custom data payload
  ///
  /// Returns true if notification was sent to at least one device
  Future<bool> sendNotificationToUser(
    Session session,
    int userId,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    // Get all active device tokens for this user
    final devices = await UserDevice.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.isActive.equals(true),
    );

    if (devices.isEmpty) {
      session.log(
        'No active devices found for user $userId',
        level: LogLevel.warning,
      );
      return false;
    }

    bool anySuccess = false;
    for (final device in devices) {
      final success = await _fcmService.sendNotificationToDevice(
        deviceToken: device.deviceToken,
        title: title,
        body: body,
        data: data,
        session: session,
      );

      if (success) {
        anySuccess = true;
      } else {
        // If notification fails, the token might be invalid
        // Consider deactivating it after multiple failures
        session.log(
          'Failed to send notification to device ${device.deviceToken}',
          level: LogLevel.warning,
        );
      }
    }

    return anySuccess;
  }

  /// Send a notification to the current authenticated user
  Future<bool> sendNotificationToMe(
    Session session,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      session.log('Not authenticated. Skipping.');
      return false;
    }

    final authUserId = authInfo.authUserId;

    final user = await User.db.findFirstRow(
      session,
      where: (u) => u.authUserId.equals(authUserId),
    );

    if (user == null || user.id == null) return false;

    return await sendNotificationToUser(
      session,
      user.id!,
      title,
      body,
      data: data,
    );
  }

  /// Send notification to multiple users
  ///
  /// [userIds] - List of auth user IDs
  /// [title] - Notification title
  /// [body] - Notification body
  /// [data] - Optional custom data payload
  ///
  /// Returns a map of userId -> success status
  Future<Map<String, bool>> sendNotificationToMultipleUsers(
    Session session,
    List<int> userIds,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    final results = <String, bool>{};

    for (final userId in userIds) {
      final success = await sendNotificationToUser(
        session,
        userId,
        title,
        body,
        data: data,
      );
      results[userId.toString()] = success;
    }

    return results;
  }

  /// Send notification to a topic
  ///
  /// [topic] - The FCM topic name
  /// [title] - Notification title
  /// [body] - Notification body
  /// [data] - Optional custom data payload
  Future<bool> sendNotificationToTopic(
    Session session,
    String topic,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    return await _fcmService.sendNotificationToTopic(
      topic: topic,
      title: title,
      body: body,
      data: data,
      session: session,
    );
  }

  /// Get all active devices for the current user
  Future<List<UserDevice>> getMyDevices(Session session) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      return [];
    }

    final user = await User.db.findFirstRow(
      session,
      where: (u) => u.authUserId.equals(authInfo.authUserId),
    );

    if (user == null || user.id == null) return [];

    return await UserDevice.db.find(
      session,
      where: (t) => t.userId.equals(user.id!) & t.isActive.equals(true),
    );
  }

  /// Send notification to all users
  ///
  /// [title] - Notification title
  /// [body] - Notification body
  /// [data] - Optional custom data payload
  Future<bool> sendNotificationToAllUsers(
    Session session,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    // We use the 'all_users' topic that clients subscribe to
    return await sendNotificationToTopic(
      session,
      'all_users',
      title,
      body,
      data: data,
    );
  }

  /// Send notification when a user starts reading a book
  ///
  /// [bookTitle] - The title of the book being started
  /// Sends to the 'all_users' topic to notify all users
  Future<bool> sendReadingStartedNotification(
    Session session,
    String bookTitle,
  ) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      session.log('Not authenticated. Skipping.');
      return false;
    }

    // Get the user's name
    final user = await User.db.findFirstRow(
      session,
      where: (u) => u.authUserId.equals(authInfo.authUserId),
    );

    final userName = user?.username ?? 'Someone';

    // Send notification to all users
    return await sendNotificationToTopic(
      session,
      'all_users',
      '📚 New Reader Alert!',
      '$userName just started reading "$bookTitle"',
      // data: {
      //   'type': 'reading_started',
      //   'bookTitle': bookTitle,
      //   'userName': userName,
      // },
    );
  }

  /// Clean up inactive or old device tokens
  ///
  /// Removes devices that haven't been updated in the specified number of days
  Future<int> cleanupOldDevices(Session session, {int daysOld = 90}) async {
    final cutoffDate = DateTime.now().toUtc().subtract(Duration(days: daysOld));

    // deleteWhere returns a List<UserDevice> of the models deleted
    final deletedDevices = await UserDevice.db.deleteWhere(
      session,
      where: (t) => t.updatedAt < cutoffDate,
    );

    session.log(
      'Cleaned up ${deletedDevices.length} old device tokens',
      level: LogLevel.info,
    );

    return deletedDevices.length;
  }
}
