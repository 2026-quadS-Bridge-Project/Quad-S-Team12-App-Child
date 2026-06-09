import 'package:dio/dio.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/models/result.dart';
import '../../../../core/network/api_error.dart';
import '../models/time_schedule.dart';
import 'time_setup_repository.dart';

/// HTTP-backed implementation of [TimeSetupRepository].
///
/// Wires the AWS Swagger schedule endpoints:
///   * `GET  /api/v1/schedules/daily`
///   * `GET  /api/v1/schedules/routines`
///   * `POST /api/v1/schedules/weekly-budgets`
///   * `PUT  /api/v1/schedules/templates`
///   * `POST/DELETE /api/v1/schedules/routines`
///
/// All [DioException]s funnel through [failureFromDioException] for
/// consistent Korean error messages.
class ApiTimeSetupRepository implements TimeSetupRepository {
  ApiTimeSetupRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<Result<TimeSchedule>> fetchPreviousWeekSchedule() async {
    try {
      final TimeSchedule schedule = await _fetchDailySchedule(
        DateTime.now().subtract(const Duration(days: 7)),
      );
      return Result<TimeSchedule>.success(schedule);
    } on DioException catch (e) {
      return failureFromDioException<TimeSchedule>(e);
    }
  }

  @override
  Future<Result<TimeSchedule?>> fetchCurrentSchedule() async {
    final TimeSchedule? policySchedule;
    try {
      policySchedule = await _fetchPolicySchedule();
    } on DioException catch (e) {
      if (_isMissingPolicyError(e)) {
        return Result<TimeSchedule?>.failure(
          '부모님이 아직 이번 달 시간을 설정하지 않았어요.',
          cause: e,
        );
      }
      return failureFromDioException<TimeSchedule?>(e);
    }

    if (policySchedule != null) {
      return Result<TimeSchedule?>.success(policySchedule);
    }

    try {
      final TimeSchedule schedule = await _fetchDailySchedule(DateTime.now());
      return Result<TimeSchedule?>.success(schedule);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Result<TimeSchedule?>.success(null);
      }
      return failureFromDioException<TimeSchedule?>(e);
    }
  }

  Future<TimeSchedule> _fetchDailySchedule(DateTime date) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/schedules/daily',
      queryParameters: <String, dynamic>{'date': _yyyyMmDd(date)},
    );
    final Map<String, dynamic>? data = _responseObject(response.data);
    if (data == null) {
      throw const FormatException(
        'GET /api/v1/schedules/daily response was not a JSON object.',
      );
    }
    return dailyScheduleToTimeSchedule(data, routines: await _fetchRoutines());
  }

  Future<TimeSchedule?> _fetchPolicySchedule() async {
    final String? childId = await AuthSession.memberId();
    if (childId == null || childId.isEmpty) {
      return null;
    }

    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/children/$childId/policies',
    );
    final Map<String, dynamic>? data = _responseObject(response.data);
    if (data == null) {
      return null;
    }

    final int baseTime = _intValue(data['baseTime']);
    final int totalAvailableTime = _intValue(data['totalAvailableTime']);
    final int accumulatedRewardTime = _intValue(data['accumulatedRewardTime']);
    final String? yearMonth = _stringValue(data['yearMonth']);
    final int monthlyBudgetMinutes = baseTime > 0
        ? baseTime
        : totalAvailableTime - accumulatedRewardTime;
    if (monthlyBudgetMinutes <= 0) {
      return null;
    }

    return TimeSchedule(
      allowedHours: routinesToHourCells(await _fetchRoutinesOrEmpty()),
      weeklyTotals: _emptyWeeklyTotals(),
      dayAllocations: const <DayAllocation>[],
      monthlyBudgetMinutes: monthlyBudgetMinutes,
      yearMonth: yearMonth ?? _currentYearMonth(),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRoutines() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/v1/schedules/routines',
    );
    return _jsonList(response.data)
        .whereType<Map>()
        .map((Map value) => Map<String, dynamic>.from(value))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _fetchRoutinesOrEmpty() async {
    try {
      return await _fetchRoutines();
    } on DioException {
      return const <Map<String, dynamic>>[];
    }
  }

  @override
  Future<Result<void>> saveSchedule(TimeSchedule schedule) async {
    final String? validationMessage = _validateScheduleForSave(schedule);
    if (validationMessage != null) {
      return Result<void>.failure(validationMessage);
    }

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
    final String yearMonth = schedule.yearMonth ?? _currentYearMonth();
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

      for (final WeeklyTotal w in schedule.weeklyTotals) {
        final int weekNumber = w.weekIndex + 1;
        final Map<int, int> templateMinutes = _templateMinutesForWeek(
          schedule: schedule,
          weeklyTotal: w,
        );
        for (final MapEntry<int, int> entry in templateMinutes.entries) {
          if (entry.value <= 0) {
            continue;
          }
          await _dio.put<dynamic>(
            '/api/v1/schedules/templates',
            data: <String, dynamic>{
              'yearMonth': yearMonth,
              'weekNumber': weekNumber,
              'dayOfWeek': _dayOfWeekName(entry.key),
              'baseMinutes': entry.value,
            },
          );
        }
      }

      await _replaceRoutines(schedule.allowedHours);
      await _dio.post<dynamic>(
        '/api/v1/schedules/complete',
        queryParameters: <String, dynamic>{'yearMonth': yearMonth},
      );

      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  String? _validateScheduleForSave(TimeSchedule schedule) {
    final int? monthlyBudgetMinutes = schedule.monthlyBudgetMinutes;
    if (monthlyBudgetMinutes == null || monthlyBudgetMinutes <= 0) {
      return '부모님이 설정한 이번 달 총 시간을 다시 불러와 주세요.';
    }

    const Set<int> requiredWeekIndices = <int>{0, 1, 2, 3};
    final Set<int> weekIndices = schedule.weeklyTotals
        .map((WeeklyTotal total) => total.weekIndex)
        .toSet();
    if (schedule.weeklyTotals.length != requiredWeekIndices.length ||
        !weekIndices.containsAll(requiredWeekIndices)) {
      return '1~4주차 시간을 모두 분배해 주세요.';
    }
    if (schedule.weeklyTotals.any(
      (WeeklyTotal total) => total.totalMinutes <= 0,
    )) {
      return '1~4주차 시간을 모두 분배해 주세요.';
    }

    final int distributedMinutes = schedule.weeklyTotals.fold<int>(
      0,
      (int sum, WeeklyTotal total) => sum + total.totalMinutes,
    );
    if (distributedMinutes != monthlyBudgetMinutes) {
      return '주별 시간 합계가 부모님이 설정한 월 총 시간과 맞지 않아요.';
    }

    if (schedule.dayAllocations.isEmpty) {
      return '요일별 시간 분배를 입력해 주세요.';
    }
    return null;
  }

  /// Clears the child's existing fixed routines, then re-creates one block per
  /// contiguous run of allowed hours per weekday. `createRoutine` always
  /// inserts (no upsert), so a delete-first pass keeps re-saves idempotent.
  Future<void> _replaceRoutines(Set<HourCell> allowedHours) async {
    final Response<dynamic> listResp = await _dio.get<dynamic>(
      '/api/v1/schedules/routines',
    );
    for (final dynamic routine in _jsonList(listResp.data)) {
      final Object? id = routine is Map ? routine['id'] : null;
      if (id != null) {
        await _dio.delete<dynamic>('/api/v1/schedules/routines/$id');
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

  Map<int, int> _templateMinutesForWeek({
    required TimeSchedule schedule,
    required WeeklyTotal weeklyTotal,
  }) {
    final Map<int, int> baseMinutesByWeekday = _baseTemplateMinutes(schedule);
    final int baseTotal = baseMinutesByWeekday.values.fold<int>(
      0,
      (int sum, int minutes) => sum + minutes,
    );
    final int targetTotal = weeklyTotal.totalMinutes;
    if (baseTotal <= 0 || targetTotal <= 0) {
      return const <int, int>{};
    }
    if (baseTotal == targetTotal) {
      return baseMinutesByWeekday;
    }

    final List<int> weekdays = baseMinutesByWeekday.keys.toList()..sort();
    final Map<int, int> scaled = <int, int>{};
    int remaining = targetTotal;
    for (int i = 0; i < weekdays.length; i++) {
      final int weekday = weekdays[i];
      final int minutes = i == weekdays.length - 1
          ? remaining
          : (baseMinutesByWeekday[weekday]! * targetTotal) ~/ baseTotal;
      scaled[weekday] = minutes;
      remaining -= minutes;
    }
    return scaled;
  }

  Map<int, int> _baseTemplateMinutes(TimeSchedule schedule) {
    final Map<int, int> minutesByWeekday = <int, int>{};
    for (final DayAllocation allocation in schedule.dayAllocations) {
      for (final int weekday in allocation.weekdayIndices) {
        minutesByWeekday[weekday] =
            (minutesByWeekday[weekday] ?? 0) + allocation.totalMinutes;
      }
    }
    return minutesByWeekday;
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

  String _yyyyMmDd(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic>? _responseObject(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  List<dynamic> _jsonList(dynamic data) {
    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data'] as List);
    }
    if (data is List) {
      return List<dynamic>.from(data);
    }
    return const <dynamic>[];
  }

  List<WeeklyTotal> _emptyWeeklyTotals() {
    return <WeeklyTotal>[
      for (int weekIndex = 0; weekIndex < 4; weekIndex++)
        WeeklyTotal(weekIndex: weekIndex, hours: 0, minutes: 0),
    ];
  }

  bool _isMissingPolicyError(DioException e) {
    final int? statusCode = e.response?.statusCode;
    if (statusCode == 404) {
      return true;
    }
    if (statusCode != 400) {
      return false;
    }
    final String message = _responseMessage(e.response?.data);
    return message.contains('시간 정책') || message.contains('정책이 없습니다');
  }

  String _responseMessage(dynamic data) {
    if (data is Map) {
      final Object? dataMessage = data['data'];
      if (dataMessage is String && dataMessage.isNotEmpty) {
        return dataMessage;
      }
      final Object? message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return '';
  }

  int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  String? _stringValue(Object? value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }
}
