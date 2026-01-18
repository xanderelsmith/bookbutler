import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class HomeWidgetService {
  static const String _widgetEnabledKey = 'home_widget_enabled';
  static const String _widgetNameKey = 'HomeWidget';
  static const String _widgetGroupId = 'group.com.example.project_thera';

  /// Initialize home widget
  Future<bool> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_widgetGroupId);
      return true;
    } catch (e) {
      log('Error initializing home widget: $e');
      return false;
    }
  }

  /// Check if home widget is enabled
  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_widgetEnabledKey) ?? false;
    } catch (e) {
      log('Error checking home widget enabled status: $e');
      return false;
    }
  }

  /// Check if request pin widget is supported (Android 8.0+)
  Future<bool> isRequestPinWidgetSupported() async {
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported();
      return supported ?? false;
    } catch (e) {
      log('Error checking pin widget support: $e');
      return false;
    }
  }

  /// Request to pin the widget to home screen (Android 8.0+)
  Future<bool> requestPinWidget() async {
    try {
      if (Platform.isAndroid) {
        final supported = await isRequestPinWidgetSupported();
        if (!supported) {
          log('⚠️ Widget pinning not supported on this device/launcher');
          return false;
        }

        await HomeWidget.requestPinWidget(
          qualifiedAndroidName: 'com.example.project_thera.HomeWidgetProvider',
        );
        log('✅ Widget pin request sent');
        return true;
      }
      return false;
    } catch (e) {
      log('Error requesting pin widget: $e');
      return false;
    }
  }

  /// Enable or disable home widget
  Future<bool> setEnabled(bool enabled, {bool skipUpdate = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_widgetEnabledKey, enabled);

      if (!enabled && !skipUpdate) {
        // Clear widget data when disabled
        await clearWidgetData();
      }
      // Don't update widget when enabling to avoid errors if native setup is missing

      return true;
    } catch (e) {
      log('Error setting home widget enabled: $e');
      return false;
    }
  }

  /// Update home widget with currently reading book and streak
  Future<bool> updateWidgetData({
    Book? currentlyReading,
    required int dailyStreak,
  }) async {
    try {
      final enabled = await isEnabled();
      if (!enabled) {
        log('Home widget is disabled, skipping update');
        return false;
      }

      await HomeWidget.saveWidgetData<String>(
        'currently_reading_title',
        currentlyReading?.title ?? 'No book in progress',
      );

      await HomeWidget.saveWidgetData<String>(
        'currently_reading_author',
        currentlyReading?.author ?? '',
      );

      await HomeWidget.saveWidgetData<int>(
        'currently_reading_progress',
        currentlyReading?.progress ?? 0,
      );

      await HomeWidget.saveWidgetData<int>(
        'currently_reading_current_page',
        currentlyReading?.currentPage ?? 0,
      );

      await HomeWidget.saveWidgetData<int>(
        'currently_reading_total_pages',
        currentlyReading?.totalPages ?? 0,
      );

      await HomeWidget.saveWidgetData<String>(
        'daily_streak',
        '$dailyStreak days',
      );

      await HomeWidget.saveWidgetData<int>('streak_count', dailyStreak);

      // Save timestamp for last update
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateTime.now().toIso8601String(),
      );

      // Update the widget - handle gracefully if widget not configured
      try {
        if (Platform.isAndroid) {
          // Update Android widget using qualified name
          await HomeWidget.updateWidget(
            qualifiedAndroidName: 'com.example.project_thera.HomeWidgetProvider',
          );
          log('✅ Android home widget updated successfully');
        } else {
          // iOS widget update
          await HomeWidget.updateWidget(
            name: _widgetNameKey,
            iOSName: 'HomeWidget',
          );
          log('✅ iOS home widget updated successfully');
        }
      } on PlatformException catch (e) {
        // Widget not configured on native side - this is okay
        if (e.code == '-3' || e.message?.contains('No Widget found') == true) {
          log(
            'ℹ️ Home widget not configured on native side - widget updates disabled',
          );
          // Disable widget feature if native setup is missing (skip update to avoid recursion)
          await setEnabled(false, skipUpdate: true);
          return false;
        }
        log('⚠️ Error updating widget: $e');
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      log('❌ Error updating home widget: $e');
      log('Stack trace: $stackTrace');
      // Don't throw - widget updates are optional
      return false;
    }
  }

  /// Clear all widget data
  Future<bool> clearWidgetData() async {
    try {
      await HomeWidget.saveWidgetData<String>('currently_reading_title', '');
      await HomeWidget.saveWidgetData<String>('currently_reading_author', '');
      await HomeWidget.saveWidgetData<int>('currently_reading_progress', 0);
      await HomeWidget.saveWidgetData<int>('currently_reading_current_page', 0);
      await HomeWidget.saveWidgetData<int>('currently_reading_total_pages', 0);
      await HomeWidget.saveWidgetData<String>('daily_streak', '');
      await HomeWidget.saveWidgetData<int>('streak_count', 0);
      await HomeWidget.saveWidgetData<String>('last_updated', '');

      // Update widget after clearing data
      try {
        if (Platform.isAndroid) {
          await HomeWidget.updateWidget(
            qualifiedAndroidName: 'com.example.project_thera.HomeWidgetProvider',
          );
        } else {
          await HomeWidget.updateWidget(
            name: _widgetNameKey,
            iOSName: 'HomeWidget',
          );
        }
      } on PlatformException catch (e) {
        // Widget not configured - this is okay when clearing
        if (e.code == '-3' || e.message?.contains('No Widget found') == true) {
          log('ℹ️ Widget not configured, skipping update');
        } else {
          log('⚠️ Error updating widget: $e');
        }
      }

      return true;
    } catch (e) {
      log('Error clearing widget data: $e');
      return false;
    }
  }
}
