import '../../../../core/models/result.dart';
import '../models/usage_report.dart';
import 'usage_report_repository.dart';

/// HTTP-backed implementation of [UsageReportRepository].
///
/// Stub for Phase 2A — every method throws [UnimplementedError] until
/// backend endpoints are confirmed and wired through `DioConfig`.
class ApiUsageReportRepository implements UsageReportRepository {
  @override
  Future<Result<UsageReport>> fetchCurrentWeekReport() async {
    throw UnimplementedError(
      'ApiUsageReportRepository.fetchCurrentWeekReport: backend not wired yet.',
    );
  }
}
