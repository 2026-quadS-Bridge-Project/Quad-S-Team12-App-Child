import 'package:dio/dio.dart';

import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/time_schedule.dart';
import 'time_setup_repository.dart';

/// HTTP-backed implementation of [TimeSetupRepository].
///
/// Wires the three Time Setup endpoints documented in
/// `docs/api-contract.md`:
///   * `GET  /time-setup/previous-week` → seed for the v2 (next-month) flow.
///   * `GET  /time-setup/current`       → currently-saved upcoming schedule
///                                        (wrapped as `{ "schedule": ... }`).
///   * `POST /time-setup`               → persist the finished plan.
///
/// All [DioException]s funnel through [failureFromDioException] for
/// consistent Korean error messages.
class ApiTimeSetupRepository implements TimeSetupRepository {
  ApiTimeSetupRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<Result<TimeSchedule>> fetchPreviousWeekSchedule() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/time-setup/previous-week',
      );
      final dynamic data = response.data;
      if (data is! Map) {
        throw const FormatException(
          'GET /time-setup/previous-week response was not a JSON object.',
        );
      }
      final TimeSchedule schedule = TimeSchedule.fromJson(
        Map<String, dynamic>.from(data),
      );
      return Result<TimeSchedule>.success(schedule);
    } on DioException catch (e) {
      return failureFromDioException<TimeSchedule>(e);
    }
  }

  @override
  Future<Result<TimeSchedule?>> fetchCurrentSchedule() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/time-setup/current',
      );
      final dynamic data = response.data;
      if (data is! Map) {
        throw const FormatException(
          'GET /time-setup/current response was not a JSON object.',
        );
      }
      final dynamic inner = data['schedule'];
      if (inner == null) {
        return Result<TimeSchedule?>.success(null);
      }
      if (inner is! Map) {
        throw const FormatException(
          'GET /time-setup/current `schedule` field was not a JSON object.',
        );
      }
      final TimeSchedule schedule = TimeSchedule.fromJson(
        Map<String, dynamic>.from(inner),
      );
      return Result<TimeSchedule?>.success(schedule);
    } on DioException catch (e) {
      return failureFromDioException<TimeSchedule?>(e);
    }
  }

  @override
  Future<Result<void>> saveSchedule(TimeSchedule schedule) async {
    // The backend has no single /time-setup endpoint; the plan is split across
    // three schedule endpoints (all identified by the child JWT). The backend
    // enforces a strict order — a week's budget must exist before its day
    // templates, and each week's template sum is validated against that budget
    // (and the budget total against the parent's monthly baseTime). So we call
    // them in the mandated order and let the first failure surface verbatim:
    //   1. POST /weekly-budgets   (weeklyTotals)   — must precede templates
    //   2. PUT  /templates        (dayAllocations) — per week × weekday
    //   3. routines               (allowedHours)   — cleared then re-created
    //
    // Errors funnel through failureFromDioException, which prefers the
    // backend's Korean `message` (e.g. "N주차 예산을 먼저 분배해주세요.",
    // "...총량을 초과할 수 없습니다.", "정책이 없습니다."). The last means the
    // parent has not set this month's baseTime yet — a parent-side prerequisite
    // this app cannot create, only report.
    final String yearMonth = _currentYearMonth();
    try {
      await _dio.post<dynamic>(
        '/api/v1/schedules/weekly-budgets',
        queryParameters: <String, dynamic>{'yearMonth': yearMonth},
        data: <Map<String, dynamic>>[
          for (final WeeklyTotal w in schedule.weeklyTotals)
            <String, dynamic>{
              'weekNumber': w.weekIndex + 1, // app is 0-based, backend 1-based
              'allocatedMinutes': w.totalMinutes,
            },
        ],
      );

      // dayAllocations carry no week dimension, so the per-weekday base time is
      // replicated across every week present in the budget. Each week's sum is
      // validated against that week's budget server-side.
      for (final WeeklyTotal w in schedule.weeklyTotals) {
        final int weekNumber = w.weekIndex + 1;
        for (final DayAllocation a in schedule.dayAllocations) {
          for (final int weekday in a.weekdayIndices) {
            await _dio.put<dynamic>(
              '/api/v1/schedules/templates',
              data: <String, dynamic>{
                'yearMonth': yearMonth,
                'weekNumber': weekNumber,
                'dayOfWeek': _dayOfWeekName(weekday),
                'baseMinutes': a.totalMinutes,
              },
            );
          }
        }
      }

      await _replaceRoutines(schedule.allowedHours);

      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  /// Clears the child's existing fixed routines, then re-creates one block per
  /// contiguous run of allowed hours per weekday. `createRoutine` always
  /// inserts (no upsert), so a delete-first pass keeps re-saves idempotent.
  Future<void> _replaceRoutines(Set<HourCell> allowedHours) async {
    final Response<dynamic> listResp =
        await _dio.get<dynamic>('/api/v1/schedules/routines');
    final dynamic existing = listResp.data;
    if (existing is List) {
      for (final dynamic routine in existing) {
        final Object? id = routine is Map ? routine['id'] : null;
        if (id != null) {
          await _dio.delete<dynamic>('/api/v1/schedules/routines/$id');
        }
      }
    }

    final Map<int, List<int>> hoursByWeekday = <int, List<int>>{};
    for (final HourCell cell in allowedHours) {
      (hoursByWeekday[cell.weekday] ??= <int>[]).add(cell.hour);
    }
    for (final MapEntry<int, List<int>> entry in hoursByWeekday.entries) {
      final List<int> sorted = entry.value..sort();
      for (final (int, int) range in _mergeContiguous(sorted)) {
        await _dio.post<dynamic>(
          '/api/v1/schedules/routines',
          data: <String, dynamic>{
            'dayOfWeek': _dayOfWeekName(entry.key),
            'startTime': _hhmmss(range.$1),
            'endTime': _hhmmss(range.$2),
          },
        );
      }
    }
  }

  /// Merges a sorted list of hours into `(startHour, endHourExclusive)` ranges.
  /// e.g. `[9,10,11,14]` → `[(9,12),(14,15)]`.
  List<(int, int)> _mergeContiguous(List<int> sortedHours) {
    final List<(int, int)> ranges = <(int, int)>[];
    if (sortedHours.isEmpty) return ranges;
    int start = sortedHours.first;
    int prev = start;
    for (int i = 1; i < sortedHours.length; i++) {
      final int h = sortedHours[i];
      if (h == prev + 1) {
        prev = h;
        continue;
      }
      ranges.add((start, prev + 1));
      start = h;
      prev = h;
    }
    ranges.add((start, prev + 1));
    return ranges;
  }

  /// app weekday index (0 = 월 … 6 = 일) → `java.time.DayOfWeek` name.
  String _dayOfWeekName(int weekday) {
    const List<String> names = <String>[
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return names[weekday % 7];
  }

  /// Hour → `LocalTime`-parseable `"HH:mm:ss"`. Hour 24 (an exclusive end at
  /// midnight) is clamped to the last valid second of the day.
  String _hhmmss(int hour) {
    if (hour >= 24) return '23:59:59';
    return '${hour.toString().padLeft(2, '0')}:00:00';
  }

  /// Current `"yyyy-MM"`, the month the budgets/templates are filed under.
  String _currentYearMonth() {
    final DateTime now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}';
  }
}
