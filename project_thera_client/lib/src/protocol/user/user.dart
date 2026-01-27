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
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i2;
import 'package:project_thera_client/src/protocol/protocol.dart' as _i3;

abstract class User implements _i1.SerializableModel {
  User._({
    this.id,
    required this.authUserId,
    this.authUser,
    this.username,
    this.bio,
    this.createdAt,
    this.updatedAt,
    this.email,
  });

  factory User({
    int? id,
    required _i1.UuidValue authUserId,
    _i2.AuthUser? authUser,
    String? username,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
  }) = _UserImpl;

  factory User.fromJson(Map<String, dynamic> jsonSerialization) {
    return User(
      id: jsonSerialization['id'] as int?,
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      authUser: jsonSerialization['authUser'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.AuthUser>(
              jsonSerialization['authUser'],
            ),
      username: jsonSerialization['username'] as String?,
      bio: jsonSerialization['bio'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      email: jsonSerialization['email'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue authUserId;

  /// The [AuthUser] this profile belongs to
  /// This creates a proper database relation
  _i2.AuthUser? authUser;

  String? username;

  String? bio;

  DateTime? createdAt;

  DateTime? updatedAt;

  String? email;

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  User copyWith({
    int? id,
    _i1.UuidValue? authUserId,
    _i2.AuthUser? authUser,
    String? username,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'User',
      if (id != null) 'id': id,
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toJson(),
      if (email != null) 'email': email,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserImpl extends User {
  _UserImpl({
    int? id,
    required _i1.UuidValue authUserId,
    _i2.AuthUser? authUser,
    String? username,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
  }) : super._(
         id: id,
         authUserId: authUserId,
         authUser: authUser,
         username: username,
         bio: bio,
         createdAt: createdAt,
         updatedAt: updatedAt,
         email: email,
       );

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  User copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? authUserId,
    Object? authUser = _Undefined,
    Object? username = _Undefined,
    Object? bio = _Undefined,
    Object? createdAt = _Undefined,
    Object? updatedAt = _Undefined,
    Object? email = _Undefined,
  }) {
    return User(
      id: id is int? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _i2.AuthUser?
          ? authUser
          : this.authUser?.copyWith(),
      username: username is String? ? username : this.username,
      bio: bio is String? ? bio : this.bio,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
      updatedAt: updatedAt is DateTime? ? updatedAt : this.updatedAt,
      email: email is String? ? email : this.email,
    );
  }
}
