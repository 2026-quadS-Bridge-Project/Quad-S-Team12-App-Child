import '../../../../core/config/environment.dart';
import '../models/mission.dart';
import 'api_mission_approval_listener.dart';
import 'mock_mission_approval_listener.dart';

/// Contract for the mission auto-approval channel.
///
/// Extracted from [MissionController] so the inline mock `Timer` that fakes
/// AI auto-approval can be swapped for a real WebSocket / SSE / polling
/// implementation once the backend ships, without touching the controller
/// again.
///
/// Implementations should be one-shot per subscription: a single
/// [MissionStatus] emit, then auto-cancel. The controller is responsible
/// for cancelling the returned [MissionApprovalSubscription] on dispose to
/// avoid late `notifyListeners()` calls on a torn-down `ChangeNotifier`.
abstract interface class MissionApprovalListener {
  /// Subscribe for the next approval update for [missionId].
  ///
  /// The [onApproval] callback fires AT MOST ONCE with the new status; the
  /// subscription is auto-cancelled after emit. Returns a handle the
  /// controller can cancel on dispose.
  MissionApprovalSubscription subscribe({
    required String missionId,
    required ConfirmationMethod confirmationMethod,
    required void Function(MissionStatus status) onApproval,
  });
}

/// Handle returned by [MissionApprovalListener.subscribe]. Cancelling is
/// idempotent and safe to call after the callback has already fired.
abstract interface class MissionApprovalSubscription {
  void cancel();
}

/// Phase 2B factory: selects mock vs. real implementation based on
/// [currentEnvironment.useMocks].
///
/// Returns [MockMissionApprovalListener] while mocks are enabled and
/// [ApiMissionApprovalListener] in real API mode.
MissionApprovalListener createMissionApprovalListener() {
  if (currentEnvironment.useMocks) return const MockMissionApprovalListener();
  return const ApiMissionApprovalListener();
}
