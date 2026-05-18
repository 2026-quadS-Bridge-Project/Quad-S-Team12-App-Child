import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final TimeSetupController controller = TimeSetupScope.of(context);
    final bool canProceed = controller.canProceedToStep3;

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
              // 695:11880 (title) and 695:11883 (2-line description).
              const BridgeStepHeader(
                step: 2,
                title: '주별 시간 분배',
                description: '부모님이 부여한 이번 달 총 사용 시간을\n주별로 분배해요!',
              ),
              const SizedBox(height: 24),
              BridgeTotalTimeCard(
                title: '주별 총 사용시간',
                hours: controller.schedule.totalWeeklyHours,
                minutes: controller.schedule.totalWeeklyMinutes,
                // 자동계산 is a Figma-spec'd affordance (Button/Blue/Light
                // chip that splits the monthly cap evenly across the 4
                // weekly totals — see 08a §"자동계산 icon button"). The
                // distribution logic is not yet wired, so render as a
                // disabled button with a Tooltip explaining unavailability
                // instead of a misleading enabled affordance.
                // TODO(backend): implement auto-distribute (split
                // totalWeeklyCapMinutes / 4 into the 4 weeklyTotals).
                trailing: Tooltip(
                  message: '곧 사용 가능한 기능이에요',
                  child: TextButton(
                    onPressed: null,
                    child: Text(
                      '자동계산',
                      style: AppTypography.labelBold.copyWith(
                        color: AppColors.gray300,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // v2 (next-week edit): row 1 is the locked historical `1주차`
              // sourced from `controller.previousWeek` (opacity 0.2, not
              // tappable). Rows 2/3/4 are editable. v1 (initial setup):
              // all 4 rows editable. Per spec §v2-3, row count is always 4.
              if (controller.showPastWeekDim) ...<Widget>[
                BridgeWeekRow(
                  weekLabel: '1주차',
                  hours: controller.previousWeek?.weeklyTotals[0].hours ?? 0,
                  minutes:
                      controller.previousWeek?.weeklyTotals[0].minutes ?? 0,
                  onTap: null,
                  isPast: true,
                ),
                const SizedBox(height: 12),
                for (int i = 1; i < 4; i++) ...<Widget>[
                  BridgeWeekRow(
                    weekLabel: '${i + 1}주차',
                    hours: controller.schedule.weeklyTotals[i].hours,
                    minutes: controller.schedule.weeklyTotals[i].minutes,
                    onTap: () =>
                        _openTimeSheet(context, controller, weekIndex: i),
                  ),
                  if (i < 3) const SizedBox(height: 12),
                ],
              ] else
                for (int i = 0; i < 4; i++) ...<Widget>[
                  BridgeWeekRow(
                    weekLabel: '${i + 1}주차',
                    hours: controller.schedule.weeklyTotals[i].hours,
                    minutes: controller.schedule.weeklyTotals[i].minutes,
                    onTap: () =>
                        _openTimeSheet(context, controller, weekIndex: i),
                  ),
                  if (i < 3) const SizedBox(height: 12),
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
    final int initialHours = weekIndex != null
        ? controller.schedule.weeklyTotals[weekIndex].hours
        : controller.schedule.totalWeeklyHours;
    final int initialMinutes = weekIndex != null
        ? controller.schedule.weeklyTotals[weekIndex].minutes
        : controller.schedule.totalWeeklyMinutes;

    final TimeOfDayPick? pick = await BridgeTimeBottomSheet.show(
      context,
      initialHours: initialHours,
      initialMinutes: initialMinutes,
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
}
