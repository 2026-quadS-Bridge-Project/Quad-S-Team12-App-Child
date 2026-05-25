import 'package:flutter/material.dart';

import '../../../../core/services/calendar_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/buttons/bridge_pill_icon_button.dart';
import '../../../../core/widgets/icons/bridge_stepper_pills.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../../../core/widgets/layout/bridge_day_row.dart';
import '../../../../core/widgets/layout/bridge_step_header.dart';
import '../../../../core/widgets/layout/bridge_total_time_card.dart';
import '../../../../core/widgets/mixins/async_error_listener.dart';
import '../../data/models/time_schedule.dart';
import '../../state/time_setup_controller.dart';
import '../../state/time_setup_scope.dart';

/// Step 3 review screen ("완성" / `695:11487`).
///
/// Identical layout to [DailyTimeSetupPage] in its valid (all-green) state:
/// the delta banner is omitted because the weekly cap matches the sum of all
/// day allocations, and the primary CTA is enabled to submit the plan.
///
/// Reuses the wizard's shared [TimeSetupScope] for both reads (week total,
/// day allocations) and writes (`submit`, back navigation to
/// [TimeSetupStep.dailyAllocation]).
class TimeSetupReviewPage extends StatefulWidget {
  const TimeSetupReviewPage({super.key});

  @override
  State<TimeSetupReviewPage> createState() => _TimeSetupReviewPageState();
}

class _TimeSetupReviewPageState extends State<TimeSetupReviewPage>
    with AsyncErrorListenerMixin<TimeSetupReviewPage> {
  static const double _sectionHeaderGap = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Wizard root re-injects the controller through TimeSetupScope on each
    // dependency change; bindAsyncErrorListener is idempotent for the same
    // instance and auto-detaches the previous one if the scope ever swaps.
    bindAsyncErrorListener(TimeSetupScope.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final controller = TimeSetupScope.of(context);
    final schedule = controller.schedule;
    final String monthLabel = createCalendarService().currentMonthLabel();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BridgeAppBar(
        title: '시간 설정',
        onBack: () => controller.goToStep(TimeSetupStep.dailyAllocation),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.pageHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Center(
                        child: BridgeStepperPills(
                          currentStep: controller.stepIndex,
                          totalSteps: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const BridgeStepHeader(
                        step: 3,
                        title: '이번주 일간 시간 설정',
                        description: '거의 다 왔어요!\n내가 설정한 이번주의 시간을 일별로 분배해요.',
                      ),
                      const SizedBox(height: AppTokens.itemGap),
                      BridgeTotalTimeCard(
                        variant: BridgeTotalTimeCardVariant.compact,
                        title:
                            '$monthLabel ${controller.currentWeekIndex + 1}주차',
                        hours: controller.currentWeekTotalHours,
                        minutes: controller.currentWeekTotalRemainderMinutes,
                      ),
                      const SizedBox(height: AppTokens.sectionGap),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '일별 시간 분배',
                            style: AppTypography.heading2Bold.copyWith(
                              color: AppColors.gray800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: BridgePillIconButton(
                                label: '스케줄 보기',
                                trailingIcon: Icons.arrow_forward,
                                variant: BridgePillVariant.tonal,
                                onPressed: () =>
                                    _openSchedulePreview(context, schedule),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: _sectionHeaderGap),
                      for (
                        int index = 0;
                        index < schedule.dayAllocations.length;
                        index++
                      ) ...[
                        BridgeDayRow(
                          daysLabel: schedule.dayAllocations[index].daysLabel,
                          hours: schedule.dayAllocations[index].hours,
                          minutes: schedule.dayAllocations[index].minutes,
                          showPencil: false,
                        ),
                        if (index < schedule.dayAllocations.length - 1)
                          const SizedBox(height: AppTokens.mediumGap),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              BridgeButton(
                label: '다음',
                variant: BridgeButtonVariant.primary,
                size: BridgeButtonSize.large,
                fullWidth: true,
                onPressed: controller.isSaving ? null : controller.submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSchedulePreview(
    BuildContext context,
    TimeSchedule schedule,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.bottomSheetTopRadius),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '스케줄 보기',
                  style: AppTypography.heading2Bold.copyWith(
                    color: AppColors.gray800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '등록한 사용 가능 시간을 다시 확인해요.',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                const SizedBox(height: 16),
                for (int weekday = 0; weekday < _weekdayNames.length; weekday++)
                  _ScheduleSummaryRow(
                    dayLabel: _weekdayNames[weekday],
                    selectedHours: schedule.allowedHours
                        .where((HourCell cell) => cell.weekday == weekday)
                        .length,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

const List<String> _weekdayNames = <String>['월', '화', '수', '목', '금', '토', '일'];

class _ScheduleSummaryRow extends StatelessWidget {
  const _ScheduleSummaryRow({
    required this.dayLabel,
    required this.selectedHours,
  });

  final String dayLabel;
  final int selectedHours;

  @override
  Widget build(BuildContext context) {
    final bool hasHours = selectedHours > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(AppTokens.dialogRadius),
        ),
        child: Row(
          children: <Widget>[
            Text(
              dayLabel,
              style: AppTypography.headlineSemiBold.copyWith(
                color: hasHours ? AppColors.gray800 : AppColors.gray400,
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: AppColors.gray200),
            const SizedBox(width: 10),
            Text(
              hasHours
                  ? '${selectedHours.toString().padLeft(2, '0')}시간'
                  : '등록 없음',
              style: AppTypography.labelSemiBold.copyWith(
                color: hasHours ? AppColors.gray800 : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
