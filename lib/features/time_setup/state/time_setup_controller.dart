import 'package:flutter/foundation.dart';

import '../data/mock/time_schedule_mock.dart';
import '../data/models/time_schedule.dart';

enum TimeSetupStep {
  /// Pre-step splash. v2-only entry that shows the 3-step description list
  /// and a `시작` CTA before entering [scheduleRegister]. v1 never enters
  /// this state — it constructs straight into [scheduleRegister].
  intro,
  scheduleRegister,
  weeklyTotal,
  dailyAllocation,
  review,
  complete,
}

enum TimeSetupMode { v1Initial, v2NextWeek }

class TimeSetupController extends ChangeNotifier {
  TimeSetupController({
    TimeSchedule? initial,
    TimeSetupMode mode = TimeSetupMode.v1Initial,
  }) : _schedule = initial ?? TimeScheduleMock.empty,
       _mode = mode,
       _previousWeek = null;

  /// v2 entry: keeps the immutable [previousWeek] snapshot for the dimmed
  /// `1주차` row and seeds [_schedule] with the same data so the user starts
  /// editing from the prior week's plan. Mutations (setWeeklyTotal /
  /// upsertAllocation / removeAllocation / toggleHour) only touch [_schedule]
  /// — [_previousWeek] remains untouched so the historical reference can
  /// always be re-read.
  TimeSetupController.v2NextWeek({required TimeSchedule previousWeek})
    : _schedule = previousWeek,
      _previousWeek = previousWeek,
      _mode = TimeSetupMode.v2NextWeek,
      _step = TimeSetupStep.intro;

  TimeSchedule _schedule;
  final TimeSchedule? _previousWeek;
  TimeSetupStep _step = TimeSetupStep.scheduleRegister;
  final TimeSetupMode _mode;

  TimeSchedule get schedule => _schedule;
  TimeSchedule? get previousWeek => _previousWeek;
  TimeSetupStep get step => _step;
  TimeSetupMode get mode => _mode;
  bool get showPastWeekDim => _mode == TimeSetupMode.v2NextWeek;
  int get stepIndex => switch (_step) {
    // intro is a pre-step splash; the 3-pill stepper still highlights
    // step 1 so the upcoming destination is visually anticipated.
    TimeSetupStep.intro => 1,
    TimeSetupStep.scheduleRegister => 1,
    TimeSetupStep.weeklyTotal => 2,
    TimeSetupStep.dailyAllocation => 3,
    TimeSetupStep.review => 3,
    TimeSetupStep.complete => 3,
  };

  // Step 1: schedule register grid
  void toggleHour(int weekday, int hour) {
    final cell = HourCell(weekday: weekday, hour: hour);
    final newSet = Set<HourCell>.from(_schedule.allowedHours);
    if (newSet.contains(cell)) {
      newSet.remove(cell);
    } else {
      newSet.add(cell);
    }
    _schedule = TimeSchedule(
      allowedHours: newSet,
      weeklyTotals: _schedule.weeklyTotals,
      dayAllocations: _schedule.dayAllocations,
    );
    notifyListeners();
  }

  bool get canProceedToStep2 => _schedule.allowedHours.isNotEmpty;

  /// Step 2: set the weekly total for one 주차 (or all weeks if [weekIndex]
  /// is null — legacy "set them all to the same value" behaviour, used by
  /// callers that haven't migrated to per-week input yet).
  void setWeeklyTotal({
    required int hours,
    required int minutes,
    int? weekIndex,
  }) {
    final List<WeeklyTotal> next = <WeeklyTotal>[
      for (final WeeklyTotal w in _schedule.weeklyTotals)
        if (weekIndex == null || w.weekIndex == weekIndex)
          WeeklyTotal(weekIndex: w.weekIndex, hours: hours, minutes: minutes)
        else
          w,
    ];
    _schedule = TimeSchedule(
      allowedHours: _schedule.allowedHours,
      weeklyTotals: next,
      dayAllocations: _schedule.dayAllocations,
    );
    notifyListeners();
  }

  /// All 4 weeks must have a non-zero total before proceeding to allocation.
  bool get canProceedToStep3 =>
      _schedule.weeklyTotals.isNotEmpty &&
      _schedule.weeklyTotals.every((WeeklyTotal w) => w.totalMinutes > 0);

  // Step 3: daily allocations
  void upsertAllocation(DayAllocation alloc) {
    // Replace allocation with same daysLabel, or append.
    final list = List<DayAllocation>.from(_schedule.dayAllocations);
    final idx = list.indexWhere((a) => a.daysLabel == alloc.daysLabel);
    if (idx >= 0) {
      list[idx] = alloc;
    } else {
      list.add(alloc);
    }
    _schedule = TimeSchedule(
      allowedHours: _schedule.allowedHours,
      weeklyTotals: _schedule.weeklyTotals,
      dayAllocations: list,
    );
    notifyListeners();
  }

  void removeAllocation(String daysLabel) {
    final list = _schedule.dayAllocations
        .where((a) => a.daysLabel != daysLabel)
        .toList(growable: false);
    _schedule = TimeSchedule(
      allowedHours: _schedule.allowedHours,
      weeklyTotals: _schedule.weeklyTotals,
      dayAllocations: list,
    );
    notifyListeners();
  }

  bool get isAllocationBalanced =>
      _schedule.deltaMinutes == 0 && _schedule.dayAllocations.isNotEmpty;
  bool get isOverBudget => _schedule.deltaMinutes > 0;
  bool get isUnderBudget => _schedule.deltaMinutes < 0;

  // Navigation
  void goToStep(TimeSetupStep next) {
    _step = next;
    notifyListeners();
  }

  // Final submit — in real backend this would push to parent; for mock, just transitions to complete.
  void submit() {
    _step = TimeSetupStep.complete;
    notifyListeners();
  }

  /// Mode-aware reset. v2 must preserve [_previousWeek] (immutable historical
  /// record) and return to the intro splash so the 3-step explainer plays
  /// again; v1 has no intro step so it returns straight to [scheduleRegister].
  /// [_mode] is preserved in both cases — `showPastWeekDim` therefore stays
  /// consistent with how the controller was constructed.
  void reset() {
    if (_mode == TimeSetupMode.v2NextWeek) {
      _schedule = _previousWeek ?? TimeScheduleMock.empty;
      _step = TimeSetupStep.intro;
    } else {
      _schedule = TimeScheduleMock.empty;
      _step = TimeSetupStep.scheduleRegister;
    }
    notifyListeners();
  }
}
