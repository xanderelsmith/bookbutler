import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import '../services/leaderboard_service.dart';

/// Endpoint for managing leaderboard entries.
/// Access this endpoint as `client.leaderboardEntry` from the Flutter client.
class LeaderboardEntryEndpoint extends Endpoint {
  /// Gets the top N leaderboard entries, ordered by points (descending).
  /// [limit] defaults to 10 if not provided.
  Future<List<LeaderboardEntry>> getTopEntries(
    Session session, {
    int limit = 10,
  }) async {
    final entries = await LeaderboardEntry.db.find(
      session,
      orderBy: (e) => e.points,
      orderDescending: true,
      limit: limit,
      include: LeaderboardEntry.include(user: User.include()),
    );

    return entries;
  }

  /// Gets the current authenticated user's leaderboard entry.
  Future<LeaderboardEntry?> getCurrentUserEntry(Session session) async {
    final authInfo = session.authenticated;
    if (authInfo == null) return null;

    // Correctly get the UuidValue from the session extension
    final authUserId = authInfo.authUserId;

    // Find the custom User profile using the authUserId
    final user = await User.db.findFirstRow(
      session,
      where: (u) => u.authUserId.equals(authUserId),
    );

    if (user == null || user.id == null) return null;

    // Find the leaderboard entry referencing our custom User id
    return await LeaderboardEntry.db.findFirstRow(
      session,
      where: (e) => e.userId.equals(user.id!),
      include: LeaderboardEntry.include(user: User.include()),
    );
  }

  /// Gets the rank of the current authenticated user.
  Future<int?> getUserRank(Session session) async {
    final entry = await getCurrentUserEntry(session);
    if (entry == null) return null;

    // Count how many entries have more points
    final rank = await LeaderboardEntry.db.count(
      session,
      where: (e) => e.points > entry.points,
    );

    return rank + 1;
  }

  /// Creates or updates a leaderboard entry for the current authenticated user.
  Future<LeaderboardEntry> upsertEntry(
    Session session, {
    required int points,
    required String name,
    required int books,
    required int pages,
    String? email,
  }) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      session.log(
        'UpsertEntry: User is NOT authenticated. They are appearing as "Guest". Push notifications will be skipped.',
        level: LogLevel.warning,
      );
      return LeaderboardEntry(
        userId: 0,
        points: 0,
        name: 'Guest',
        books: 0,
        pages: 0,
      );
    }

    return await LeaderboardService.instance.upsertEntry(
      session,
      points: points,
      name: name,
      books: books,
      pages: pages,
      authUserId: authInfo.authUserId,
      email: email,
    );
  }

  /// Gets leaderboard entries around a specific user's position.
  Future<List<LeaderboardEntry>> getEntriesAroundUser(
    Session session, {
    int range = 2,
  }) async {
    final userEntry = await getCurrentUserEntry(session);
    if (userEntry == null) return [];

    // Note: For large datasets, it's better to calculate rank first
    // and use offset/limit rather than fetching all entries.
    final allEntries = await LeaderboardEntry.db.find(
      session,
      orderBy: (e) => e.points,
      orderDescending: true,
      include: LeaderboardEntry.include(user: User.include()),
    );

    final userIndex = allEntries.indexWhere((e) => e.id == userEntry.id);
    if (userIndex == -1) return [];

    final startIndex = (userIndex - range).clamp(0, allEntries.length - 1);
    final endIndex = (userIndex + range + 1).clamp(0, allEntries.length);

    return allEntries.sublist(startIndex, endIndex);
  }

  /// Gets all leaderboard entries for pagination.
  Future<List<LeaderboardEntry>> getEntries(
    Session session, {
    int offset = 0,
    int limit = 50,
  }) async {
    return await LeaderboardEntry.db.find(
      session,
      orderBy: (e) => e.points,
      orderDescending: true,
      offset: offset,
      limit: limit,
      include: LeaderboardEntry.include(user: User.include()),
    );
  }

  /// Streams leaderboard entries with periodic updates.
  /// Yields the top N entries every [updateInterval] seconds.
  Stream<List<LeaderboardEntry>> streamTopEntries(
    Session session, {
    int limit = 10,
    int updateIntervalSeconds = 3,
  }) async* {
    // Send initial data immediately
    final initialEntries = await LeaderboardEntry.db.find(
      session,
      orderBy: (e) => e.points,
      orderDescending: true,
      limit: limit,
      include: LeaderboardEntry.include(user: User.include()),
    );
    yield initialEntries;

    // Then send periodic updates
    final timer = Stream.periodic(
      Duration(seconds: updateIntervalSeconds),
      (_) {},
    );

    await for (final _ in timer) {
      final entries = await LeaderboardEntry.db.find(
        session,
        orderBy: (e) => e.points,
        orderDescending: true,
        limit: limit,
        include: LeaderboardEntry.include(user: User.include()),
      );
      yield entries;
    }
  }
}
