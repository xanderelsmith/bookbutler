import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/reading_goal_service.dart';

final readingGoalServiceProvider = Provider<ReadingGoalService>((ref) {
  return ReadingGoalService();
});

final readingGoalProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(readingGoalServiceProvider);
  return await service.getGoal();
});
