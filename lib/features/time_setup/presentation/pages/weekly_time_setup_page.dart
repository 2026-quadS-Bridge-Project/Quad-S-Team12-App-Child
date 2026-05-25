import 'package:flutter/material.dart';

import 'package:bridge_k/core/services/calendar_service.dart';
import 'package:bridge_k/core/theme/app_colors.dart';
import 'package:bridge_k/core/theme/app_typography.dart';
import 'package:bridge_k/core/widgets/buttons/bridge_button.dart';
import 'package:bridge_k/core/widgets/icons/bridge_stepper_pills.dart';
import 'package:bridge_k/core/widgets/layout/bridge_app_bar.dart';
import 'package:bridge_k/core/widgets/layout/bridge_step_header.dart';
import 'package:bridge_k/core/widgets/layout/bridge_total_time_card.dart';
import 'package:bridge_k/core/widgets/layout/bridge_week_row.dart';
import 'package:bridge_k/core/widgets/pickers/bridge_time_bottom_sheet.dart';

import '../../state/time_setup_controller.dart';
import '../../state/time_setup_scope.dart';

/// Step 2 of 3 in the initial time-setup wizard.
///
/// Lets the child set their **weekly total** phone usage time. Tapping the
/// `이번 주` row opens a [BridgeTimeBottomSheet] that returns a
/// [TimeOfDayPick]; on confirm the value is pushed back into
/// [TimeSetupController.setWeeklyTotal]. The `다음` CTA enables once the
/// total is greater than zero and advances to
/// [TimeSetupStep.dailyAllocation]. The back chevron rewinds to
/// [TimeSetupStep.scheduleRegister].
///
/// Spec: docs/figma-specs/08a-time-v1-entry-weekly.md
/// (frames `695:11870` empty, `695:8694` filled)
class WeeklyTimeSetupPage extends StatelessWidget {
  const WeeklyTimeSetupPage({super.key});

  static const double _horizontalPadding = 24;
  static const double _topPadding = 16;
  static const double _bottomPadding = 24;
  static const double _sectionGap = 24;
  static const double _weekRowGap = 8;

