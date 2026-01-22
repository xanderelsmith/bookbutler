import 'package:flutter/material.dart';

/// Model for offline reminder notification settings
class OfflineReminderSettings {
  final bool enabled;
  final TimeOfDay time;

  const OfflineReminderSettings({required this.enabled, required this.time});

  /// Default settings: disabled, 8:00 PM
  factory OfflineReminderSettings.defaultSettings() {
    return const OfflineReminderSettings(
      enabled: false,
      time: TimeOfDay(hour: 20, minute: 0),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {'enabled': enabled, 'hour': time.hour, 'minute': time.minute};
  }

  /// Create from JSON
  factory OfflineReminderSettings.fromJson(Map<String, dynamic> json) {
    return OfflineReminderSettings(
      enabled: json['enabled'] as bool? ?? false,
      time: TimeOfDay(
        hour: json['hour'] as int? ?? 20,
        minute: json['minute'] as int? ?? 0,
      ),
    );
  }

  /// Create a copy with updated values
  OfflineReminderSettings copyWith({bool? enabled, TimeOfDay? time}) {
    return OfflineReminderSettings(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
    );
  }
}
