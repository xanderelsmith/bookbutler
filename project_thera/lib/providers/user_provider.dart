import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

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
}

final userProvider = NotifierProvider<UserNotifier, UserModel?>(
  UserNotifier.new,
);
