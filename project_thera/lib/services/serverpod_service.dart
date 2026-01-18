import 'dart:developer';

import 'package:project_thera/models/user.dart';
import 'package:project_thera_client/project_thera_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../main.dart';

class ServerpodService {
  static const String _serverUrlKey = 'serverpod_server_url';
  static final String _defaultServerUrl = 'http://${newVariable}:8080/';

  late Client _client;
  bool _isInitialized = false;

  Client get client => _client;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get server URL from preferences or use default
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString(_serverUrlKey) ?? _defaultServerUrl;

      // Initialize the client with authentication session manager
      // Disable streaming connections to avoid random port connection errors
      _client =
          Client(
              serverUrl,
              connectionTimeout: const Duration(seconds: 10),
              streamingConnectionTimeout: const Duration(seconds: 5),
              disconnectStreamsOnLostInternetConnection: true,
            )
            ..connectivityMonitor = FlutterConnectivityMonitor()
            ..authSessionManager = FlutterAuthSessionManager();

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Serverpod client: $e');
    }
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);
    _isInitialized = false;
    await initialize();
  }

  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? _defaultServerUrl;
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
        return userModel;
      }
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
        email: email,
        password: password,
      );
      await _client.emailIdp.client.authSessionManager.updateSignedInUser(
        authSuccess,
      );
      developer.log('Login after registration successful for email: $email');

      // Create user profile in the custom user table (with username if provided)
      final user = await _ensureUserProfile(username: username);
      return UserModel(
        email: email,
        authUserId: user.authUserId,
        nickname: user.username,
        bio: user.bio,
      );
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

  Future<bool> isSignedIn() async {
    if (!_isInitialized) await initialize();
    try {
      // Access the manager from the client
      final sessionManager = _client.auth;

      // Check the authentication state directly
      return sessionManager.client.authSessionManager.isAuthenticated;
    } catch (e) {
      return false;
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
    }
  }

  // Get user info from the server
  Future<Map<String, dynamic>?> getSignedInUser() async {
    if (!_isInitialized) await initialize();
    final signedIn = await isSignedIn();
    if (!signedIn) return null;

    try {
      // For now, return basic signed-in info
      // TODO: Create a custom endpoint to get user details if needed
      // The user info can be retrieved from the server using a custom endpoint
      return {
        'signedIn': true,
        // Additional user info would come from a custom server endpoint
      };
    } catch (e) {
      // If we can't get user info, but we're signed in, return basic info
      return {'signedIn': true};
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
}
