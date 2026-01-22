import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../providers/serverpod_provider.dart';

class UserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    return null;
  }

  void setUser(UserModel user) {
    try {
      state = user;
    } catch (e) {
      // Ignore errors if provider is disposed
    }
  }

  void clearUser() {
    try {
      state = null;
    } catch (e) {
      // Ignore errors if provider is disposed
    }
  }

  Future<void> restoreSession(Ref ref) async {
    try {
      final service = ref.read(serverpodServiceProvider);
      final user = await service.restoreSession();
      if (user != null) {
        setUser(user);
      }
    } catch (e) {
      // Ignore errors
    }
  }
}

final userProvider = NotifierProvider<UserNotifier, UserModel?>(
  UserNotifier.new,
);

final userBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(userProvider.notifier).restoreSession(ref);
});
