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
  Future<Result<MissionSubmissionResult>> submitMission({
    required String id,
    required List<String> photoPaths,
  });
}

/// Cached singleton — initialized lazily on first access via Dart's
/// top-level-final-is-lazy semantics. Tests that need a fresh repository
/// pass a Mock instance directly into the controller constructor, so this
/// global is only used by production call sites.
final MissionRepository _missionRepository = currentEnvironment.useMocks
    ? MockMissionRepository()
    : ApiMissionRepository(DioConfig.create());

/// Phase 2B factory: returns the cached repository instance. Selection
/// between [MockMissionRepository] and [ApiMissionRepository] is decided
/// once at first access based on [currentEnvironment.useMocks].
MissionRepository createMissionRepository() => _missionRepository;
