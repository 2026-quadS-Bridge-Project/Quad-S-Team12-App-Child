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
  Future<Result<Mission>> submitMission({
    required String id,
    required List<String> photoPaths,
  }) async {
    try {
      // Mock backend: echo the mission with the supplied photoPaths attached.
      // The controller is responsible for status transitions (childSelf vs.
      // aiAuto vs. parentApproval) because those drive UI sub-views.
      final Mission base = MissionMock.byId(id);
      return Result<Mission>.success(base.copyWith(photoUrls: photoPaths));
    } catch (e, stack) {
      return Result<Mission>.failure(
        'Mock submit failed for mission $id',
        cause: e,
        stack: stack,
      );
    }
  }
}
