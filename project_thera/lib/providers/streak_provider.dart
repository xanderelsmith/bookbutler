import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/streak_service.dart';

// Provider for StreakService (singleton)
final streakServiceProvider = Provider<StreakService>((ref) {
  return StreakService();
});

// Provider for current streak
final currentStreakProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(streakServiceProvider);
  return await service.getCurrentStreak();
});

// Provider for longest streak
final longestStreakProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(streakServiceProvider);
  return await service.getLongestStreak();
});
