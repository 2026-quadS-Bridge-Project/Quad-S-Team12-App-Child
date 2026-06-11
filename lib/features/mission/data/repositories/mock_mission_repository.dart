import '../../../../core/models/result.dart';
import '../mock/mission_mock.dart';
import '../models/mission.dart';
import 'mission_repository.dart';

/// Mock [MissionRepository] backed by [MissionMock].
///
/// Always resolves synchronously-async (Dart auto-wraps in a Future via the
/// `async` modifier). Submission is a no-op pass-through — the controller
/// owns the local UI-only status transitions because mock-mode has no
/// backend round-trip.
class MockMissionRepository implements MissionRepository {
  @override
  Future<Result<List<Mission>>> listMissions() async {
    return Result<List<Mission>>.success(MissionMock.all);
  }

  @override
  Future<Result<Mission>> fetchMission(String id) async {
    try {
      final Mission mission = MissionMock.byId(id);
      return Result<Mission>.success(mission);
    } catch (e, stack) {
      return Result<Mission>.failure(
        'Mission not found: $id',
        cause: e,
        stack: stack,
      );
    }
  }

  @override
  Future<Result<MissionSubmissionResult>> submitMission({
    required String id,
    required List<String> photoPaths,
  }) async {
    try {
      // Mock backend: validate the id resolves and report success. The
      // controller owns status transitions (childSelf vs. aiAuto vs.
      // parentApproval) because those drive UI sub-views.
      MissionMock.byId(id);
      return Result<MissionSubmissionResult>.success(
        const MissionSubmissionResult(),
      );
    } catch (e, stack) {
      return Result<MissionSubmissionResult>.failure(
        'Mock submit failed for mission $id',
        cause: e,
        stack: stack,
      );
    }
  }
}
