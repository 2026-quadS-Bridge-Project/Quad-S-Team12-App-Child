import 'dart:async';

import '../models/mission.dart';
import 'mission_approval_listener.dart';

/// Mock implementation that simulates AI auto-approval with a 2-second
/// `Timer`, preserving the original inline behavior that used to live in
/// `MissionController.submit()`.
///
/// Behavior matrix:
/// - [ConfirmationMethod.aiAuto]         → schedule a 2s `Timer` that emits
///   [MissionStatus.completed], cancellable via the returned subscription.
/// - [ConfirmationMethod.childSelf]      → no-op subscription. The controller
///   already completes these immediately on submit, so the listener stays
///   silent.
/// - [ConfirmationMethod.parentApproval] → no-op subscription. Mock parent
///   approval flow has no automated trigger; the mission stays in
///   `reviewing` until a real parent action arrives.
class MockMissionApprovalListener implements MissionApprovalListener {
  const MockMissionApprovalListener();

  @override
  MissionApprovalSubscription subscribe({
    required String missionId,
    required ConfirmationMethod confirmationMethod,
    required void Function(MissionStatus status) onApproval,
  }) {
    if (confirmationMethod != ConfirmationMethod.aiAuto) {
      return const _NoopSubscription();
    }
    final Timer timer = Timer(const Duration(seconds: 2), () {
      onApproval(MissionStatus.completed);
    });
    return _TimerSubscription(timer);
  }
}

class _TimerSubscription implements MissionApprovalSubscription {
  _TimerSubscription(this._timer);

  final Timer _timer;

  @override
  void cancel() {
    _timer.cancel();
  }
}

class _NoopSubscription implements MissionApprovalSubscription {
  const _NoopSubscription();

  @override
  void cancel() {}
}
