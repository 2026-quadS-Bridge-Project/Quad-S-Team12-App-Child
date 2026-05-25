import 'package:bridge_k/features/time_setup/data/models/time_schedule.dart';

import '../models/time_confirm_data.dart';

class TimeConfirmMock {
  const TimeConfirmMock._();

  static const TimeConfirmData empty = TimeConfirmData(schedule: null);

  /// Display-only fixture for docs/figma-specs/10-time-confirm.md.
  ///
  /// Keep this local to time-confirm so the shared TimeScheduleMock can remain
  /// useful for setup/review flows with their own Figma values.
  static const TimeSchedule _figmaFilledSchedule = TimeSchedule(
    allowedHours: <HourCell>{},
    weeklyTotals: <WeeklyTotal>[
      WeeklyTotal(weekIndex: 0, hours: 15, minutes: 0),
    ],
    dayAllocations: <DayAllocation>[
      DayAllocation(
        daysLabel: '월, 수, 금',
        weekdayIndices: <int>[0, 2, 4],
        hours: 7,
        minutes: 0,
      ),
      DayAllocation(
        daysLabel: '화, 목',
        weekdayIndices: <int>[1, 3],
        hours: 7,
        minutes: 0,
      ),
      DayAllocation(
        daysLabel: '토, 일',
        weekdayIndices: <int>[5, 6],
        hours: 7,
        minutes: 0,
      ),
    ],
  );

  static const TimeConfirmData filled = TimeConfirmData(
    schedule: _figmaFilledSchedule,
  );

  static const TimeConfirmData filledWithOnboarding = TimeConfirmData(
    schedule: _figmaFilledSchedule,
    showOnboarding: true,
  );
}
