/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import '../user/user.dart' as _i2;
import 'package:project_thera_client/src/protocol/protocol.dart' as _i3;

abstract class LeaderboardEntry implements _i1.SerializableModel {
  LeaderboardEntry._({
    this.id,
    required this.points,
    required this.name,
    required this.books,
    required this.pages,
    this.email,
    required this.userId,
    this.user,
  });

  factory LeaderboardEntry({
    int? id,
    required int points,
    required String name,
    required int books,
    required int pages,
    String? email,
    required int userId,
    _i2.User? user,
  }) = _LeaderboardEntryImpl;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return LeaderboardEntry(
      id: jsonSerialization['id'] as int?,
      points: jsonSerialization['points'] as int,
      name: jsonSerialization['name'] as String,
      books: jsonSerialization['books'] as int,
      pages: jsonSerialization['pages'] as int,
      email: jsonSerialization['email'] as String?,
      userId: jsonSerialization['userId'] as int,
      user: jsonSerialization['user'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.User>(jsonSerialization['user']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int points;

  String name;

  int books;

  int pages;

  String? email;

  int userId;

  /// Reference the User class directly to create a proper relation
  _i2.User? user;

  /// Returns a shallow copy of this [LeaderboardEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LeaderboardEntry copyWith({
    int? id,
    int? points,
    String? name,
    int? books,
    int? pages,
    String? email,
    int? userId,
    _i2.User? user,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LeaderboardEntry',
      if (id != null) 'id': id,
      'points': points,
      'name': name,
      'books': books,
      'pages': pages,
      if (email != null) 'email': email,
      'userId': userId,
      if (user != null) 'user': user?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LeaderboardEntryImpl extends LeaderboardEntry {
  _LeaderboardEntryImpl({
    int? id,
    required int points,
    required String name,
    required int books,
    required int pages,
    String? email,
    required int userId,
    _i2.User? user,
  }) : super._(
         id: id,
         points: points,
         name: name,
         books: books,
         pages: pages,
         email: email,
         userId: userId,
         user: user,
       );

  /// Returns a shallow copy of this [LeaderboardEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LeaderboardEntry copyWith({
    Object? id = _Undefined,
    int? points,
    String? name,
    int? books,
    int? pages,
    Object? email = _Undefined,
    int? userId,
    Object? user = _Undefined,
  }) {
    return LeaderboardEntry(
      id: id is int? ? id : this.id,
      points: points ?? this.points,
      name: name ?? this.name,
      books: books ?? this.books,
      pages: pages ?? this.pages,
      email: email is String? ? email : this.email,
      userId: userId ?? this.userId,
      user: user is _i2.User? ? user : this.user?.copyWith(),
    );
  }
}
