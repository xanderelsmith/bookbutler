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

/// Device token model for storing FCM/APNs tokens
/// This stores the push notification tokens for each user's devices
abstract class UserDevice implements _i1.SerializableModel {
  UserDevice._({
    this.id,
    required this.authUserId,
    this.authUser,
    required this.deviceToken,
    required this.platform,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory UserDevice({
    int? id,
    required _i1.UuidValue authUserId,
    _i2.AuthUser? authUser,
    required String deviceToken,
    required String platform,
    required bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserDeviceImpl;

  factory UserDevice.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserDevice(
      id: jsonSerialization['id'] as int?,
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      authUser: jsonSerialization['authUser'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.AuthUser>(
              jsonSerialization['authUser'],
            ),
      deviceToken: jsonSerialization['deviceToken'] as String,
      platform: jsonSerialization['platform'] as String,
      isActive: jsonSerialization['isActive'] as bool,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue authUserId;

  /// The [AuthUser] this device belongs to
  /// This creates a proper database relation with cascade delete
  _i2.AuthUser? authUser;

  /// FCM token (Android) or APNs token (iOS)
  /// Now properly persisted in database (removed !persist)
  String deviceToken;

  /// Platform: 'android' or 'ios'
  String platform;

  /// Whether this device is still active
  bool isActive;

  /// When the token was registered
  DateTime? createdAt;

  /// When the token was last updated
  DateTime? updatedAt;

  /// Returns a shallow copy of this [UserDevice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserDevice copyWith({
    int? id,
    _i1.UuidValue? authUserId,
    _i2.AuthUser? authUser,
    String? deviceToken,
    String? platform,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserDevice',
      if (id != null) 'id': id,
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'deviceToken': deviceToken,
      'platform': platform,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserDeviceImpl extends UserDevice {
  _UserDeviceImpl({
    int? id,
    required _i1.UuidValue authUserId,
    _i2.AuthUser? authUser,
    required String deviceToken,
    required String platform,
    required bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         authUser: authUser,
         deviceToken: deviceToken,
         platform: platform,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [UserDevice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserDevice copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? authUserId,
    Object? authUser = _Undefined,
    String? deviceToken,
    String? platform,
    bool? isActive,
    Object? createdAt = _Undefined,
    Object? updatedAt = _Undefined,
  }) {
    return UserDevice(
      id: id is int? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _i2.AuthUser?
          ? authUser
          : this.authUser?.copyWith(),
      deviceToken: deviceToken ?? this.deviceToken,
      platform: platform ?? this.platform,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
      updatedAt: updatedAt is DateTime? ? updatedAt : this.updatedAt,
    );
  }
}
