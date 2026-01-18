/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../user/user.dart' as _i2;
import 'package:project_thera_server/src/generated/protocol.dart' as _i3;

abstract class LeaderboardEntry
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = LeaderboardEntryTable();

  static const db = LeaderboardEntryRepository._();

  @override
  int? id;

  int points;

  String name;

  int books;

  int pages;

  String? email;

  int userId;

  /// Reference the User class directly to create a proper relation
  _i2.User? user;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LeaderboardEntry',
      if (id != null) 'id': id,
      'points': points,
      'name': name,
      'books': books,
      'pages': pages,
      if (email != null) 'email': email,
      'userId': userId,
      if (user != null) 'user': user?.toJsonForProtocol(),
    };
  }

  static LeaderboardEntryInclude include({_i2.UserInclude? user}) {
    return LeaderboardEntryInclude._(user: user);
  }

  static LeaderboardEntryIncludeList includeList({
    _i1.WhereExpressionBuilder<LeaderboardEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LeaderboardEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LeaderboardEntryTable>? orderByList,
    LeaderboardEntryInclude? include,
  }) {
    return LeaderboardEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LeaderboardEntry.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(LeaderboardEntry.t),
      include: include,
    );
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

class LeaderboardEntryUpdateTable
    extends _i1.UpdateTable<LeaderboardEntryTable> {
  LeaderboardEntryUpdateTable(super.table);

  _i1.ColumnValue<int, int> points(int value) => _i1.ColumnValue(
    table.points,
    value,
  );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<int, int> books(int value) => _i1.ColumnValue(
    table.books,
    value,
  );

  _i1.ColumnValue<int, int> pages(int value) => _i1.ColumnValue(
    table.pages,
    value,
  );

  _i1.ColumnValue<String, String> email(String? value) => _i1.ColumnValue(
    table.email,
    value,
  );

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
    value,
  );
}

class LeaderboardEntryTable extends _i1.Table<int?> {
  LeaderboardEntryTable({super.tableRelation})
    : super(tableName: 'leaderboard_entry') {
    updateTable = LeaderboardEntryUpdateTable(this);
    points = _i1.ColumnInt(
      'points',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    books = _i1.ColumnInt(
      'books',
      this,
    );
    pages = _i1.ColumnInt(
      'pages',
      this,
    );
    email = _i1.ColumnString(
      'email',
      this,
    );
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
  }

  late final LeaderboardEntryUpdateTable updateTable;

  late final _i1.ColumnInt points;

  late final _i1.ColumnString name;

  late final _i1.ColumnInt books;

  late final _i1.ColumnInt pages;

  late final _i1.ColumnString email;

  late final _i1.ColumnInt userId;

  /// Reference the User class directly to create a proper relation
  _i2.UserTable? _user;

  _i2.UserTable get user {
    if (_user != null) return _user!;
    _user = _i1.createRelationTable(
      relationFieldName: 'user',
      field: LeaderboardEntry.t.userId,
      foreignField: _i2.User.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.UserTable(tableRelation: foreignTableRelation),
    );
    return _user!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    points,
    name,
    books,
    pages,
    email,
    userId,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'user') {
      return user;
    }
    return null;
  }
}

class LeaderboardEntryInclude extends _i1.IncludeObject {
  LeaderboardEntryInclude._({_i2.UserInclude? user}) {
    _user = user;
  }

  _i2.UserInclude? _user;

  @override
  Map<String, _i1.Include?> get includes => {'user': _user};

  @override
  _i1.Table<int?> get table => LeaderboardEntry.t;
}

