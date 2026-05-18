import '../models/time_schedule.dart';

class TimeScheduleMock {
  const TimeScheduleMock._();

  /// Default 4-week plan with all weeks at zero (used for empty initial state
  /// and as a base when constructing other fixtures).
  static const List<WeeklyTotal> _zeroWeeks = <WeeklyTotal>[
    WeeklyTotal(weekIndex: 0, hours: 0, minutes: 0),
    WeeklyTotal(weekIndex: 1, hours: 0, minutes: 0),
    WeeklyTotal(weekIndex: 2, hours: 0, minutes: 0),
    WeeklyTotal(weekIndex: 3, hours: 0, minutes: 0),
  ];

  /// Helper: 4 weeks each at the same (hours, minutes).
  static List<WeeklyTotal> _uniformWeeks(int hours, int minutes) =>
      <WeeklyTotal>[
        for (int i = 0; i < 4; i++)
          WeeklyTotal(weekIndex: i, hours: hours, minutes: minutes),
      ];

  /// Empty initial state — used when child first opens 시간 설정.
  static const TimeSchedule empty = TimeSchedule(
    allowedHours: {},
    weeklyTotals: _zeroWeeks,
    dayAllocations: [],
  );

  /// Sample filled state matching Figma 08c completion screens
  /// (21h per week across all 4 weeks, 3 day-sets at 7h each).
  static TimeSchedule get sampleFilled => TimeSchedule(
    allowedHours: {
      // 07~22 every weekday (mon-fri)
      for (int w = 0; w < 5; w++)
        for (int h = 7; h < 22; h++) HourCell(weekday: w, hour: h),
      // weekends 09~23
      for (int w = 5; w < 7; w++)
        for (int h = 9; h < 23; h++) HourCell(weekday: w, hour: h),
    },
    weeklyTotals: _uniformWeeks(21, 0),
    dayAllocations: [
      DayAllocation(
        daysLabel: '월,수,금',
        weekdayIndices: [0, 2, 4],
        hours: 7,
        minutes: 0,
      ),
      DayAllocation(
        daysLabel: '화,목',
        weekdayIndices: [1, 3],
        hours: 7,
        minutes: 0,
      ),
      DayAllocation(
        daysLabel: '토,일',
        weekdayIndices: [5, 6],
        hours: 7,
        minutes: 0,
      ),
    ],
  );

  /// Over-budget example for error banner testing
  /// (allocated 23h/wk vs 21h/wk cap, 4 weeks).
  static TimeSchedule get sampleOverBudget => TimeSchedule(
    allowedHours: sampleFilled.allowedHours,
    weeklyTotals: _uniformWeeks(21, 0),
    dayAllocations: [
      DayAllocation(
        daysLabel: '월,수,금',
        weekdayIndices: [0, 2, 4],
        hours: 8,
        minutes: 0,
      ),
      DayAllocation(
        daysLabel: '화,목',
        weekdayIndices: [1, 3],
        hours: 7,
        minutes: 0,
      ),
      DayAllocation(
        daysLabel: '토,일',
        weekdayIndices: [5, 6],
        hours: 8,
        minutes: 0,
      ),
    ],
  );
}
