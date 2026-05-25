import '../../../../core/models/result.dart';
import '../mock/usage_report_mock.dart';
import '../models/usage_report.dart';
import 'usage_report_repository.dart';

/// Mock implementation backed by [UsageReportMock] fixtures.
///
/// Used while [currentEnvironment.useMocks] is true. All methods complete
/// synchronously-via-Future with Success outcomes; no failure paths are
/// modelled until the real backend lands.
class MockUsageReportRepository implements UsageReportRepository {
  @override
  Future<Result<UsageReport>> fetchCurrentWeekReport() async {
    return Result<UsageReport>.success(UsageReportMock.currentWeek);
  }
}
