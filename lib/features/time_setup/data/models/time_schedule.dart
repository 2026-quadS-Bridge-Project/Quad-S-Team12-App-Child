class HourCell {
  const HourCell({required this.weekday, required this.hour});
  final int weekday; // 0..6 (월=0)
  final int hour; // 0..23 (or 7..23 visible range)

  /// JSON shape: `{"weekday": int, "hour": int}`.
  factory HourCell.fromJson(Map<String, dynamic> json) =>
      HourCell(weekday: json['weekday'] as int, hour: json['hour'] as int);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'weekday': weekday,
    'hour': hour,
  };

  @override
  bool operator ==(Object other) =>
      other is HourCell && other.weekday == weekday && other.hour == hour;
  @override
  int get hashCode => Object.hash(weekday, hour);
}

class DayAllocation {
  const DayAllocation({
    required this.daysLabel,
    required this.weekdayIndices,
    required this.hours,
    required this.minutes,
  });
  final String daysLabel; // '월,수,금'
  final List<int> weekdayIndices; // [0,2,4]
  final int hours;
  final int minutes;

  int get totalMinutes => hours * 60 + minutes;
  int get totalAllocatedMinutes => totalMinutes * weekdayIndices.length;

  /// JSON shape:
  /// `{"daysLabel": String, "weekdayIndices": [int...], "hours": int, "minutes": int}`.
  factory DayAllocation.fromJson(Map<String, dynamic> json) => DayAllocation(
    daysLabel: json['daysLabel'] as String,
    weekdayIndices: (json['weekdayIndices'] as List<dynamic>)
        .map((dynamic e) => e as int)
        .toList(growable: false),
    hours: json['hours'] as int,
    minutes: json['minutes'] as int,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'daysLabel': daysLabel,
    'weekdayIndices': weekdayIndices,
    'hours': hours,
    'minutes': minutes,
  };
}

/// Per-week total cap. One row per 주차 in the 4-week plan.
class WeeklyTotal {
  const WeeklyTotal({
    required this.weekIndex,
    required this.hours,
    required this.minutes,
  });
  final int weekIndex;
  final int hours;
  final int minutes;
  int get totalMinutes => hours * 60 + minutes;

  /// JSON shape: `{"weekIndex": int, "hours": int, "minutes": int}`.
  factory WeeklyTotal.fromJson(Map<String, dynamic> json) => WeeklyTotal(
    weekIndex: json['weekIndex'] as int,
    hours: json['hours'] as int,
    minutes: json['minutes'] as int,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'weekIndex': weekIndex,
    'hours': hours,
    'minutes': minutes,
  };
}

class TimeSchedule {
  const TimeSchedule({
    required this.allowedHours,
    required this.weeklyTotals,
    required this.dayAllocations,
    this.monthlyBudgetMinutes,
    this.yearMonth,
  });

  final Set<HourCell> allowedHours; // from 스케쥴 등록 grid
  final List<WeeklyTotal> weeklyTotals; // one entry per 주차 (typically 4)
  final List<DayAllocation> dayAllocations;
  final int? monthlyBudgetMinutes;
  final String? yearMonth;

  /// JSON shape:
  /// `{"allowedHours": [HourCell...], "weeklyTotals": [WeeklyTotal...],
  ///   "dayAllocations": [DayAllocation...]}`.
  factory TimeSchedule.fromJson(Map<String, dynamic> json) => TimeSchedule(
    allowedHours: <HourCell>{
      for (final dynamic cell in json['allowedHours'] as List<dynamic>)
        HourCell.fromJson(cell as Map<String, dynamic>),
    },
    weeklyTotals: <WeeklyTotal>[
      for (final dynamic w in json['weeklyTotals'] as List<dynamic>)
        WeeklyTotal.fromJson(w as Map<String, dynamic>),
    ],
    dayAllocations: <DayAllocation>[
      for (final dynamic a in json['dayAllocations'] as List<dynamic>)
        DayAllocation.fromJson(a as Map<String, dynamic>),
    ],
    monthlyBudgetMinutes: json['monthlyBudgetMinutes'] is num
        ? (json['monthlyBudgetMinutes'] as num).toInt()
        : null,
    yearMonth: json['yearMonth'] is String ? json['yearMonth'] as String : null,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'allowedHours': <Map<String, dynamic>>[
      for (final HourCell cell in allowedHours) cell.toJson(),
    ],
    'weeklyTotals': <Map<String, dynamic>>[
      for (final WeeklyTotal w in weeklyTotals) w.toJson(),
    ],
    'dayAllocations': <Map<String, dynamic>>[
      for (final DayAllocation a in dayAllocations) a.toJson(),
    ],
    if (monthlyBudgetMinutes != null)
      'monthlyBudgetMinutes': monthlyBudgetMinutes,
    if (yearMonth != null) 'yearMonth': yearMonth,
  };

  /// Sum of the child-entered weekly rows.
  int get distributedWeeklyTotalMinutes =>
      weeklyTotals.fold(0, (sum, w) => sum + w.totalMinutes);

  /// Parent-granted monthly cap when available, otherwise the row sum.
  int get weeklyTotalCapMinutes =>
      monthlyBudgetMinutes ?? distributedWeeklyTotalMinutes;

