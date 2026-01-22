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
    final authInfo = session.authenticated;
    if (authInfo == null) {
      throw Exception('User must be authenticated');
    }

    final authUserId = authInfo.authUserId;

    // Check if this device token already exists
    var existingDevice = await UserDevice.db.findFirstRow(
      session,
      where: (d) => d.deviceToken.equals(deviceToken),
    );

    final now = DateTime.now().toUtc();

    if (existingDevice == null) {
      // Create new device record
      final device = UserDevice(
        authUserId: authUserId,
        deviceToken: deviceToken,
        platform: platform,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await UserDevice.db.insertRow(session, device);

      session.log(
        'Registered new device token for user $authUserId',
        level: LogLevel.info,
      );
    } else {
      // Update existing device record
      existingDevice = existingDevice.copyWith(
        authUserId: authUserId,
        platform: platform,
        isActive: true,
        updatedAt: now,
      );

      await UserDevice.db.updateRow(session, existingDevice);

      session.log(
        'Updated device token for user $authUserId',
        level: LogLevel.info,
      );
    }
  }

  /// Deactivate a device token (e.g., when user logs out)
  Future<void> deactivateDeviceToken(
    Session session,
    String deviceToken,
  ) async {
    final authInfo = await session.authenticated;
    if (authInfo == null) {
      throw Exception('User must be authenticated');
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
    UuidValue userId,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    // Get all active device tokens for this user
    final devices = await UserDevice.db.find(
      session,
      where: (t) => t.authUserId.equals(userId) & t.isActive.equals(true),
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
      throw Exception('User must be authenticated');
    }

    return await sendNotificationToUser(
      session,
      authInfo.authUserId,
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
    List<UuidValue> userIds,
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
      results[userId.uuid] = success;
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
    final authInfo = await session.authenticated;
    if (authInfo == null) {
      throw Exception('User must be authenticated');
    }

    return await UserDevice.db.find(
      session,
      where: (t) =>
          t.authUserId.equals(authInfo.authUserId) & t.isActive.equals(true),
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
