# Implementation Steps for User Model

## Step 1: Generate Serverpod Code

After creating the `user.spy.yaml` file, you need to generate the code:

```bash
cd project_thera_server
serverpod generate
```

This will:
- Generate the `User` class in `lib/src/generated/user/user.dart`
- Create database migrations
- Update the protocol and endpoints

## Step 2: Apply Database Migrations

After generating, apply the migrations to create the `user` table:

```bash
# Make sure your database is running
docker-compose up -d postgres

# Apply migrations
dart run bin/main.dart --apply-migrations
```

Or restart your server with migrations:
```bash
dart run bin/main.dart --apply-migrations
```

## Step 3: Update Flutter Client to Use Server-Side User Data

### Update `serverpod_service.dart`:

Add methods to get and update user profile:

```dart
/// Gets the current user's profile from the server
Future<Map<String, dynamic>?> getSignedInUser() async {
  if (!_isInitialized) await initialize();
  final signedIn = await isSignedIn();
  if (!signedIn) return null;

  try {
    final user = await _client.user.getCurrentUser();
    if (user == null) return null;
    
    return {
      'signedIn': true,
      'username': user.username,
      'bio': user.bio,
      'email': user.email, // You may need to get this from auth profile
    };
  } catch (e) {
    return {'signedIn': true};
  }
}

/// Updates the user's profile on the server
Future<void> updateUserProfile({
  String? username,
  String? bio,
}) async {
  if (!_isInitialized) await initialize();
  
  await _client.user.updateProfile(
    username: username,
    bio: bio,
  );
}
```

### Update `profile_screen.dart`:

Replace the local-only save with server sync:

```dart
void _handleSave() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);
  
  try {
    final service = ref.read(serverpodServiceProvider);
    await service.updateUserProfile(
      username: _nameController.text.trim(),
      bio: _bioController.text.trim(),
    );

    // Refresh user data from server
    final updatedUser = await service.getSignedInUser();
    if (updatedUser != null) {
      final userNotifier = ref.read(userProvider.notifier);
      userNotifier.setUser(
        app_user.User(
          email: updatedUser['email'] ?? '',
          nickname: updatedUser['username'],
          bio: updatedUser['bio'],
        ),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Update `login_screen.dart`:

After successful login, fetch user data from server:

```dart
// After login succeeds
final userNotifier = ref.read(userProvider.notifier);
final userData = await service.getSignedInUser();

if (userData != null) {
  userNotifier.setUser(
    app_user.User(
      email: userData['email'] ?? _emailController.text.trim(),
      nickname: userData['username'],
      bio: userData['bio'],
    ),
  );
} else {
  // Fallback if user profile doesn't exist yet
  userNotifier.setUser(
    app_user.User(
      email: _emailController.text.trim(),
      nickname: _isLoginMode ? null : _nicknameController.text.trim(),
      bio: null,
    ),
  );
}
```

## Step 4: Verify Everything Works

1. Restart your Serverpod server
2. Test login/registration
3. Test updating profile - changes should persist
4. Restart the app - profile data should load from server
