import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_thera_client/project_thera_client.dart';
import '../services/serverpod_service.dart';

final serverpodServiceProvider = Provider<ServerpodService>((ref) {
  return ServerpodService();
});

final serverpodClientProvider = FutureProvider<ServerpodService>((ref) async {
  final service = ref.watch(serverpodServiceProvider);
  await service.initialize();
  return service;
});

final authUserProvider = FutureProvider<User?>((ref) async {
  final service = ref.watch(serverpodServiceProvider);
  await service.initialize();
  return await service.getCurrentUserProfile();
});

final isSignedInProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(serverpodServiceProvider);
  await service.initialize();
  return await service.isSignedIn();
});
