import '../models/mission.dart';
import 'mission_approval_listener.dart';

/// Real-environment placeholder for the mission auto-approval channel.
///
/// Expected behavior once the backend ships:
/// - Open a WebSocket (or SSE / long-poll) connection scoped to the current
///   user session on first [subscribe] call. Reuse the connection across
///   subsequent subscriptions.
/// - On `subscribe(missionId: X, ...)`, register the [onApproval] callback
///   against `X` so the next inbound `mission.statusChanged` event for that
///   mission triggers exactly one emission.
/// - Auto-unregister the callback after the first emit (the contract is
///   one-shot per subscription). [MissionApprovalSubscription.cancel] must
///   also unregister it, so callbacks never fire after the controller is
///   disposed.
/// - [ConfirmationMethod] is forwarded purely as a hint; the backend is the
///   source of truth for which methods are auto-resolved.
/// - Surface transport errors to the caller via a logger or callback; do
///   not throw out of [subscribe] in steady state.
///
/// Today this is intentionally a no-op: the real backend submission call
/// succeeds or fails via [ApiMissionRepository], but there is not yet a push
/// channel for subsequent status changes. Keeping the listener silent avoids
/// a runtime crash in real API mode while leaving the mission in `reviewing`
/// until a future refresh / push implementation updates it.
class ApiMissionApprovalListener implements MissionApprovalListener {
  const ApiMissionApprovalListener();

  @override
  MissionApprovalSubscription subscribe({
    required String missionId,
    required ConfirmationMethod confirmationMethod,
    required void Function(MissionStatus status) onApproval,
  }) {
    return const _NoopSubscription();
  }
}

class _NoopSubscription implements MissionApprovalSubscription {
  const _NoopSubscription();

  @override
  void cancel() {}
}
