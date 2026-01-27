import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_activity.dart';

class ReadingActivityService {
  static const String _activitiesKey = 'reading_activities';

  Future<List<ReadingActivity>> getAllActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = prefs.getString(_activitiesKey);

      if (activitiesJson == null || activitiesJson.isEmpty) {
        return [];
      }

      final List<dynamic> activitiesList = json.decode(activitiesJson);
      return activitiesList
          .map((json) => ReadingActivity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> addActivity(ReadingActivity activity) async {
    final activities = await getAllActivities();
    activities.add(activity);
    return await _saveActivities(activities);
  }

  Future<bool> updateDailyActivity(
    DateTime date,
    int pagesRead,
    int minutesSpent,
    String bookId,
  ) async {
    final activities = await getAllActivities();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final index = activities.indexWhere(
      (a) => DateTime(a.date.year, a.date.month, a.date.day) == normalizedDate,
    );

    if (index != -1) {
      // Update existing activity
      final existing = activities[index];
      final updatedBookIds = existing.bookIds.contains(bookId)
          ? existing.bookIds
          : [...existing.bookIds, bookId];
      activities[index] = existing.copyWith(
        pagesRead: existing.pagesRead + pagesRead,
        minutesSpent: existing.minutesSpent + minutesSpent,
        bookIds: updatedBookIds,
      );
    } else {
      // Create new activity
      activities.add(
        ReadingActivity(
          date: normalizedDate,
          pagesRead: pagesRead,
          minutesSpent: minutesSpent,
          bookIds: [bookId],
        ),
      );
    }

    return await _saveActivities(activities);
  }

  Future<bool> _saveActivities(List<ReadingActivity> activities) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = json.encode(
        activities.map((activity) => activity.toJson()).toList(),
      );
      return await prefs.setString(_activitiesKey, activitiesJson);
    } catch (e) {
      return false;
    }
  }
}
