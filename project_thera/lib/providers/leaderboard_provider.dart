import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_thera_client/project_thera_client.dart';
import '../services/leaderboard_service.dart';
import 'serverpod_provider.dart';

/// Provider for leaderboard service
final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  final serverpodService = ref.read(serverpodServiceProvider);
  return LeaderboardService(serverpodService);
});

/// Provider for top leaderboard entries with real-time streaming updates
final leaderboardEntriesProvider = StreamProvider<List<LeaderboardEntry>>((
  ref,
) {
  final service = ref.watch(leaderboardServiceProvider);
  final serverpodService = ref.read(serverpodServiceProvider);
  final controller = StreamController<List<LeaderboardEntry>>();

  // Initialize and then forward the server stream
  serverpodService
      .initialize()
      .then((_) {
        final serverStream = service.streamTopEntries(
          limit: 20,
          updateIntervalSeconds: 3,
        );
        serverStream.listen(
          (entries) {
            if (!controller.isClosed) {
              controller.add(entries);
            }
          },
          onError: (error) {
            if (!controller.isClosed) {
              controller.addError(error);
            }
          },
          onDone: () {
            if (!controller.isClosed) {
              controller.close();
            }
          },
        );
      })
      .catchError((error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      });

  ref.onDispose(() {
    if (!controller.isClosed) {
      controller.close();
    }
  });

  return controller.stream;
});

/// Provider for current user's leaderboard entry
final currentUserLeaderboardProvider = FutureProvider<LeaderboardEntry?>((
  ref,
) async {
  final service = ref.watch(leaderboardServiceProvider);
  try {
    return await service.getCurrentUserEntry();
  } catch (e) {
    return null;
  }
});

/// Provider for current user's rank
final currentUserRankProvider = FutureProvider<int?>((ref) async {
  final service = ref.watch(leaderboardServiceProvider);
  try {
    return await service.getCurrentUserRank();
  } catch (e) {
    return null;
  }
});