class LeaderboardEntryIncludeList extends _i1.IncludeList {
  LeaderboardEntryIncludeList._({
    _i1.WhereExpressionBuilder<LeaderboardEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LeaderboardEntry.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => LeaderboardEntry.t;
}

class LeaderboardEntryRepository {
  const LeaderboardEntryRepository._();

  final attachRow = const LeaderboardEntryAttachRowRepository._();

  /// Returns a list of [LeaderboardEntry]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<LeaderboardEntry>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LeaderboardEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LeaderboardEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LeaderboardEntryTable>? orderByList,
    _i1.Transaction? transaction,
    LeaderboardEntryInclude? include,
  }) async {
    return session.db.find<LeaderboardEntry>(
      where: where?.call(LeaderboardEntry.t),
      orderBy: orderBy?.call(LeaderboardEntry.t),
      orderByList: orderByList?.call(LeaderboardEntry.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
    );
  }

  /// Returns the first matching [LeaderboardEntry] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<LeaderboardEntry?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LeaderboardEntryTable>? where,
    int? offset,
    _i1.OrderByBuilder<LeaderboardEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LeaderboardEntryTable>? orderByList,
    _i1.Transaction? transaction,
    LeaderboardEntryInclude? include,
  }) async {
    return session.db.findFirstRow<LeaderboardEntry>(
      where: where?.call(LeaderboardEntry.t),
      orderBy: orderBy?.call(LeaderboardEntry.t),
      orderByList: orderByList?.call(LeaderboardEntry.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
    );
  }

  /// Finds a single [LeaderboardEntry] by its [id] or null if no such row exists.
  Future<LeaderboardEntry?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
    LeaderboardEntryInclude? include,
  }) async {
    return session.db.findById<LeaderboardEntry>(
      id,
      transaction: transaction,
      include: include,
    );
  }

  /// Inserts all [LeaderboardEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [LeaderboardEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<LeaderboardEntry>> insert(
    _i1.Session session,
    List<LeaderboardEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<LeaderboardEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [LeaderboardEntry] and returns the inserted row.
  ///
  /// The returned [LeaderboardEntry] will have its `id` field set.
  Future<LeaderboardEntry> insertRow(
    _i1.Session session,
    LeaderboardEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<LeaderboardEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [LeaderboardEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<LeaderboardEntry>> update(
    _i1.Session session,
    List<LeaderboardEntry> rows, {
    _i1.ColumnSelections<LeaderboardEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<LeaderboardEntry>(
      rows,
      columns: columns?.call(LeaderboardEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LeaderboardEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LeaderboardEntry> updateRow(
    _i1.Session session,
    LeaderboardEntry row, {
    _i1.ColumnSelections<LeaderboardEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<LeaderboardEntry>(
      row,
      columns: columns?.call(LeaderboardEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LeaderboardEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LeaderboardEntry?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<LeaderboardEntryUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<LeaderboardEntry>(
      id,
      columnValues: columnValues(LeaderboardEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LeaderboardEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<LeaderboardEntry>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<LeaderboardEntryUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<LeaderboardEntryTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LeaderboardEntryTable>? orderBy,
    _i1.OrderByListBuilder<LeaderboardEntryTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<LeaderboardEntry>(
      columnValues: columnValues(LeaderboardEntry.t.updateTable),
      where: where(LeaderboardEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LeaderboardEntry.t),
      orderByList: orderByList?.call(LeaderboardEntry.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [LeaderboardEntry]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<LeaderboardEntry>> delete(
    _i1.Session session,
    List<LeaderboardEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<LeaderboardEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [LeaderboardEntry].
  Future<LeaderboardEntry> deleteRow(
    _i1.Session session,
    LeaderboardEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LeaderboardEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<LeaderboardEntry>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<LeaderboardEntryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<LeaderboardEntry>(
      where: where(LeaderboardEntry.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<LeaderboardEntryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<LeaderboardEntry>(
      where: where?.call(LeaderboardEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }
}

class LeaderboardEntryAttachRowRepository {
  const LeaderboardEntryAttachRowRepository._();

  /// Creates a relation between the given [LeaderboardEntry] and [User]
  /// by setting the [LeaderboardEntry]'s foreign key `userId` to refer to the [User].
  Future<void> user(
    _i1.Session session,
    LeaderboardEntry leaderboardEntry,
    _i2.User user, {
    _i1.Transaction? transaction,
  }) async {
    if (leaderboardEntry.id == null) {
      throw ArgumentError.notNull('leaderboardEntry.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $leaderboardEntry = leaderboardEntry.copyWith(userId: user.id);
    await session.db.updateRow<LeaderboardEntry>(
      $leaderboardEntry,
      columns: [LeaderboardEntry.t.userId],
      transaction: transaction,
    );
  }
}
