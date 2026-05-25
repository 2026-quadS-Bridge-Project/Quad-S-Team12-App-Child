import '../../../../core/models/result.dart';
import '../mock/time_schedule_mock.dart';
import '../models/time_schedule.dart';
import 'time_setup_repository.dart';

/// Mock implementation backed by [TimeScheduleMock] fixtures.
///
/// Used while [currentEnvironment.useMocks] is true. All methods complete
/// synchronously-via-Future with Success outcomes; no failure paths are
/// modelled until the real backend lands.
class MockTimeSetupRepository implements TimeSetupRepository {
  @override
  Future<Result<TimeSchedule>> fetchPreviousWeekSchedule() async {
    return Result<TimeSchedule>.success(TimeScheduleMock.sampleV2PreviousWeek);
  }

  @override
  Future<Result<TimeSchedule?>> fetchCurrentSchedule() async {
    // No saved schedule yet — child must complete the setup flow.
    return Result<TimeSchedule?>.success(null);
  }

  @override
  Future<Result<void>> saveSchedule(TimeSchedule schedule) async {
    // No-op for now — backend wiring deferred. Returning success keeps the
    // controller flow exercising the real code path.
    return Result<void>.success(null);
  }
}
