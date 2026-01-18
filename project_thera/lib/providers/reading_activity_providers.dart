import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reading_activity.dart';
import '../services/reading_activity_service.dart';
import '../services/streak_service.dart';
import 'streak_provider.dart';

// Provider for ReadingActivityService (singleton)
final readingActivityServiceProvider = Provider<ReadingActivityService>((ref) {
  return ReadingActivityService();
});

// StateNotifier for managing reading activities
class ReadingActivitiesNotifier extends StateNotifier<AsyncValue<List<ReadingActivity>>> {
  ReadingActivitiesNotifier(this._service, this._streakService) : super(const AsyncValue.loading()) {
    loadActivities();
  }

  final ReadingActivityService _service;
  final StreakService _streakService;

  Future<void> loadActivities() async {
    state = const AsyncValue.loading();
    try {
      final activities = await _service.getAllActivities();
      state = AsyncValue.data(activities);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> addActivity(ReadingActivity activity) async {
    try {
      final success = await _service.addActivity(activity);
      if (success) {
        await loadActivities();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDailyActivity(DateTime date, int pagesRead, int minutesSpent, String bookId) async {
    try {
      final success = await _service.updateDailyActivity(date, pagesRead, minutesSpent, bookId);
      if (success) {
        await loadActivities();
        
        // Update streak when reading activity is recorded
        if (pagesRead > 0) {
          await _streakService.updateStreak(date);
        }
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

// Provider for activities notifier
final readingActivitiesProvider = StateNotifierProvider<ReadingActivitiesNotifier, AsyncValue<List<ReadingActivity>>>((ref) {
  final service = ref.watch(readingActivityServiceProvider);
  final streakService = ref.watch(streakServiceProvider);
  return ReadingActivitiesNotifier(service, streakService);
});

// Provider for monthly activities (grouped by month)
final monthlyActivitiesProvider = Provider.family<List<Map<DateTime, int>>, DateTime>((ref, month) {
  final activitiesAsync = ref.watch(readingActivitiesProvider);
  return activitiesAsync.when(
    data: (activities) {
      final Map<DateTime, int> monthMap = {};
      for (var activity in activities) {
        if (activity.date.year == month.year && activity.date.month == month.month) {
          final date = DateTime(activity.date.year, activity.date.month, activity.date.day);
          monthMap[date] = (monthMap[date] ?? 0) + activity.pagesRead;
        }
      }
      return [monthMap];
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
