import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const String _streakKey = 'reading_streak';
  static const String _lastReadingDateKey = 'last_reading_date';

  /// Get current daily streak
  Future<int> getCurrentStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streakData = prefs.getString(_streakKey);
      
      if (streakData == null) {
        return 0;
      }

      final data = json.decode(streakData) as Map<String, dynamic>;
      final lastReadingDateStr = data['lastReadingDate'] as String?;
      final streakCount = data['streak'] as int? ?? 0;

      if (lastReadingDateStr == null) {
        return 0;
      }

      final lastReadingDate = DateTime.parse(lastReadingDateStr);
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);
      final normalizedLastDate = DateTime(
        lastReadingDate.year,
        lastReadingDate.month,
        lastReadingDate.day,
      );

      // Calculate days difference
      final daysDifference = normalizedToday.difference(normalizedLastDate).inDays;

      if (daysDifference == 0) {
        // Read today, streak continues
        return streakCount;
      } else if (daysDifference == 1) {
        // Read yesterday, streak continues
        return streakCount;
      } else {
        // Streak broken, reset to 0
        await _resetStreak();
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  /// Update streak when reading activity is recorded
  Future<int> updateStreak(DateTime readingDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedDate = DateTime(
        readingDate.year,
        readingDate.month,
        readingDate.day,
      );

      final currentStreak = await getCurrentStreak();
      final lastReadingDateStr = prefs.getString(_lastReadingDateKey);

      if (lastReadingDateStr != null) {
        final lastReadingDate = DateTime.parse(lastReadingDateStr);
        final normalizedLastDate = DateTime(
          lastReadingDate.year,
          lastReadingDate.month,
          lastReadingDate.day,
        );

        final daysDifference = normalizedDate.difference(normalizedLastDate).inDays;

        if (daysDifference == 0) {
          // Same day, don't update
          return currentStreak;
        } else if (daysDifference == 1) {
          // Consecutive day, increment streak
          final newStreak = currentStreak + 1;
          await _saveStreak(newStreak, normalizedDate);
          return newStreak;
        } else {
          // Streak broken, start new streak
          await _saveStreak(1, normalizedDate);
          return 1;
        }
      } else {
        // First reading, start streak
        await _saveStreak(1, normalizedDate);
        return 1;
      }
    } catch (e) {
      return 0;
    }
  }

  /// Get longest streak ever achieved
  Future<int> getLongestStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('longest_streak') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _saveStreak(int streak, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save streak data
      final streakData = json.encode({
        'streak': streak,
        'lastReadingDate': date.toIso8601String(),
      });
      await prefs.setString(_streakKey, streakData);
      await prefs.setString(_lastReadingDateKey, date.toIso8601String());

      // Update longest streak if current is longer
      final longestStreak = await getLongestStreak();
      if (streak > longestStreak) {
        await prefs.setInt('longest_streak', streak);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _resetStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_streakKey);
      await prefs.remove(_lastReadingDateKey);
    } catch (e) {
      // Handle error silently
    }
  }
}
