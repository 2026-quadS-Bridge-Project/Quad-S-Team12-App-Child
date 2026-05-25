import '../../../../core/config/dio_config.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/models/result.dart';
import '../models/mission.dart';
import 'api_mission_repository.dart';
import 'mock_mission_repository.dart';

/// Contract for the mission feature's data layer.
///
/// All operations return a [Result] so callers can branch on success vs.
/// failure without try/catch — see [MissionController] for the standard
/// consumption pattern.
abstract interface class MissionRepository {
  Future<Result<List<Mission>>> listMissions();
  Future<Result<Mission>> fetchMission(String id);
  Future<Result<Mission>> submitMission({
    required String id,
    required List<String> photoPaths,
  });
}

/// Phase 2B factory: selects mock vs. real implementation based on
/// [currentEnvironment.useMocks].
///
/// Returns [MockMissionRepository] today; will return [ApiMissionRepository]
/// once `useMocks` is flipped off in [EnvironmentConfig]. The Dio instance
/// is constructed lazily inside the api branch so mock-only builds never
/// pay the configuration cost.
MissionRepository createMissionRepository() {
  if (currentEnvironment.useMocks) {
    return MockMissionRepository();
  }
  return ApiMissionRepository(DioConfig.create());
}
