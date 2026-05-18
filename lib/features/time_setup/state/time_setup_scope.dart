import 'package:flutter/widgets.dart';

import 'time_setup_controller.dart';

/// Inherited widget that exposes the [TimeSetupController] to descendant
/// pages of the wizard. Listens to controller changes so descendants that
/// call [TimeSetupScope.of] will rebuild when the controller notifies.
class TimeSetupScope extends InheritedNotifier<TimeSetupController> {
  const TimeSetupScope({
    super.key,
    required TimeSetupController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Returns the nearest [TimeSetupController] above [context]. Throws if
  /// the scope is missing — callers must be inside [TimeSetupRootPage].
  static TimeSetupController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TimeSetupScope>();
    assert(scope != null, 'TimeSetupScope.of() called outside TimeSetupScope');
    return scope!.notifier!;
  }
}
