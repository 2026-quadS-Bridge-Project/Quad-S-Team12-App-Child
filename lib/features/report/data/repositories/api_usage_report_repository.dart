import 'package:dio/dio.dart';

import '../../../../core/models/result.dart';
import '../models/usage_report.dart';
import 'usage_report_repository.dart';

/// HTTP-backed [UsageReportRepository].
///
/// The backend PR does not expose a read-only weekly report endpoint yet.
/// Do not derive this from `GET /api/v1/schedules/daily`: that endpoint creates
/// daily allocations and deducts the monthly time pool when the row does not
/// exist, so using it for a 7-day report would mutate schedule state.
class ApiUsageReportRepository implements UsageReportRepository {
  ApiUsageReportRepository([Dio? dio]);

  @override
  Future<Result<UsageReport>> fetchCurrentWeekReport() async {
    return Result<UsageReport>.failure('주간 리포트 API가 아직 준비되지 않았어요.');
  }
}
