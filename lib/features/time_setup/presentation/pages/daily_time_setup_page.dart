import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/buttons/bridge_pill_icon_button.dart';
import '../../../../core/widgets/feedback/bridge_delta_banner.dart';
import '../../../../core/widgets/icons/bridge_stepper_pills.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../../../core/widgets/layout/bridge_day_row.dart';
import '../../../../core/widgets/layout/bridge_step_header.dart';
import '../../../../core/widgets/layout/bridge_total_time_card.dart';
import '../../../../core/widgets/pickers/bridge_time_alloc_bottom_sheet.dart';
import '../../data/models/time_schedule.dart';
import '../../state/time_setup_controller.dart';
import '../../state/time_setup_scope.dart';

/// Step 3 of the initial 시간 설정 wizard — child distributes the weekly
/// budget across the 7 days via [BridgeTimeAllocBottomSheet].
///
/// Spec: docs/figma-specs/08b-time-v1-daily.md (frames 695:9743 / 11096) +
/// docs/figma-specs/08c-time-v1-errors-done.md (over / under variants).
class DailyTimeSetupPage extends StatelessWidget {
  const DailyTimeSetupPage({super.key});

  static const String _weekdayLabels = '월화수목금토일';
  static const double _pagePadding = 24;
  // Per Figma 08b/08c there is no hard cap on allocation count; the
  // limit is implicit (7 weekdays minus already-claimed days). Allow up
  // to 7 so all 7 weekdays can be claimed via single-day allocations.
  static const int _maxAllocations = 7;

  /// Section label shown above the read-only weekly total card. Per Figma
  /// 08b 695-9743 / 08c 695:10675 the label is the current 주차 (e.g.
  /// `2월 1주차`). The wizard has no month/week metadata yet, so fall back
  /// to the first-week label until a calendar source is wired.
  // TODO(backend): source month + 주차 from a calendar service.
  static const String _weekLabel = '2월 1주차';

