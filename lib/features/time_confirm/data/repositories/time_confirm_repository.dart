import '../../../../core/config/environment.dart';
import '../../../../core/models/result.dart';
import '../models/time_confirm_data.dart';
import 'api_time_confirm_repository.dart';
import 'mock_time_confirm_repository.dart';

/// Repository contract for the Time Confirm feature.
///
/// Concrete implementations:
///   * [MockTimeConfirmRepository] — returns canned fixtures from
///     `TimeConfirmMock` (used while [EnvironmentConfig.useMocks] is true).
///   * [ApiTimeConfirmRepository] — calls the real backend (stubbed for now).
abstract interface class TimeConfirmRepository {
  /// Load the currently active schedule pushed by the parent.
  Future<Result<TimeConfirmData>> fetchCurrentSchedule();

  /// Send a "수정 요청" to the parent. No payload — the request itself is
  /// the signal.
  Future<Result<void>> requestModification();

  /// Mark the schedule as acknowledged by the child (the 확인 CTA).
  Future<Result<void>> acknowledgeSchedule();
}

/// Factory that picks the right repo for the current environment.
TimeConfirmRepository createTimeConfirmRepository() {
  if (currentEnvironment.useMocks) {
    return MockTimeConfirmRepository();
  }
  return ApiTimeConfirmRepository();
}
