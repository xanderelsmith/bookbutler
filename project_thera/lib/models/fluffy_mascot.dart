import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart';

class FluffyMascot {
  final File file;
  late final Artboard artboard;
  late final StateMachine stateMachine;
  late final RiveWidgetController _controller;
  late final ViewModelInstance _viewModelInstance;

  FluffyMascot(this.file) {
    // Initialize artboard
    artboard = file.defaultArtboard()!;

    // Initialize state machine
    stateMachine = artboard.defaultStateMachine()!;

    // Create controller
    _controller = RiveWidgetController(
      file,
      stateMachineSelector: StateMachineSelector.byName('State Machine 1'),
    );

    // Bind data (auto-bind to default view model)
    // If the Rive file has multiple view models, you might need DataBind.byName('ViewModel1')
    try {
      _viewModelInstance = _controller.dataBind(DataBind.auto());
    } catch (e) {
      log('Error binding to ViewModel: $e');
      // Fallback or rethrow depending on strictness
    }
  }

  /// Returns the Rive widget ready for display
  Widget get view => RiveWidget(controller: _controller);

  /// Get the controller
  RiveWidgetController get controller => _controller;

  /// Fire triggers via data binding
  void dance() {
    log('dance');
    final trigger = _viewModelInstance.trigger('dance');
    if (trigger != null) {
      trigger.trigger();
    } else {
      _viewModelInstance.boolean('dance')?.value = true;
    }
  }

  void wave() {
    log('wave');
    final trigger = _viewModelInstance.trigger('wave');
    if (trigger != null) {
      trigger.trigger();
    } else {
      _viewModelInstance.boolean('wave')?.value = true;
    }
  }

  void idle() {
    log('idle');
    // Try as trigger
    final trigger = _viewModelInstance.trigger('idle');
    if (trigger != null) {
      trigger.trigger();
    } else {
      // Fall back to boolean
      _viewModelInstance.boolean('idle')?.value = true;
    }
  }

  /// Dispose resources
  void dispose() {
    _controller.dispose();
  }
}
