import '../../../../core/config/dio_config.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/models/result.dart';
import '../models/time_schedule.dart';
import 'api_time_setup_repository.dart';
import 'mock_time_setup_repository.dart';

/// Repository contract for the Time Setup feature.
///
/// Concrete implementations:
///   * [MockTimeSetupRepository] — returns canned fixtures from
///     `TimeScheduleMock` (used while [EnvironmentConfig.useMocks] is true).
///   * [ApiTimeSetupRepository] — calls the real backend (stubbed for now).
abstract interface class TimeSetupRepository {
  /// Load the previous week's schedule snapshot — used by v2 (next-week edit)
  /// to seed the locked 1주차 row and the editable weeks 2-4 draft.
  Future<Result<TimeSchedule>> fetchPreviousWeekSchedule();

  /// Load the child's currently saved upcoming schedule, if any. Returns
  /// `Success(null)` when the child has not yet completed the setup flow.
  Future<Result<TimeSchedule?>> fetchCurrentSchedule();

  /// Persist the child's finished plan after the review step.
  Future<Result<void>> saveSchedule(TimeSchedule schedule);
}

/// Factory that picks the right repo for the current environment.
TimeSetupRepository createTimeSetupRepository() {
  if (currentEnvironment.useMocks) {
    return MockTimeSetupRepository();
  }
  return ApiTimeSetupRepository(dio: DioConfig.create());
}
