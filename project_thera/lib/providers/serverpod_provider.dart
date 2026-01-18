import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/serverpod_service.dart';

final serverpodServiceProvider = Provider<ServerpodService>((ref) {
  return ServerpodService();
});

final serverpodClientProvider = FutureProvider<ServerpodService>((ref) async {
  final service = ref.watch(serverpodServiceProvider);
  await service.initialize();
  return service;
});

final authUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.watch(serverpodServiceProvider);
  await service.initialize();
  return await service.getSignedInUser();
});

final isSignedInProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(serverpodServiceProvider);
  await service.initialize();
  return await service.isSignedIn();
});
