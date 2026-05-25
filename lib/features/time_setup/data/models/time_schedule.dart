class HourCell {
  const HourCell({required this.weekday, required this.hour});
  final int weekday; // 0..6 (월=0)
  final int hour; // 0..23 (or 7..23 visible range)

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
}

class TimeSchedule {
  const TimeSchedule({
    required this.allowedHours,
    required this.weeklyTotals,
    required this.dayAllocations,
  });

  final Set<HourCell> allowedHours; // from 스케쥴 등록 grid
  final List<WeeklyTotal> weeklyTotals; // one entry per 주차 (typically 4)
  final List<DayAllocation> dayAllocations;

  /// Total cap across **all** weeks (sum of every entry in [weeklyTotals]).
  int get weeklyTotalCapMinutes =>
      weeklyTotals.fold(0, (sum, w) => sum + w.totalMinutes);

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
