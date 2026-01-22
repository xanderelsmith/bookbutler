import 'dart:async';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'dart:developer' as developer;
import 'fcm_service.dart';

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  static LeaderboardService get instance => _instance;

  LeaderboardService._internal();

  /// Creates or updates a leaderboard entry for a user.
  ///
  /// [authUserId] is required to look up the user.
  Future<LeaderboardEntry> upsertEntry(
    Session session, {
    required int points,
    required String name,
    required int books,
    required int pages,
    required UuidValue authUserId,
    String? email,
  }) async {
    try {
      final user = await User.db.findFirstRow(
        session,
        where: (u) => u.authUserId.equals(authUserId),
      );

      if (user == null) {
        throw Exception(
          'User profile not found. Please create a user profile first.',
        );
      }

      final finalName = name.isNotEmpty
          ? name
          : (email?.isNotEmpty == true ? email! : 'Reader');

      var entry = await LeaderboardEntry.db.findFirstRow(
        session,
        where: (e) => e.userId.equals(user.id!),
      );

      if (entry == null) {
        entry = await LeaderboardEntry.db.insertRow(
          session,
          LeaderboardEntry(
            points: points,
            name: finalName,
            books: books,
            pages: pages,
            email: email,
            userId: user.id!,
          ),
        );
      } else {
        entry.points = points;
        entry.name = finalName;
        entry.books = books;
        entry.pages = pages;
        entry.email = email ?? entry.email;

        entry = await LeaderboardEntry.db.updateRow(session, entry);
      }

      final savedEntry = (await LeaderboardEntry.db.findById(
        session,
        entry.id!,
        include: LeaderboardEntry.include(user: User.include()),
      ))!;

      // Send notification to all users about the update
      // We do this asynchronously to not block the response
      unawaited(
        FCMService.instance.sendNotificationToTopic(
          session: session,
          topic: 'all_users',
          title: 'Leaderboard Update',
          body: '${finalName} just reached $points points with $books books!',
          data: {
            'type': 'leaderboard',
            'entryId': savedEntry.id.toString(),
          },
        ),
      );

      return savedEntry;
    } catch (e, stackTrace) {
      developer.log(
        '❌ [LeaderboardService] Error in upsertEntry: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'LeaderboardService.upsertEntry',
      );
      rethrow;
    }
  }
}
