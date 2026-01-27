import 'dart:developer';

import 'package:project_thera/main.dart';
import 'package:project_thera/models/user.dart';
import 'package:project_thera_client/project_thera_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'push_notification_service.dart';

class ServerpodService {
  static final ServerpodService _instance = ServerpodService._internal();
  factory ServerpodService() => _instance;
  ServerpodService._internal();

  static const String _serverUrlKey = 'serverpod_server_url';
  static final String defaultServerUrl =
      // 'http://$newVariable:8080/';
      'https://project-thera.api.serverpod.space/';

  static const String _userCacheKey = 'cached_user_profile';
  late Client _client;
  bool _isInitialized = false;

  Client get client => _client;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString(_serverUrlKey) ?? defaultServerUrl;

    _client =
        Client(
            serverUrl,
            connectionTimeout: const Duration(seconds: 10),
            streamingConnectionTimeout: const Duration(seconds: 5),
            disconnectStreamsOnLostInternetConnection: true,
          )
          ..connectivityMonitor = FlutterConnectivityMonitor()
          ..authSessionManager = FlutterAuthSessionManager();

    // await _client.auth.initialize();

    _isInitialized = true;
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);
    _isInitialized = false;
    await initialize();
  }

  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? defaultServerUrl;
  }

  /// Attempts to restore a previous session.
  /// Returns the UserModel if successful, null otherwise.
  /// Attempts to restore a previous session.
  /// Returns the UserModel if successful, null otherwise.
  Future<UserModel?> restoreSession() async {
    // 1. Make sure the client and auth are initialized
    await initialize(); // this should call `_client.auth.initialize()` internally

    try {
      // 2. Check if we have a valid, restored session
      final signedIn = _client.authSessionManager.isAuthenticated;

      if (signedIn) {
        developer.log('Session restored, fetching user profile...');

        try {
          // 3. Fetch fresh profile from your server
          final user = await _ensureUserProfile();

          final userModel = UserModel(
            email: user.email ?? '',
            authUserId: user.authUserId,
            nickname: user.username,
            bio: user.bio,
          );

          developer.log('Session restoration successful: $userModel');

          // 4. Cache the fresh profile
          await _cacheUser(userModel);
          return userModel;
        } catch (e) {
          developer.log(
            'Failed to fetch fresh profile, falling back to cache: $e',
          );
          // Network / server error → fall back to cache
          return await getCachedUser();
        }
      } else {
        // Not signed in → try cached user only
        return await getCachedUser();
      }
    } catch (e) {
      developer.log('Failed to restore session: $e');
      // Critical failure → last resort: cache
      return await getCachedUser();
    }
  }

  /// Logs in an existing user with email / password.
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      developer.log('Attempting to login with email: $email');
      var authSuccess = await _client.emailIdp.login(
        rememberMe: true,
        email: email,
        password: password,
      );
      await _client.emailIdp.client.authSessionManager.updateSignedInUser(
        authSuccess,
      );
      var isAuthenticated =
          _client.emailIdp.client.authSessionManager.isAuthenticated;
      log(isAuthenticated.toString());
      developer.log('Login successful for email: $email');

      // Ensure user profile exists in the custom user table
      if (isAuthenticated) {
        final user = await _ensureUserProfile();
        var userModel = UserModel(
          email: email,
          authUserId: user.authUserId,
          nickname: user.username,
          bio: user.bio,
        );
        log(userModel.toString());
        // Cache on login
        await _cacheUser(userModel);

        // Sync FCM Token
        final pushService = PushNotificationService();
        if (pushService.currentToken != null) {
          pushService.sendTokenToServer(pushService.currentToken!);
        }

        return userModel;
      }
      return null;
    } catch (e, stackTrace) {
      developer.log(
        'Login failed for email: $email',
        error: e,
        stackTrace: stackTrace,
        name: 'ServerpodService.login',
      );
      throw Exception('Login failed: $e');
    }
  }

  /// Creates a new account directly (no email verification)
  /// and logs the user in.
  Future<UserModel> registerAndLogin({
    required String email,
    required String password,
    String? username,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      developer.log('Attempting to register account with email: $email');

      // Create account via custom auth endpoint
      await _client.auth.createAccountDirectly(
        email: email,
        password: password,
      );
      developer.log('Account created successfully for email: $email');

      // Then log in with the same credentials
      developer.log('Attempting to login after registration for email: $email');
      var authSuccess = await _client.emailIdp.login(
        rememberMe: true,
        email: email,
        password: password,
      );
      await _client.emailIdp.client.authSessionManager.updateSignedInUser(
        authSuccess,
      );
      developer.log('Login after registration successful for email: $email');

      // Create user profile in the custom user table (with username if provided)
      final user = await _ensureUserProfile(username: username);
      final userModel = UserModel(
        email: email,
        authUserId: user.authUserId,
        nickname: user.username,
        bio: user.bio,
      );

      // Cache on register
      await _cacheUser(userModel);

      // Sync FCM Token
      final pushService = PushNotificationService();
      if (pushService.currentToken != null) {
        pushService.sendTokenToServer(pushService.currentToken!);
      }

      return userModel;
    } catch (e, stackTrace) {
      developer.log(
        'Registration/Login failed for email: $email',
        error: e,
        stackTrace: stackTrace,
        name: 'ServerpodService.registerAndLogin',
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!_isInitialized) await initialize();
    try {
      // Sign out using the session manager
      final sessionManager = _client.authSessionManager;
      // Clear the local session (this will sign out the user)
      await sessionManager.signOutDevice();
    } catch (e) {
      // Ignore errors during sign out
    } finally {
      // Always clear local cache on sign out
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
    }
  }

  Future<bool> isSignedIn() async {
    await initialize();
    try {
      return _client.authSessionManager.isAuthenticated;
    } catch (_) {
      return false;
    }
  }
  // ===== User Profile Methods =====

  /// Gets the current user's profile from the server
  Future<User?> getCurrentUserProfile() async {
    if (!_isInitialized) await initialize();
    try {
      return await _client.user.getCurrentUser();
    } catch (e) {
      developer.log('Error getting user profile: $e');
      return null;
    }
  }

  /// Updates the current user's profile on the server
  Future<User> updateUserProfile({String? username, String? bio}) async {
    if (!_isInitialized) await initialize();
    try {
      return await _client.user.updateProfile(username: username, bio: bio);
    } catch (e) {
      developer.log('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Ensures a user profile exists in the custom user table
  /// Creates one if it doesn't exist, or returns the existing one
  Future<User> _ensureUserProfile({String? username}) async {
    try {
      // Try to get the current user profile
      var userProfile = await getCurrentUserProfile();

      // If profile doesn't exist, create it using updateProfile (which creates if missing)
      if (userProfile == null) {
        developer.log('User profile does not exist, creating one...');
        userProfile = await updateUserProfile(username: username);
        developer.log('User profile created successfully');
      } else {
        developer.log('User profile already exists');
        // Update username if provided and different
        if (username != null && userProfile.username != username) {
          userProfile = await updateUserProfile(username: username);
        }
      }
      return userProfile;
    } catch (e) {
      developer.log('Error ensuring user profile exists: $e');
      throw Exception('Failed to ensure user profile: $e');
    }
  }

  // ===== Caching Methods =====

  Future<void> _cacheUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(user.toJson());
      await prefs.setString(_userCacheKey, jsonString);
      developer.log('User cached successfully');
    } catch (e) {
      developer.log('Error caching user: $e');
    }
  }

  Future<UserModel?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userCacheKey);
      if (jsonString != null) {
        developer.log('Found cached user');
        final jsonMap = jsonDecode(jsonString);
        return UserModel.fromJson(jsonMap);
      }
    } catch (e) {
      developer.log('Error reading user cache: $e');
    }
    return null;
  }
}
