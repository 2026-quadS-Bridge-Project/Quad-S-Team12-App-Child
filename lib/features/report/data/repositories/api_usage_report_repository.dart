import 'package:dio/dio.dart';

import '../../../../core/config/dio_config.dart';
import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/usage_report.dart';
import 'usage_report_repository.dart';

/// HTTP-backed [UsageReportRepository] wired to the endpoints defined under
/// "Usage Report" in `docs/api-contract.md`:
/// - `GET /reports/weekly` → current-week [UsageReport]. The `weekOf` query
///   parameter is optional per the contract; omitting it asks the server
///   for the current week, which is exactly what
///   [fetchCurrentWeekReport] needs.
///
/// DioException → [Result.failure] via [failureFromDioException]; the helper
/// surfaces server-supplied Korean copy (e.g. `REPORT_NOT_READY` →
/// '아직 이번 주 리포트가 준비되지 않았어요.') when present and falls back to
/// the generic status-code messages otherwise.
class ApiUsageReportRepository implements UsageReportRepository {
  ApiUsageReportRepository([Dio? dio]) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<UsageReport>> fetchCurrentWeekReport() async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>('/reports/weekly');
      return Result<UsageReport>.success(
        UsageReport.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return failureFromDioException<UsageReport>(e);
    }
  }
}
