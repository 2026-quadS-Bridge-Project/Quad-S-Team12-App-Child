import 'package:bridge_k/features/time_setup/data/models/time_schedule.dart';
import 'package:bridge_k/features/time_setup/data/mock/time_schedule_mock.dart';
import 'package:bridge_k/features/time_setup/data/repositories/time_setup_repository.dart';
import 'package:bridge_k/features/time_setup/state/time_setup_controller.dart';
import 'package:bridge_k/core/models/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TimeSchedule scheduleWith({
    List<int> weeklyMinutes = const <int>[60, 60, 60, 60],
    List<DayAllocation> allocations = const <DayAllocation>[],
    int? monthlyBudgetMinutes,
  }) {
    assert(weeklyMinutes.length == 4);
    return TimeSchedule(
      allowedHours: <HourCell>{const HourCell(weekday: 0, hour: 7)},
      weeklyTotals: <WeeklyTotal>[
        for (int i = 0; i < weeklyMinutes.length; i++)
          WeeklyTotal(
            weekIndex: i,
            hours: weeklyMinutes[i] ~/ 60,
            minutes: weeklyMinutes[i] % 60,
          ),
      ],
      dayAllocations: allocations,
      monthlyBudgetMinutes: monthlyBudgetMinutes,
    );
  }

  test('v1 controller starts at intro before schedule registration', () {
    final TimeSetupController controller = TimeSetupController();

    expect(controller.mode, TimeSetupMode.v1Initial);
    expect(controller.step, TimeSetupStep.intro);
    expect(controller.stepIndex, 1);

    controller.goToStep(TimeSetupStep.scheduleRegister);

    expect(controller.step, TimeSetupStep.scheduleRegister);
  });

  test('reset returns v1 flow to intro and clears the draft schedule', () {
    final TimeSetupController controller = TimeSetupController(
      initial: scheduleWith(weeklyMinutes: const <int>[120, 60, 60, 60]),
    )..goToStep(TimeSetupStep.weeklyTotal);

    controller.reset();

    expect(controller.mode, TimeSetupMode.v1Initial);
    expect(controller.step, TimeSetupStep.intro);
    expect(controller.schedule.allowedHours, isEmpty);
  });

  test('v2 controller starts and resets to intro while preserving history', () {
    final TimeSchedule previousWeek = scheduleWith(
      weeklyMinutes: const <int>[180, 180, 180, 180],
    );
    final TimeSetupController controller =
        TimeSetupController.v2NextWeek(previousWeek: previousWeek)
          ..setWeeklyTotal(hours: 4, minutes: 0, weekIndex: 1)
          ..goToStep(TimeSetupStep.weeklyTotal);

    controller.reset();

    expect(controller.mode, TimeSetupMode.v2NextWeek);
    expect(controller.step, TimeSetupStep.intro);
    expect(controller.previousWeek, same(previousWeek));
    expect(controller.schedule.weeklyTotalMinutesAt(0), 180);
    expect(controller.schedule.weeklyTotalMinutesAt(1), 0);
    expect(controller.schedule.weeklyTotalMinutesAt(2), 0);
    expect(controller.schedule.weeklyTotalMinutesAt(3), 0);
  });

  test('v2 previousWeek remains immutable after weekly edits', () {
    final TimeSchedule previousWeek = scheduleWith(
      weeklyMinutes: const <int>[120, 180, 240, 300],
    );
    final TimeSetupController controller = TimeSetupController.v2NextWeek(
      previousWeek: previousWeek,
    );

    controller.setWeeklyTotal(hours: 7, minutes: 30, weekIndex: 1);
    controller.setWeeklyTotal(hours: 9, minutes: 0, weekIndex: 0);

    expect(controller.previousWeek, same(previousWeek));
    expect(previousWeek.weeklyTotalMinutesAt(0), 120);
    expect(previousWeek.weeklyTotalMinutesAt(1), 180);
    expect(controller.schedule.weeklyTotalMinutesAt(0), 120);
    expect(controller.schedule.weeklyTotalMinutesAt(1), 450);
  });

  test('v2 remaining/editable cap excludes locked week 1', () {
    final TimeSetupController controller = TimeSetupController.v2NextWeek(
      previousWeek: TimeScheduleMock.sampleV2PreviousWeek,
    );

    expect(controller.lockedPastWeekMinutes, 15 * 60);
    expect(controller.weeklyDistributionCapMinutes, (45 * 60) + 30);
    expect(controller.weeklyDistributionCapHours, 45);
    expect(controller.weeklyDistributionCapRemainderMinutes, 30);
    expect(controller.editableWeeklyTotalMinutes, 0);
    expect(controller.editableWeeklyRemainingMinutes, (45 * 60) + 30);
    expect(controller.canProceedToStep3, isFalse);

    controller.setWeeklyTotal(hours: 10, minutes: 0, weekIndex: 1);

    expect(controller.editableWeeklyTotalMinutes, 10 * 60);
    expect(controller.editableWeeklyRemainingMinutes, (35 * 60) + 30);
    expect(controller.canProceedToStep3, isFalse);
  });

  test('auto-distribute splits editable remaining weeks evenly in v2', () {
    final TimeSetupController controller = TimeSetupController.v2NextWeek(
      previousWeek: TimeScheduleMock.sampleV2PreviousWeek,
    );

    controller.autoDistributeWeeklyTotals();

    expect(controller.schedule.weeklyTotalMinutesAt(0), 15 * 60);
    expect(controller.schedule.weeklyTotalMinutesAt(1), 15 * 60);
    expect(controller.schedule.weeklyTotalMinutesAt(2), 15 * 60);
    expect(controller.schedule.weeklyTotalMinutesAt(3), (15 * 60) + 30);
    expect(controller.editableWeeklyRemainingMinutes, 0);
    expect(controller.canProceedToStep3, isTrue);
  });

  test('v1 can proceed to step 3 when all four weeks are filled', () {
    final TimeSetupController controller = TimeSetupController(
      initial: scheduleWith(
        weeklyMinutes: const <int>[60, 60, 60, 60],
        monthlyBudgetMinutes: 4 * 60,
      ),
    );

    expect(controller.canProceedToStep3, isTrue);

    controller.setWeeklyTotal(hours: 0, minutes: 0, weekIndex: 2);

    expect(controller.canProceedToStep3, isFalse);
  });

  test('v1 cannot proceed without a parent monthly budget', () {
    final TimeSetupController controller = TimeSetupController(
      initial: scheduleWith(weeklyMinutes: const <int>[60, 60, 60, 60]),
    );

    expect(controller.weeklyDistributionCapMinutes, 0);
    expect(controller.editableWeeklyTotalMinutes, 4 * 60);
    expect(controller.canProceedToStep3, isFalse);
  });

  test('v1 weekly distribution may be below parent monthly budget', () {
    final TimeSetupController controller = TimeSetupController(
      initial: scheduleWith(
        weeklyMinutes: const <int>[120, 120, 720, 1380],
        monthlyBudgetMinutes: 116 * 60,
      ),
    );

    expect(controller.weeklyDistributionCapMinutes, 116 * 60);
    expect(controller.editableWeeklyTotalMinutes, 39 * 60);
    expect(controller.canProceedToStep3, isTrue);

    controller.autoDistributeWeeklyTotals();

    expect(controller.schedule.weeklyTotalMinutesAt(0), 29 * 60);
    expect(controller.schedule.weeklyTotalMinutesAt(1), 29 * 60);
    expect(controller.schedule.weeklyTotalMinutesAt(2), 29 * 60);
    expect(controller.schedule.weeklyTotalMinutesAt(3), 29 * 60);
    expect(controller.editableWeeklyTotalMinutes, 116 * 60);
    expect(controller.canProceedToStep3, isTrue);
  });

  test('daily allocation validation counts time once per selected weekday', () {
    final TimeSetupController controller = TimeSetupController(
      initial: scheduleWith(
        weeklyMinutes: const <int>[600, 60, 60, 60],
        allocations: const <DayAllocation>[
          DayAllocation(
            daysLabel: '화',
            weekdayIndices: <int>[1],
            hours: 2,
            minutes: 0,
          ),
          DayAllocation(
            daysLabel: '수,목,금,토',
            weekdayIndices: <int>[2, 3, 4, 5],
            hours: 2,
            minutes: 0,
          ),
        ],
      ),
    );

    expect(controller.schedule.allocatedMinutes, 10 * 60);
    expect(controller.allocationDeltaMinutes, 0);
    expect(controller.isAllocationBalanced, isTrue);
  });

  test('submit does not call repository when draft is not valid', () async {
    final _RecordingTimeSetupRepository repository =
        _RecordingTimeSetupRepository();
    final TimeSetupController controller = TimeSetupController(
      initial: scheduleWith(
        weeklyMinutes: const <int>[60, 60, 60, 60],
        monthlyBudgetMinutes: 4 * 60,
        allocations: const <DayAllocation>[
          DayAllocation(
            daysLabel: '월',
            weekdayIndices: <int>[0],
            hours: 0,
            minutes: 30,
          ),
        ],
      ),
      repository: repository,
    );

    expect(controller.canProceedToStep3, isTrue);
    expect(controller.isAllocationBalanced, isFalse);

    await controller.submit();

    expect(repository.saveCount, 0);
    expect(controller.step, TimeSetupStep.intro);
    expect(controller.errorMessage, contains('다시 확인'));
  });

  test('adding time splits and regroups weekdays by resulting total', () {
    final TimeSetupController controller = TimeSetupController(
      initial: scheduleWith(
        weeklyMinutes: const <int>[480, 60, 60, 60],
        allocations: const <DayAllocation>[
          DayAllocation(
            daysLabel: '화,수,목',
            weekdayIndices: <int>[1, 2, 3],
            hours: 2,
            minutes: 0,
          ),
        ],
      ),
    );

    controller.addDailyAllocation(
      const DayAllocation(
        daysLabel: '화',
        weekdayIndices: <int>[1],
        hours: 0,
        minutes: 30,
      ),
    );

    expect(controller.schedule.dayAllocations, hasLength(2));
    expect(controller.schedule.dayAllocations[0].daysLabel, '화');
    expect(controller.schedule.dayAllocations[0].hours, 2);
    expect(controller.schedule.dayAllocations[0].minutes, 30);
    expect(controller.schedule.dayAllocations[1].daysLabel, '수,목');
    expect(controller.schedule.dayAllocations[1].hours, 2);
    expect(controller.schedule.dayAllocations[1].minutes, 0);

    controller.addDailyAllocation(
      const DayAllocation(
        daysLabel: '금',
        weekdayIndices: <int>[4],
        hours: 2,
        minutes: 0,
      ),
    );

    expect(controller.schedule.dayAllocations, hasLength(2));
    expect(controller.schedule.dayAllocations[0].daysLabel, '화');
    expect(controller.schedule.dayAllocations[1].daysLabel, '수,목,금');
  });
}

class _RecordingTimeSetupRepository implements TimeSetupRepository {
  int saveCount = 0;

  @override
  Future<Result<TimeSchedule?>> fetchCurrentSchedule() async =>
      Result<TimeSchedule?>.success(null);

  @override
  Future<Result<TimeSchedule>> fetchPreviousWeekSchedule() async =>
      Result<TimeSchedule>.success(TimeScheduleMock.empty);

  @override
  Future<Result<void>> saveSchedule(TimeSchedule schedule) async {
    saveCount += 1;
    return Result<void>.success(null);
  }
}
