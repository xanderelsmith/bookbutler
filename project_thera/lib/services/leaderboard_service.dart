import 'package:project_thera_client/project_thera_client.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'serverpod_service.dart';
import '../models/reading_activity.dart';

/// Service for managing leaderboard-related operations
class LeaderboardService {
  final ServerpodService _serverpodService;

  LeaderboardService(this._serverpodService);

  /// Gets the top N leaderboard entries (one-time fetch)
  Future<List<LeaderboardEntry>> getTopEntries({int limit = 10}) async {
    await _serverpodService.initialize();
    try {
      return await _serverpodService.client.leaderboardEntry.getTopEntries(
        limit: limit,
      );
    } catch (e) {
      developer.log('Error getting leaderboard entries: $e');
      rethrow;
    }
  }

  /// Streams leaderboard entries with real-time updates
  /// Note: The ServerpodService client must be initialized before calling this method
  Stream<List<LeaderboardEntry>> streamTopEntries({
    int limit = 10,
    int updateIntervalSeconds = 3,
  }) {
    // Return the stream directly from the server
    // Serverpod automatically handles the streaming connection
    // Ensure client is initialized before subscribing to this stream
    return _serverpodService.client.leaderboardEntry.streamTopEntries(
      limit: limit,
      updateIntervalSeconds: updateIntervalSeconds,
    );
  }

  /// Gets the current user's leaderboard entry
  Future<LeaderboardEntry?> getCurrentUserEntry() async {
    await _serverpodService.initialize();
    try {
      return await _serverpodService.client.leaderboardEntry
          .getCurrentUserEntry();
    } catch (e) {
      developer.log('Error getting current user entry: $e');
      return null;
    }
  }

  /// Gets the current user's rank
  Future<int?> getCurrentUserRank() async {
    await _serverpodService.initialize();
    try {
      return await _serverpodService.client.leaderboardEntry.getUserRank();
    } catch (e) {
      developer.log('Error getting user rank: $e');
      return null;
    }
  }

  /// Creates or updates the current user's leaderboard entry
  Future<LeaderboardEntry> upsertEntry({
    required int points,
    required String name,
    required int books,
    required int pages,
    String? email,
  }) async {
    await _serverpodService.initialize();
    try {
      var notification = await _serverpodService.client.leaderboardEntry
          .upsertEntry(
            points: points,
            name: name,
            books: books,
            pages: pages,
            email: email,
          );
      developer.log(
        '📊 [LeaderboardService] upsertEntry completed successfully. Entry ID: ${notification.id}, Points: ${notification.points}',
      );
      return notification;
    } catch (e) {
      developer.log('Error upserting leaderboard entry: $e');
      rethrow;
    }
  }

  /// Updates the leaderboard entry based on reading activities
  /// Formula: 5 pages = 2 points (so points = (pages / 5) * 2)
  Future<LeaderboardEntry?> updateFromReadingActivities({
    required List<ReadingActivity> activities,
    required String name,
    String? email,
  }) async {
    developer.log(
      '📊 [LeaderboardService] updateFromReadingActivities called with ${activities.length} activities, name: "$name"',
    );
    try {
      // Calculate total pages read from all activities
      int totalPages = 0;
      final Set<String> uniqueBookIds = {};

      developer.log(
        '📊 [LeaderboardService] Calculating stats from ${activities.length} activities...',
      );
      for (var activity in activities) {
        totalPages += activity.pagesRead;

        // Collect unique book IDs
        for (var bookId in activity.bookIds) {
          uniqueBookIds.add(bookId);
        }
      }

      // Calculate points: 5 pages = 2 points, so points = (pages / 5) * 2
      final points = ((totalPages / 5) * 2).round();
      final booksCount = uniqueBookIds.length;

      developer.log(
        '📊 [LeaderboardService] Calculated: totalPages=$totalPages, uniqueBooks=$booksCount, points=$points (formula: ($totalPages / 5) * 2)',
      );
      developer.log(
        '📊 [LeaderboardService] Calling upsertEntry with: name="$name", email="$email", points=$points, books=$booksCount, pages=$totalPages',
      );

      // Update leaderboard entry
      final result = await upsertEntry(
        points: points,
        name: name,
        books: booksCount,
        pages: totalPages,
        email: email,
      );

      return result;
    } catch (e, stackTrace) {
      developer.log(
        '📊 [LeaderboardService] ❌ Error updating leaderboard from reading activities: $e',
      );
      developer.log('📊 [LeaderboardService] Stack trace: $stackTrace');
      return null;
    }
  }
}
