import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/home_widget_service.dart';

// Provider for HomeWidgetService (singleton)
final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  return HomeWidgetService();
});

// Provider for home widget enabled state
final homeWidgetEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(homeWidgetServiceProvider);
  return await service.isEnabled();
});
