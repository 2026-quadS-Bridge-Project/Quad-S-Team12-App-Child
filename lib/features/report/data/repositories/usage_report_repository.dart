import '../../../../core/config/environment.dart';
import '../../../../core/models/result.dart';
import '../models/usage_report.dart';
import 'api_usage_report_repository.dart';
import 'mock_usage_report_repository.dart';

/// Repository contract for the weekly usage Report feature.
///
/// Concrete implementations:
///   * [MockUsageReportRepository] — returns canned fixtures from
///     `UsageReportMock` (used while [EnvironmentConfig.useMocks] is true).
///   * [ApiUsageReportRepository] — calls the real backend (stubbed for now).
///
/// Future expansion (monthly / custom date range) is out of scope for the
/// current child-side weekly report screen.
abstract interface class UsageReportRepository {
  /// Load the usage report for the current week.
  Future<Result<UsageReport>> fetchCurrentWeekReport();
}

/// Cached singleton — lazy-initialized at first access.
final UsageReportRepository _usageReportRepository =
    currentEnvironment.useMocks
        ? MockUsageReportRepository()
        : ApiUsageReportRepository();

/// Factory that returns the cached repo for the current environment.
UsageReportRepository createUsageReportRepository() => _usageReportRepository;
