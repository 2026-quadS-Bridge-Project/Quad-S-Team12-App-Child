import '../../../../core/models/result.dart';
import '../mock/time_confirm_mock.dart';
import '../models/time_confirm_data.dart';
import 'time_confirm_repository.dart';

/// Mock implementation backed by [TimeConfirmMock] fixtures.
///
/// Used while [currentEnvironment.useMocks] is true. All methods complete
/// synchronously-via-Future with Success outcomes; no failure paths are
/// modelled until the real backend lands.
class MockTimeConfirmRepository implements TimeConfirmRepository {
  @override
  Future<Result<TimeConfirmData>> fetchCurrentSchedule() async {
    return Result<TimeConfirmData>.success(TimeConfirmMock.filled);
  }

  @override
  Future<Result<void>> requestModification() async {
    // No-op for now — backend wiring deferred. Returning success keeps the
    // controller flow exercising the real code path.
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> acknowledgeSchedule() async {
    return Result<void>.success(null);
  }
}