  @override
  Widget build(BuildContext context) {
    final TimeSetupController controller = TimeSetupScope.of(context);
    final CalendarService calendar = createCalendarService();
    final String monthLabel = calendar.currentMonthLabel();
    final String weekLabel = calendar.currentWeekLabel();
    final bool canProceed = controller.canProceedToStep3;
    final int totalTimeMinutes = _displayedTotalMinutes(controller);
    final _TimeParts totalTime = _TimeParts.fromMinutes(totalTimeMinutes);
    final bool canAutoCalculate = _canAutoCalculate(
      controller,
      totalMinutes: totalTimeMinutes,
    );
    final String totalTimeTitle = controller.showPastWeekDim
        ? '$monthLabel 잔여 시간'
        : '$monthLabel 총 사용 시간';
    final String headerDescription = switch (controller.mode) {
      TimeSetupMode.v2NextWeek =>
        '$weekLabel에 사용하고 남은 시간으로\n주별 시간 분배를 다시 설정해요!',
      TimeSetupMode.v1Initial => '부모님이 부여한 이번 달 총 사용 시간을\n주별로 분배해요!',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BridgeAppBar(
        title: '시간 설정',
        onBack: () => controller.goToStep(TimeSetupStep.scheduleRegister),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _horizontalPadding,
            _topPadding,
            _horizontalPadding,
            _bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Center(
                child: BridgeStepperPills(currentStep: 2, totalSteps: 3),
              ),
              const SizedBox(height: 24),
              // Title + description verbatim per Figma 08a 695:11870 nodes
              // 695:11880 (title) and 695:11883 (2-line description). Spec
              // 09-time-v2 §v2-3 overrides the description for v2 next-week
              // edits, branched via [controller.mode] above.
              BridgeStepHeader(
                step: 2,
                title: '주별 시간 분배',
                description: headerDescription,
              ),
              const SizedBox(height: 24),
              BridgeTotalTimeCard(
                variant: BridgeTotalTimeCardVariant.compact,
                title: totalTimeTitle,
                hours: totalTime.hours,
                minutes: totalTime.minutes,
              ),
              const SizedBox(height: _sectionGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '주별 시간 분배',
                    style: AppTypography.heading2Bold.copyWith(
                      color: AppColors.gray800,
                    ),
                  ),
                  _AutoCalculateButton(
                    onPressed: canAutoCalculate
                        ? () => _handleAutoCalculate(controller)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // v2 (next-week edit): row 1 is the locked historical `1주차`
              // sourced from `controller.previousWeek` (opacity 0.2, not
              // tappable). Rows 2/3/4 are editable. v1 (initial setup):
              // all 4 rows editable. Per spec §v2-3, row count is always 4.
              if (controller.showPastWeekDim) ...<Widget>[
                BridgeWeekRow(
                  weekLabel: '1주차',
                  hours: _pastWeekTime(controller).hours,
                  minutes: _pastWeekTime(controller).minutes,
                  onTap: null,
                  isPast: true,
                ),
                const SizedBox(height: _weekRowGap),
                for (int i = 1; i < 4; i++) ...<Widget>[
                  BridgeWeekRow(
                    weekLabel: '${i + 1}주차',
                    hours: _weekTime(controller, i).hours,
                    minutes: _weekTime(controller, i).minutes,
                    onTap: () =>
                        _openTimeSheet(context, controller, weekIndex: i),
                  ),
                  if (i < 3) const SizedBox(height: _weekRowGap),
                ],
              ] else
                for (int i = 0; i < 4; i++) ...<Widget>[
                  BridgeWeekRow(
                    weekLabel: '${i + 1}주차',
                    hours: _weekTime(controller, i).hours,
                    minutes: _weekTime(controller, i).minutes,
                    onTap: () =>
                        _openTimeSheet(context, controller, weekIndex: i),
                  ),
                  if (i < 3) const SizedBox(height: _weekRowGap),
                ],
              const Spacer(),
              BridgeButton(
                label: '다음',
                variant: BridgeButtonVariant.primary,
                size: BridgeButtonSize.large,
                fullWidth: true,
                onPressed: canProceed
                    ? () => controller.goToStep(TimeSetupStep.dailyAllocation)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTimeSheet(
    BuildContext context,
    TimeSetupController controller, {
    int? weekIndex,
  }) async {
    // Seed the bottom sheet with the targeted week's current value when a
    // specific index is supplied; otherwise fall back to the aggregate.
    final _TimeParts initialTime = weekIndex != null
        ? _weekTime(controller, weekIndex)
        : _TimeParts.fromMinutes(_displayedTotalMinutes(controller));

    final TimeOfDayPick? pick = await BridgeTimeBottomSheet.show(
      context,
      initialHours: initialTime.hours,
      initialMinutes: initialTime.minutes,
      // Weekly totals can exceed a single day, so widen the hour wheel.
      maxHours: 168,
    );
    if (pick == null) return;
    controller.setWeeklyTotal(
      hours: pick.hours,
      minutes: pick.minutes,
      weekIndex: weekIndex,
    );
  }

  static const List<int> _v2EditableWeekIndices = <int>[1, 2, 3];

  int _displayedTotalMinutes(TimeSetupController controller) {
    if (!controller.showPastWeekDim) {
      return controller.schedule.weeklyTotalCapMinutes;
    }

    return controller.weeklyDistributionCapMinutes;
  }

  _TimeParts _pastWeekTime(TimeSetupController controller) {
    final int minutes =
        controller.previousWeek?.weeklyTotalMinutesAt(0) ??
        controller.schedule.weeklyTotalMinutesAt(0);
    return _TimeParts.fromMinutes(minutes);
  }

  _TimeParts _weekTime(TimeSetupController controller, int weekIndex) {
    return _TimeParts.fromMinutes(
      controller.schedule.weeklyTotalMinutesAt(weekIndex),
    );
  }

  bool _canAutoCalculate(
    TimeSetupController controller, {
    required int totalMinutes,
  }) {
    if (!controller.showPastWeekDim || totalMinutes <= 0) {
      return false;
    }

    final List<int> distributedMinutes = _distributedEditableWeekMinutes(
      totalMinutes,
      _v2EditableWeekIndices.length,
    );

    for (int i = 0; i < _v2EditableWeekIndices.length; i++) {
      final int weekIndex = _v2EditableWeekIndices[i];
      if (controller.schedule.weeklyTotalMinutesAt(weekIndex) !=
          distributedMinutes[i]) {
        return true;
      }
    }
    return false;
  }

  void _handleAutoCalculate(TimeSetupController controller) {
    controller.autoDistributeWeeklyTotals();
  }

  List<int> _distributedEditableWeekMinutes(int totalMinutes, int weekCount) {
    if (weekCount <= 0) {
      return const <int>[];
    }

    final int baseMinutes = ((totalMinutes ~/ weekCount) ~/ 60) * 60;
    final int remainingMinutes = totalMinutes - (baseMinutes * weekCount);

    return <int>[
      for (int i = 0; i < weekCount; i++)
        i == weekCount - 1 ? baseMinutes + remainingMinutes : baseMinutes,
    ];
  }
}

class _AutoCalculateButton extends StatelessWidget {
  const _AutoCalculateButton({required this.onPressed});

  final VoidCallback? onPressed;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final Color background = _enabled
        ? AppColors.primaryLight
        : AppColors.gray150;
    final Color foreground = _enabled ? AppColors.primary : AppColors.gray300;
    final BorderRadius borderRadius = BorderRadius.circular(7);

    return Semantics(
      button: true,
      enabled: _enabled,
      label: '자동계산',
      child: Material(
        color: background,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: Container(
            height: 31,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calculate_outlined, size: 16, color: foreground),
                const SizedBox(width: 5),
                Text(
                  '자동계산',
                  style: AppTypography.labelMedium.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeParts {
  const _TimeParts({required this.hours, required this.minutes});

  factory _TimeParts.fromMinutes(int totalMinutes) {
    final int clamped = totalMinutes.clamp(0, 1 << 31);
    return _TimeParts(hours: clamped ~/ 60, minutes: clamped % 60);
  }

  final int hours;
  final int minutes;
}