  @override
  Widget build(BuildContext context) {
    final controller = TimeSetupScope.of(context);
    final schedule = controller.schedule;

    final int deltaMin = schedule.deltaMinutes;
    final int absDelta = deltaMin.abs();
    final int deltaHrs = absDelta ~/ 60;
    final int deltaMinsOnly = absDelta % 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BridgeAppBar(
        title: '시간 설정',
        onBack: () => controller.goToStep(TimeSetupStep.weeklyTotal),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: BridgeStepperPills(currentStep: 3, totalSteps: 3),
              ),
              const SizedBox(height: 24),
              // Title + description verbatim per Figma 08b 695-9743 and 08c
              // 695:10675 — `이번주 일간 시간 설정` / `거의 다 왔어요!` /
              // `내가 설정한 이번주의 시간을 일별로 분배해요.`
              const BridgeStepHeader(
                step: 3,
                title: '이번주 일간 시간 설정',
                description: '거의 다 왔어요!\n내가 설정한 이번주의 시간을 일별로 분배해요.',
              ),
              const SizedBox(height: 16),
              // Section label (`2월 1주차`) + read-only outlined total card
              // per Figma 08b §"week time" / 08c §"week time block". Uses
              // the same BridgeTotalTimeCard widget as Step 2 so the
              // anatomy matches across the wizard.
              Text(
                _weekLabel,
                style: AppTypography.heading2Bold.copyWith(
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: 12),
              BridgeTotalTimeCard(
                hours: controller.schedule.weeklyTotalHours,
                minutes: controller.schedule.weeklyTotalMinutes,
              ),
              if (controller.showPastWeekDim) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Spec §v2-6 order: `스케줄 보기` first, `사용리포트 보기`
                    // second. Both pills use the tonal variant (primaryLight
                    // bg + primary text) per spec — never ghost.
                    BridgePillIconButton(
                      label: '스케줄 보기',
                      trailingIcon: Icons.arrow_forward,
                      variant: BridgePillVariant.tonal,
                      onPressed: () =>
                          _openReferenceModal(context, title: '지난 주 스케줄'),
                    ),
                    const SizedBox(width: 8),
                    BridgePillIconButton(
                      label: '사용리포트 보기',
                      trailingIcon: Icons.arrow_forward,
                      variant: BridgePillVariant.tonal,
                      onPressed: () =>
                          _openReferenceModal(context, title: '지난 주 사용리포트'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: _DayRowsFrame(
                  isOver: controller.isOverBudget,
                  isUnder: controller.isUnderBudget,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final a in schedule.dayAllocations)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BridgeDayRow(
                            daysLabel: a.daysLabel,
                            hours: a.hours,
                            minutes: a.minutes,
                            onEdit: () => _openSheet(context, initial: a),
                          ),
                        ),
                      if (schedule.dayAllocations.length < _maxAllocations)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          // 40×40 white circular `+` button per Figma 08b
                          // §"Daily Distribution Container" — the only
                          // affordance that opens the allocation bottom
                          // sheet. Centered between the last day row and
                          // the CTA.
                          child: Center(
                            child: _AddCircleButton(
                              onTap: () => _openSheet(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (controller.isOverBudget) ...[
                BridgeDeltaBanner.over(hours: deltaHrs, minutes: deltaMinsOnly),
                const SizedBox(height: 12),
              ] else if (controller.isUnderBudget) ...[
                BridgeDeltaBanner.under(
                  hours: deltaHrs,
                  minutes: deltaMinsOnly,
                ),
                const SizedBox(height: 12),
              ],
              BridgeButton(
                label: '다음',
                variant: BridgeButtonVariant.primary,
                size: BridgeButtonSize.large,
                fullWidth: true,
                onPressed: controller.isAllocationBalanced
                    ? () => controller.goToStep(TimeSetupStep.review)
                    : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens [BridgeTimeAllocBottomSheet] and, on a non-null result, upserts
  /// the corresponding [DayAllocation] into the controller.
  Future<void> _openSheet(
    BuildContext context, {
    DayAllocation? initial,
  }) async {
    final controller = TimeSetupScope.of(context);

    final Set<int> initialDays =
        initial?.weekdayIndices.toSet() ?? const <int>{};

    final TimeAllocPick? pick = await BridgeTimeAllocBottomSheet.show(
      context,
      initialDays: initialDays,
      initialHours: initial?.hours ?? 0,
      initialMinutes: initial?.minutes ?? 0,
    );

    if (pick == null) return;

    final List<int> indices = pick.days.toList()..sort();
    final String label = indices.map((i) => _weekdayLabels[i]).join(',');

    controller.upsertAllocation(
      DayAllocation(
        daysLabel: label,
        weekdayIndices: indices,
        hours: pick.hours,
        minutes: pick.minutes,
      ),
    );
  }

  /// Opens an in-flow reference modal (bottom sheet) — does NOT push a new
  /// route. Per spec §v2-6: tapping `스케줄 보기` / `사용리포트 보기` must
  /// surface prior-week reference data without exiting the wizard
  /// (`context.push('/child-home/...')` would destroy the wizard stack).
  /// TODO: in-flow reference modal — render embedded report/schedule preview.
  Future<void> _openReferenceModal(
    BuildContext context, {
    required String title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTypography.headlineBold.copyWith(
                    color: AppColors.gray800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '미리보기는 곧 추가될 예정이에요.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Wraps the day-rows ListView in a 1.2px rounded-8 border when the user is
/// over/under budget. Per spec §v2-6/v2-7 the error frame uses
/// `destructiveBorderSoft` (over) / `primary` (under); the chip below the
/// frame remains the `BridgeDeltaBanner`. When neither condition holds the
/// wrapper is a transparent passthrough so layout is unaffected.
class _DayRowsFrame extends StatelessWidget {
  const _DayRowsFrame({
    required this.child,
    required this.isOver,
    required this.isUnder,
  });

  final Widget child;
  final bool isOver;
  final bool isUnder;

  @override
  Widget build(BuildContext context) {
    if (!isOver && !isUnder) return child;
    final Color borderColor = isOver
        ? AppColors.destructiveBorderSoft
        : AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }
}

/// 40×40 circular `+` button — the only affordance that opens
/// [BridgeTimeAllocBottomSheet] per Figma 08b 695-9743 §"Daily
/// Distribution Container": "Round `+` button (40×40, white circle w/
/// border via Ellipse3, plus icon stroke 2 primary). Centered. This is
/// the only action that opens the bottom sheet."
class _AddCircleButton extends StatelessWidget {
  const _AddCircleButton({required this.onTap});

  final VoidCallback onTap;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '시간 분배 추가',
      child: Material(
        color: AppColors.primaryLight,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: _size,
            height: _size,
            child: Icon(Icons.add_rounded, size: 28, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
