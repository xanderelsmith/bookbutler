import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

import '../models/fluffy_mascot.dart';

// Use AsyncNotifier for async loading
class RiveProvider extends AsyncNotifier<FluffyMascot> {
  @override
  Future<FluffyMascot> build() async {
    // Load the file asynchronously
    final file = await File.asset(
      'asset/fluffy.riv',
      riveFactory: Factory.rive,
    );

    return FluffyMascot(file!);
  }
}

final riveProvider = AsyncNotifierProvider<RiveProvider, FluffyMascot>(
  RiveProvider.new,
);
