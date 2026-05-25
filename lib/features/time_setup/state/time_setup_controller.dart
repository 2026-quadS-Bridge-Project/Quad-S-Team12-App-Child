import 'package:flutter/foundation.dart';

import '../../../core/models/result.dart';
import '../data/mock/time_schedule_mock.dart';
import '../data/models/time_schedule.dart';
import '../data/repositories/time_setup_repository.dart';

enum TimeSetupStep {
  /// Pre-step splash that shows the 3-step description list and a `시작` CTA
  /// before entering [scheduleRegister].
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
    TimeSetupRepository? repository,
  }) : _schedule = initial ?? TimeScheduleMock.empty,
       _mode = mode,
       _previousWeek = null,
       _repository = repository ?? createTimeSetupRepository();

  /// v2 entry: keeps the immutable [previousWeek] snapshot for the dimmed
  /// `1주차` row, while the editable draft keeps weeks 2-4 empty until the
  /// child manually distributes the remaining monthly budget. Mutations
  /// (setWeeklyTotal / upsertAllocation / removeAllocation / toggleHour) only
  /// touch [_schedule] — [_previousWeek] remains untouched so the historical
  /// reference can always be re-read.
  TimeSetupController.v2NextWeek({
    required TimeSchedule previousWeek,
    TimeSetupRepository? repository,
  }) : _schedule = _draftFromPreviousWeek(previousWeek),
       _previousWeek = previousWeek,
       _mode = TimeSetupMode.v2NextWeek,
       _step = TimeSetupStep.intro,
       _repository = repository ?? createTimeSetupRepository();

  TimeSchedule _schedule;
  final TimeSchedule? _previousWeek;
  TimeSetupStep _step = TimeSetupStep.intro;
  final TimeSetupMode _mode;
  final TimeSetupRepository _repository;
  bool _isSaving = false;
  String? _errorMessage;
  static const List<int> _allWeekIndices = <int>[0, 1, 2, 3];
  static const List<int> _v2EditableWeekIndices = <int>[1, 2, 3];
  static const List<String> _weekdayLabels = <String>[
    '월',
    '화',
    '수',
    '목',
    '금',
    '토',
    '일',
  ];

  TimeSchedule get schedule => _schedule;
  TimeSchedule? get previousWeek => _previousWeek;
  TimeSetupStep get step => _step;
  TimeSetupMode get mode => _mode;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get showPastWeekDim => _mode == TimeSetupMode.v2NextWeek;
  int get currentWeekIndex => showPastWeekDim ? 1 : 0;
  int get currentWeekTotalMinutes =>
      _schedule.weeklyTotalMinutesAt(currentWeekIndex);
  int get currentWeekTotalHours => currentWeekTotalMinutes ~/ 60;
  int get currentWeekTotalRemainderMinutes => currentWeekTotalMinutes % 60;
  List<int> get editableWeekIndices =>
      showPastWeekDim ? _v2EditableWeekIndices : _allWeekIndices;
  int get lockedPastWeekMinutes =>
      showPastWeekDim ? _previousWeek?.weeklyTotalMinutesAt(0) ?? 0 : 0;
  int get weeklyDistributionCapMinutes {
    if (!showPastWeekDim) {
      return _schedule.weeklyTotalCapMinutes;
    }

    final int previousMonthCap =
        _previousWeek?.weeklyTotalCapMinutes ?? _schedule.weeklyTotalCapMinutes;
    final int remaining = previousMonthCap - lockedPastWeekMinutes;
    return remaining > 0 ? remaining : 0;
  }

  int get weeklyDistributionCapHours => weeklyDistributionCapMinutes ~/ 60;
  int get weeklyDistributionCapRemainderMinutes =>
      weeklyDistributionCapMinutes % 60;
  int get editableWeeklyTotalMinutes =>
      editableWeekIndices.fold<int>(0, _sumWeekMinutesAt);
  int get editableWeeklyRemainingMinutes =>
      weeklyDistributionCapMinutes - editableWeeklyTotalMinutes;
  int get allocationDeltaMinutes =>
      _schedule.allocatedMinutes - currentWeekTotalMinutes;
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
  /// callers that haven't migrated to per-week input yet). In v2, the locked
  /// `1주차` row is never edited; null applies only to the future weeks.
  void setWeeklyTotal({
    required int hours,
    required int minutes,
    int? weekIndex,
  }) {
    final Set<int> targetWeekIndices = weekIndex == null
        ? editableWeekIndices.toSet()
        : <int>{if (_isEditableWeekIndex(weekIndex)) weekIndex};
    if (targetWeekIndices.isEmpty) {
      return;
    }

    final List<WeeklyTotal> next = <WeeklyTotal>[
      for (final WeeklyTotal w in _schedule.weeklyTotals)
        if (targetWeekIndices.contains(w.weekIndex))
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

  /// v1 requires all four weeks to be populated. v2 validates only editable
  /// weeks 2-4, and their sum must match the remaining cap after locked week 1.
  bool get canProceedToStep3 {
    if (_schedule.weeklyTotals.isEmpty) {
      return false;
    }
    if (!showPastWeekDim) {
      return _schedule.weeklyTotals.every(
        (WeeklyTotal w) => w.totalMinutes > 0,
      );
    }

    final bool allEditableWeeksFilled = editableWeekIndices.every(
      (int weekIndex) => _schedule.weeklyTotalMinutesAt(weekIndex) > 0,
    );
    return weeklyDistributionCapMinutes > 0 &&
        allEditableWeeksFilled &&
        editableWeeklyTotalMinutes == weeklyDistributionCapMinutes;
  }

  void autoDistributeWeeklyTotals() {
    final List<int> indices = editableWeekIndices;
    if (indices.isEmpty || weeklyDistributionCapMinutes <= 0) {
      return;
    }

    // Figma v2-5 keeps the first future weeks at whole-hour values and puts
    // the leftover minutes on the final editable week: 45h30m -> 15h / 15h /
    // 15h30m.
    final int baseMinutes =
        ((weeklyDistributionCapMinutes ~/ indices.length) ~/ 60) * 60;
    final int remainderMinutes =
        weeklyDistributionCapMinutes - (baseMinutes * indices.length);
    final Map<int, int> minutesByWeek = <int, int>{
      for (int i = 0; i < indices.length; i++)
        indices[i]:
            baseMinutes + (i == indices.length - 1 ? remainderMinutes : 0),
    };

    final List<WeeklyTotal> next = <WeeklyTotal>[
      for (final WeeklyTotal w in _schedule.weeklyTotals)
        if (minutesByWeek.containsKey(w.weekIndex))
          _weeklyTotalFromMinutes(w.weekIndex, minutesByWeek[w.weekIndex]!)
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

  // Step 3: daily allocations
  void addDailyAllocation(DayAllocation allocation) {
    final Map<int, int> minutesByDay = _minutesByDay();
    for (final int weekday in allocation.weekdayIndices) {
      minutesByDay[weekday] =
          (minutesByDay[weekday] ?? 0) + allocation.totalMinutes;
    }
    _setDayAllocationsFrom(minutesByDay);
  }

  void replaceDailyAllocation({
    required DayAllocation original,
    required DayAllocation replacement,
  }) {
    final Map<int, int> minutesByDay = _minutesByDay();
    for (final int weekday in original.weekdayIndices) {
      final int next = (minutesByDay[weekday] ?? 0) - original.totalMinutes;
      if (next > 0) {
        minutesByDay[weekday] = next;
      } else {
        minutesByDay.remove(weekday);
      }
    }
    for (final int weekday in replacement.weekdayIndices) {
      minutesByDay[weekday] = replacement.totalMinutes;
    }
    _setDayAllocationsFrom(minutesByDay);
  }

  void upsertAllocation(DayAllocation alloc) {
    addDailyAllocation(alloc);
  }

  Map<int, int> _minutesByDay() {
    final Map<int, int> minutesByDay = <int, int>{};
    for (final DayAllocation allocation in _schedule.dayAllocations) {
      for (final int weekday in allocation.weekdayIndices) {
        minutesByDay[weekday] =
            (minutesByDay[weekday] ?? 0) + allocation.totalMinutes;
      }
    }
    return minutesByDay;
  }

  void _setDayAllocationsFrom(Map<int, int> minutesByDay) {
    final Map<int, List<int>> daysByMinutes = <int, List<int>>{};
    for (int weekday = 0; weekday < _weekdayLabels.length; weekday++) {
      final int minutes = minutesByDay[weekday] ?? 0;
      if (minutes <= 0) {
        continue;
      }
      daysByMinutes.putIfAbsent(minutes, () => <int>[]).add(weekday);
    }

    final List<DayAllocation> allocations =
        daysByMinutes.entries.map((MapEntry<int, List<int>> entry) {
          final List<int> weekdays = entry.value..sort();
          final int totalMinutes = entry.key;
          return DayAllocation(
            daysLabel: weekdays.map((int i) => _weekdayLabels[i]).join(','),
            weekdayIndices: List<int>.unmodifiable(weekdays),
            hours: totalMinutes ~/ 60,
            minutes: totalMinutes % 60,
          );
        }).toList()..sort(
          (DayAllocation a, DayAllocation b) =>
              a.weekdayIndices.first.compareTo(b.weekdayIndices.first),
        );

    _schedule = TimeSchedule(
      allowedHours: _schedule.allowedHours,
      weeklyTotals: _schedule.weeklyTotals,
      dayAllocations: allocations,
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
      allocationDeltaMinutes == 0 && _schedule.dayAllocations.isNotEmpty;
  bool get isOverBudget => allocationDeltaMinutes > 0;
  bool get isUnderBudget => allocationDeltaMinutes < 0;

  // Navigation
  void goToStep(TimeSetupStep next) {
    _step = next;
    notifyListeners();
  }

  // Final submit — pushes the finished plan through [TimeSetupRepository].
  // On Success transitions to [TimeSetupStep.complete]; on Failure records
  // [errorMessage] and stays on the current step.
  Future<void> submit() async {
    if (_isSaving) {
      return;
    }
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Result<void> result = await _repository.saveSchedule(_schedule);
      switch (result) {
        case Success<void>():
          _step = TimeSetupStep.complete;
        case Failure<void>(message: final String message):
          _errorMessage = message;
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Clears [errorMessage] so the same failure can re-fire on the next submit.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Mode-aware reset. v2 must preserve [_previousWeek] (immutable historical
  /// record); both flows return to the intro splash so the 3-step explainer
  /// plays again. [_mode] is preserved in both cases — `showPastWeekDim`
  /// therefore stays consistent with how the controller was constructed.
  void reset() {
    if (_mode == TimeSetupMode.v2NextWeek) {
      _schedule = _previousWeek == null
          ? TimeScheduleMock.empty
          : _draftFromPreviousWeek(_previousWeek);
      _step = TimeSetupStep.intro;
    } else {
      _schedule = TimeScheduleMock.empty;
      _step = TimeSetupStep.intro;
    }
    notifyListeners();
  }

  int _sumWeekMinutesAt(int sum, int weekIndex) =>
      sum + _schedule.weeklyTotalMinutesAt(weekIndex);

  bool _isEditableWeekIndex(int weekIndex) =>
      editableWeekIndices.contains(weekIndex);

  static TimeSchedule _draftFromPreviousWeek(TimeSchedule previousWeek) {
    return TimeSchedule(
      allowedHours: previousWeek.allowedHours,
      weeklyTotals: <WeeklyTotal>[
        _weeklyTotalFromMinutes(0, previousWeek.weeklyTotalMinutesAt(0)),
        for (final int weekIndex in _v2EditableWeekIndices)
          WeeklyTotal(weekIndex: weekIndex, hours: 0, minutes: 0),
      ],
      dayAllocations: previousWeek.dayAllocations,
    );
  }

  static WeeklyTotal _weeklyTotalFromMinutes(int weekIndex, int totalMinutes) {
    return WeeklyTotal(
      weekIndex: weekIndex,
      hours: totalMinutes ~/ 60,
      minutes: totalMinutes % 60,
    );
  }
}
