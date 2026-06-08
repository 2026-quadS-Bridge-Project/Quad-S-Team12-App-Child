import 'package:dio/dio.dart';

import '../../../../core/config/dio_config.dart';
import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/usage_report.dart';
import 'usage_report_repository.dart';

/// HTTP-backed [UsageReportRepository] wired to the endpoints defined under
/// AWS Swagger. The deployed API does not expose `/reports/weekly`; we derive
/// the weekly report from seven `GET /api/v1/schedules/daily` calls instead.
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
      final DateTime monday = _mondayOf(DateTime.now());
      final List<DailyUsageRow> rows = <DailyUsageRow>[];
      int plannedTotal = 0;
      for (int offset = 0; offset < 7; offset++) {
        final DateTime date = monday.add(Duration(days: offset));
        final Response<dynamic> response = await _dio.get<dynamic>(
          '/api/v1/schedules/daily',
          queryParameters: <String, dynamic>{'date': _yyyyMmDd(date)},
        );
        final dynamic data = response.data;
        if (data is! Map) {
          throw const FormatException(
            'GET /api/v1/schedules/daily response was not a JSON object.',
          );
        }
        final int planned = _intValue(data['totalAvailableMinutes']);
        plannedTotal += planned;
        rows.add(
          DailyUsageRow(
            dayKor: _weekdayKor(offset),
            plannedMinutes: planned,
            actualMinutes: 0,
          ),
        );
      }

      return Result<UsageReport>.success(
        UsageReport(
          weekLabel: '${monday.month}월 ${_weekOfMonth(monday)}주차 사용리포트',
          plan: WeeklyTotalPlan(
            totalHours: plannedTotal ~/ 60,
            daySets: const <DaySetPlan>[],
          ),
          dailyRows: rows,
          compliance: const ComplianceBreakdown(
            onPlanPct: 0,
            overPct: 0,
            underPct: 0,
          ),
          suggestions: const <AiSuggestion>[],
        ),
      );
    } on DioException catch (e) {
      return failureFromDioException<UsageReport>(e);
    }
  }

  DateTime _mondayOf(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  int _weekOfMonth(DateTime date) => ((date.day - 1) ~/ 7) + 1;

  String _yyyyMmDd(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _weekdayKor(int weekday) {
    const List<String> labels = <String>['월', '화', '수', '목', '금', '토', '일'];
    return labels[weekday.clamp(0, 6)];
  }

  int _intValue(Object? value) {
    if (value is num) return value.toInt();
    return 0;
  }
}