  int weeklyTotalMinutesAt(int weekIndex) {
    for (final WeeklyTotal total in weeklyTotals) {
      if (total.weekIndex == weekIndex) {
        return total.totalMinutes;
      }
    }
    return 0;
  }

  int weeklyHoursAt(int weekIndex) => weeklyTotalMinutesAt(weekIndex) ~/ 60;
  int weeklyMinutesAt(int weekIndex) => weeklyTotalMinutesAt(weekIndex) % 60;

  /// Aggregate hours portion of all weeks combined.
  /// Kept for backward compatibility with consumers that read a single pair.
  int get totalWeeklyHours => weeklyTotalCapMinutes ~/ 60;

  /// Aggregate minutes portion of all weeks combined.
  int get totalWeeklyMinutes => weeklyTotalCapMinutes % 60;

  /// Legacy alias — same value as [totalWeeklyHours].
  /// Pre-existing call sites (review/confirm/daily pages) still reference
  /// `weeklyTotalHours` / `weeklyTotalMinutes`; keeping the names avoids a
  /// breaking change while the per-week model rolls out.
  int get weeklyTotalHours => totalWeeklyHours;
  int get weeklyTotalMinutes => totalWeeklyMinutes;

  int get allocatedMinutes =>
      dayAllocations.fold(0, (sum, a) => sum + a.totalAllocatedMinutes);

  int deltaMinutesForWeek(int weekIndex) =>
      allocatedMinutes -
      weeklyTotalMinutesAt(weekIndex); // over = positive, under = negative

  int get deltaMinutes => deltaMinutesForWeek(0);
}

/// Builds the app's schedule DTO from the AWS Swagger shape returned by
/// `GET /api/v1/schedules/daily`.
///
/// The deployed API currently returns a daily snapshot rather than the app's
/// older full-month `TimeSchedule` shape. This adapter keeps the UI renderable
/// while ensuring the app only consumes documented AWS endpoints.
TimeSchedule dailyScheduleToTimeSchedule(
  Map<String, dynamic> json, {
  List<Map<String, dynamic>> routines = const <Map<String, dynamic>>[],
}) {
  final DateTime targetDate =
      DateTime.tryParse(json['targetDate']?.toString() ?? '') ?? DateTime.now();
  final String yearMonth =
      '${targetDate.year.toString().padLeft(4, '0')}-'
      '${targetDate.month.toString().padLeft(2, '0')}';
  final int weekday = targetDate.weekday - 1;
  final int weekIndex = (targetDate.day - 1) ~/ 7;
  final int baseMinutes = _intValue(json['baseMinutes']);
  final int totalMinutes = _intValue(
    json['totalAvailableMinutes'],
    fallback: baseMinutes + _intValue(json['extendedMinutes']),
  );

  return TimeSchedule(
    allowedHours: routinesToHourCells(routines),
    weeklyTotals: <WeeklyTotal>[
      _weeklyTotalFromMinutes(weekIndex, totalMinutes),
    ],
    dayAllocations: baseMinutes <= 0
        ? const <DayAllocation>[]
        : <DayAllocation>[
            DayAllocation(
              daysLabel: _weekdayKor(weekday),
              weekdayIndices: <int>[weekday],
              hours: baseMinutes ~/ 60,
              minutes: baseMinutes % 60,
            ),
          ],
    yearMonth: yearMonth,
  );
}

Set<HourCell> routinesToHourCells(List<Map<String, dynamic>> routines) {
  final Set<HourCell> cells = <HourCell>{};
  for (final Map<String, dynamic> routine in routines) {
    final int? weekday = _weekdayFromWire(routine['dayOfWeek']);
    final int? start = _hourFromWire(routine['startTime']);
    final int? end = _hourFromWire(routine['endTime']);
    if (weekday == null || start == null || end == null || end <= start) {
      continue;
    }
    for (int hour = start; hour < end.clamp(0, 24); hour++) {
      cells.add(HourCell(weekday: weekday, hour: hour));
    }
  }
  return cells;
}

WeeklyTotal _weeklyTotalFromMinutes(int weekIndex, int totalMinutes) {
  return WeeklyTotal(
    weekIndex: weekIndex,
    hours: totalMinutes ~/ 60,
    minutes: totalMinutes % 60,
  );
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return fallback;
}

String _weekdayKor(int weekday) {
  const List<String> labels = <String>['월', '화', '수', '목', '금', '토', '일'];
  return labels[weekday.clamp(0, 6)];
}

int? _weekdayFromWire(Object? value) {
  if (value == null) return null;
  const Map<String, int> names = <String, int>{
    'MONDAY': 0,
    'TUESDAY': 1,
    'WEDNESDAY': 2,
    'THURSDAY': 3,
    'FRIDAY': 4,
    'SATURDAY': 5,
    'SUNDAY': 6,
  };
  return names[value.toString().toUpperCase()];
}

int? _hourFromWire(Object? value) {
  if (value is Map && value['hour'] is num) {
    return (value['hour'] as num).toInt();
  }
  if (value is String && value.length >= 2) {
    return int.tryParse(value.substring(0, 2));
  }
  return null;
}
