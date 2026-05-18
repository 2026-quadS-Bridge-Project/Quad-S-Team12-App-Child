import 'package:flutter/widgets.dart';

import 'mission_controller.dart';

/// Inherited widget that exposes the [MissionController] to descendant
/// widgets of the mission flow. Listens to controller changes so
/// descendants resolved via [MissionScope.of] rebuild when the controller
/// notifies.
///
/// The scope is mounted once at the root of [MissionInfoPage]; all sub-views
/// (info / perform / photoPreview / submitted) read it via [of].
class MissionScope extends InheritedNotifier<MissionController> {
  const MissionScope({
    super.key,
    required MissionController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Returns the nearest [MissionController] above [context]. Throws in debug
  /// builds if the scope is missing — callers must be inside [MissionInfoPage].
  static MissionController of(BuildContext context) {
    final MissionScope? scope = context
        .dependOnInheritedWidgetOfExactType<MissionScope>();
    assert(scope != null, 'MissionScope.of() called outside MissionScope');
    return scope!.notifier!;
  }
}
