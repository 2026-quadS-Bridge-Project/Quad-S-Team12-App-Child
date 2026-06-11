import '../../../../core/models/result.dart';
import '../models/usage_report.dart';
import 'mock_usage_report_repository.dart';

/// Repository contract for the weekly usage Report feature.
///
/// Concrete implementations:
///   * [MockUsageReportRepository] — returns canned fixtures from
///     `UsageReportMock`.
///
/// Future expansion (monthly / custom date range) is out of scope for the
/// current child-side weekly report screen.
abstract interface class UsageReportRepository {
  /// Load the usage report for the current week.
  Future<Result<UsageReport>> fetchCurrentWeekReport();
}

/// The report screen intentionally stays on the existing mock UI/data until a
/// read-only backend report endpoint exists. Do not derive reports from daily
/// schedule APIs because those can create/deduct schedule state.
final UsageReportRepository _usageReportRepository = MockUsageReportRepository();

/// Factory that returns the cached repo for the current environment.
UsageReportRepository createUsageReportRepository() => _usageReportRepository;
