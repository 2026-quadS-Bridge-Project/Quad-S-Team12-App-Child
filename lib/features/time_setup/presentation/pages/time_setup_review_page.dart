import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/icons/bridge_stepper_pills.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../../../core/widgets/layout/bridge_day_row.dart';
import '../../../../core/widgets/layout/bridge_step_header.dart';
import '../../../../core/widgets/layout/bridge_total_time_card.dart';
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
class TimeSetupReviewPage extends StatelessWidget {
  const TimeSetupReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TimeSetupScope.of(context);
    final schedule = controller.schedule;

    return Scaffold(
      backgroundColor: AppColors.gray050,
      appBar: BridgeAppBar(
        title: '시간 설정',
        onBack: () => controller.goToStep(TimeSetupStep.dailyAllocation),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.pageHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // All three pills primary — Figma "완성" frame renders the
              // reviewed step 3 as fully active.
              const Center(
                child: BridgeStepperPills(currentStep: 3, totalSteps: 3),
              ),
              const SizedBox(height: 28),
              // Title + description verbatim per Figma 08c 695:11487 (review
              // state shares the same titleset as Step 3 — see spec §"Texts
              // (verbatim)": "Same as the error frames minus the banner").
              const BridgeStepHeader(
                step: 3,
                title: '이번주 일간 시간 설정',
                description: '거의 다 왔어요!\n내가 설정한 이번주의 시간을 일별로 분배해요.',
              ),
              const SizedBox(height: AppTokens.sectionGap),
              BridgeTotalTimeCard(
                title: '주별 총 사용시간',
                hours: schedule.weeklyTotalHours,
                minutes: schedule.weeklyTotalMinutes,
              ),
              const SizedBox(height: AppTokens.itemGap),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: schedule.dayAllocations.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTokens.mediumGap),
                  itemBuilder: (context, index) {
                    final alloc = schedule.dayAllocations[index];
                    return BridgeDayRow(
                      daysLabel: alloc.daysLabel,
                      hours: alloc.hours,
                      minutes: alloc.minutes,
                      // Read-only review: no edit handler, no pencil.
                      // Banner omitted because state is balanced.
                      showPencil: false,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTokens.itemGap),
              BridgeButton(
                label: '다음',
                variant: BridgeButtonVariant.primary,
                size: BridgeButtonSize.large,
                fullWidth: true,
                onPressed: controller.submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
