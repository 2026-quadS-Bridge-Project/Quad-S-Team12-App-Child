import 'package:flutter/material.dart';

import '../../../../core/services/calendar_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
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
  static const double _sectionGap = 32;

  @override
  Widget build(BuildContext context) {
    final controller = TimeSetupScope.of(context);
    final schedule = controller.schedule;
    // Section label shown above the read-only weekly total card. Per Figma
    // 08b 695-9743 / 08c 695:10675 the label is the current 주차 (e.g.
    // `2월 1주차`); the week index still comes from the controller so v2
    // renders the locked week's number.
    final String monthLabel = createCalendarService().currentMonthLabel();

    final int deltaMin = controller.allocationDeltaMinutes;
    final int absDelta = deltaMin.abs();
    final int deltaHrs = absDelta ~/ 60;
    final int deltaMinsOnly = absDelta % 60;
    final Widget? deltaBanner = controller.isOverBudget
        ? BridgeDeltaBanner.over(hours: deltaHrs, minutes: deltaMinsOnly)
        : controller.isUnderBudget
        ? BridgeDeltaBanner.under(hours: deltaHrs, minutes: deltaMinsOnly)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BridgeAppBar(
              title: '시간 설정',
              onBack: () => controller.goToStep(TimeSetupStep.weeklyTotal),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
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
                            // Title + description verbatim per Figma 08b
                            // 695-9743 and 08c 695:10675.
                            const BridgeStepHeader(
                              step: 3,
                              title: '이번주 일간 시간 설정',
                              description:
                                  '거의 다 왔어요!\n내가 설정한 이번주의 시간을 일별로 분배해요.',
                            ),
                            const SizedBox(height: 16),
                            // Week label (`2월 1주차`) + read-only weekly total.
                            // The actual week index comes from the controller so
                            // v2 renders `2주차`.
                            Text(
                              '$monthLabel ${controller.currentWeekIndex + 1}주차',
                              style: AppTypography.heading2Bold.copyWith(
                                color: AppColors.gray800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            BridgeTotalTimeCard(
                              variant: BridgeTotalTimeCardVariant.compact,
                              hours: controller.currentWeekTotalHours,
                              minutes:
                                  controller.currentWeekTotalRemainderMinutes,
                            ),
                            const SizedBox(height: _sectionGap),
                            _DailyAllocationSection(
                              allocations: schedule.dayAllocations,
                              isOver: controller.isOverBudget,
                              isUnder: controller.isUnderBudget,
                              showErrorFrame: controller.showPastWeekDim,
                              showAddButton: !controller.showPastWeekDim,
                              showScheduleAction: controller.showPastWeekDim,
                              showUsageReportAction: controller.showPastWeekDim,
                              onSchedulePressed: () => _openSchedulePreview(
                                context,
                                schedule: controller.showPastWeekDim
                                    ? controller.previousWeek ?? schedule
                                    : schedule,
                                isPastReference: controller.showPastWeekDim,
                              ),
                              onUsageReportPressed: () =>
                                  _openUsageReportPreview(
                                    context,
                                    previousWeek: controller.previousWeek,
                                  ),
                              onAdd: () => _openSheet(context),
                              onEdit: (DayAllocation allocation) =>
                                  _openSheet(context, initial: allocation),
                            ),
                            if (deltaBanner != null) ...[
                              const SizedBox(height: 12),
                              deltaBanner,
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
                      onPressed: controller.isAllocationBalanced
                          ? () => controller.goToStep(TimeSetupStep.review)
                          : null,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
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

    final DayAllocation allocation = DayAllocation(
      daysLabel: label,
      weekdayIndices: indices,
      hours: pick.hours,
      minutes: pick.minutes,
    );

    if (initial == null) {
      controller.addDailyAllocation(allocation);
    } else {
      controller.replaceDailyAllocation(
        original: initial,
        replacement: allocation,
      );
    }
  }

  /// Opens the read-only schedule reference in-flow — this deliberately avoids
  /// pushing a route so the wizard stack and draft allocation state stay put.
  Future<void> _openSchedulePreview(
    BuildContext context, {
    required TimeSchedule schedule,
    required bool isPastReference,
  }) {
    return _showReferenceSheet(
      context,
      child: _SchedulePreviewSheet(
        schedule: schedule,
        isPastReference: isPastReference,
      ),
    );
  }

  /// v2-only reference sheet for the previous week's daily allocation shape.
  /// v1 never exposes the `사용리포트 보기` action, preserving the initial setup
  /// flow while still giving v2 an in-flow historical hint.
  Future<void> _openUsageReportPreview(
    BuildContext context, {
    required TimeSchedule? previousWeek,
  }) {
    return _showReferenceSheet(
      context,
      child: _UsageReportPreviewSheet(previousWeek: previousWeek),
    );
  }

  Future<void> _showReferenceSheet(
    BuildContext context, {
    required Widget child,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.bottomSheetTopRadius),
        ),
      ),
      builder: (BuildContext sheetContext) {
        final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.84;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

const List<String> _weekdayNames = <String>['월', '화', '수', '목', '금', '토', '일'];

class _SchedulePreviewSheet extends StatelessWidget {
  const _SchedulePreviewSheet({
    required this.schedule,
    required this.isPastReference,
  });

  final TimeSchedule schedule;
  final bool isPastReference;

  @override
  Widget build(BuildContext context) {
    final int scheduledMinutes = schedule.allocatedMinutes;

    return _ReferenceSheetScaffold(
      title: isPastReference ? '지난 주 스케줄' : '스케줄 보기',
      subtitle: isPastReference
          ? '지난 주에 분배한 일별 사용 시간을 확인해요.'
          : '이번 주에 분배한 일별 사용 시간을 확인해요.',
      children: <Widget>[
        _ReferenceMetricRow(
          metrics: <_ReferenceMetric>[
            _ReferenceMetric(
              label: '총 분배',
              value: _formatMinutes(scheduledMinutes),
            ),
            _ReferenceMetric(
              label: '분배 그룹',
              value: '${schedule.dayAllocations.length}개',
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _ReferenceSectionTitle('요일별 사용 시간'),
        const SizedBox(height: 10),
        if (scheduledMinutes == 0)
          const _ReferenceEmptyState('등록된 스케줄이 아직 없어요.')
        else
          for (int weekday = 0; weekday < _weekdayNames.length; weekday++) ...[
            _ScheduleDayPreviewRow(
              dayLabel: _weekdayNames[weekday],
              minutes: _scheduledMinutesForWeekday(schedule, weekday),
            ),
            if (weekday < _weekdayNames.length - 1) const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _UsageReportPreviewSheet extends StatelessWidget {
  const _UsageReportPreviewSheet({required this.previousWeek});

  final TimeSchedule? previousWeek;

  @override
  Widget build(BuildContext context) {
    final List<DayAllocation> allocations =
        previousWeek?.dayAllocations ?? const <DayAllocation>[];
    final int totalUsedMinutes = previousWeek?.allocatedMinutes ?? 0;

    return _ReferenceSheetScaffold(
      title: '지난 주 사용리포트',
      subtitle: previousWeek == null
          ? '지난 주 기록을 불러오지 못했어요.'
          : '지난 주 일별 사용 시간을 보고 이번 주 분배를 조정해요.',
      children: <Widget>[
        _ReferenceMetricRow(
          metrics: <_ReferenceMetric>[
            _ReferenceMetric(
              label: '총 사용',
              value: _formatMinutes(totalUsedMinutes),
            ),
            _ReferenceMetric(label: '분배 그룹', value: '${allocations.length}개'),
          ],
        ),
        const SizedBox(height: 20),
        const _ReferenceSectionTitle('지난 주 일별 사용'),
        const SizedBox(height: 10),
        if (allocations.isEmpty)
          const _ReferenceEmptyState('지난 주 일별 사용 기록이 아직 없어요.')
        else
          for (int index = 0; index < allocations.length; index++) ...[
            _UsageAllocationPreviewRow(allocation: allocations[index]),
            if (index < allocations.length - 1) const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _ReferenceSheetScaffold extends StatelessWidget {
  const _ReferenceSheetScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          title,
          style: AppTypography.heading2Bold.copyWith(color: AppColors.gray800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTypography.labelMedium.copyWith(color: AppColors.gray500),
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }
}

class _ReferenceMetric {
  const _ReferenceMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _ReferenceMetricRow extends StatelessWidget {
  const _ReferenceMetricRow({required this.metrics});

  final List<_ReferenceMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int index = 0; index < metrics.length; index++) ...[
          Expanded(child: _ReferenceMetricTile(metric: metrics[index])),
          if (index < metrics.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ReferenceMetricTile extends StatelessWidget {
  const _ReferenceMetricTile({required this.metric});

  final _ReferenceMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppTokens.fieldRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            metric.label,
            style: AppTypography.captionMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineSemiBold.copyWith(
              color: AppColors.gray800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceSectionTitle extends StatelessWidget {
  const _ReferenceSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.headlineSemiBold.copyWith(color: AppColors.gray800),
    );
  }
}

class _ReferenceEmptyState extends StatelessWidget {
  const _ReferenceEmptyState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppTokens.fieldRadius),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.labelMedium.copyWith(color: AppColors.gray500),
      ),
    );
  }
}

class _ScheduleDayPreviewRow extends StatelessWidget {
  const _ScheduleDayPreviewRow({required this.dayLabel, required this.minutes});

  final String dayLabel;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final bool hasMinutes = minutes > 0;

    return _ReferenceTile(
      leading: dayLabel,
      value: hasMinutes ? _formatMinutes(minutes) : '00시간 00분',
      detail: hasMinutes ? '사용 시간' : '등록 없음',
      isMuted: !hasMinutes,
    );
  }
}

class _UsageAllocationPreviewRow extends StatelessWidget {
  const _UsageAllocationPreviewRow({required this.allocation});

  final DayAllocation allocation;

  @override
  Widget build(BuildContext context) {
    final int dayCount = allocation.weekdayIndices.length;
    final int groupTotalMinutes = allocation.totalAllocatedMinutes;

    return _ReferenceTile(
      leading: allocation.daysLabel,
      value: _formatMinutes(allocation.totalMinutes),
      detail: '$dayCount일 합계 ${_formatMinutes(groupTotalMinutes)}',
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({
    required this.leading,
    required this.value,
    required this.detail,
    this.isMuted = false,
  });

  final String leading;
  final String value;
  final String detail;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final Color contentColor = isMuted ? AppColors.gray400 : AppColors.gray800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppTokens.fieldRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 24, maxWidth: 104),
            child: Text(
              leading,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headlineSemiBold.copyWith(
                color: contentColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 22, color: AppColors.gray200),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSemiBold.copyWith(
                    color: contentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionMedium.copyWith(
                    color: isMuted ? AppColors.gray400 : AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyAllocationSection extends StatelessWidget {
  const _DailyAllocationSection({
    required this.allocations,
    required this.isOver,
    required this.isUnder,
    required this.showErrorFrame,
    required this.showAddButton,
    required this.showScheduleAction,
    required this.showUsageReportAction,
    required this.onSchedulePressed,
    required this.onUsageReportPressed,
    required this.onAdd,
    required this.onEdit,
  });

  final List<DayAllocation> allocations;
  final bool isOver;
  final bool isUnder;
  final bool showErrorFrame;
  final bool showAddButton;
  final bool showScheduleAction;
  final bool showUsageReportAction;
  final VoidCallback onSchedulePressed;
  final VoidCallback onUsageReportPressed;
  final VoidCallback onAdd;
  final ValueChanged<DayAllocation> onEdit;

  static const double _headerGap = 20;
  static const double _rowGap = 12;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DailyAllocationHeader(
          showScheduleAction: showScheduleAction,
          showUsageReportAction: showUsageReportAction,
          onSchedulePressed: onSchedulePressed,
          onUsageReportPressed: onUsageReportPressed,
        ),
        const SizedBox(height: _headerGap),
        _DayRowsFrame(
          isOver: isOver,
          isUnder: isUnder,
          showFrame: showErrorFrame,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final DayAllocation allocation in allocations) ...[
                BridgeDayRow(
                  daysLabel: allocation.daysLabel,
                  hours: allocation.hours,
                  minutes: allocation.minutes,
                  onEdit: () => onEdit(allocation),
                ),
                const SizedBox(height: _rowGap),
              ],
              if (showAddButton) ...[
                Center(child: _AddCircleButton(onTap: onAdd)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyAllocationHeader extends StatelessWidget {
  const _DailyAllocationHeader({
    required this.showScheduleAction,
    required this.showUsageReportAction,
    required this.onSchedulePressed,
    required this.onUsageReportPressed,
  });

  final bool showScheduleAction;
  final bool showUsageReportAction;
  final VoidCallback onSchedulePressed;
  final VoidCallback onUsageReportPressed;

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = <Widget>[
      if (showScheduleAction)
        BridgePillIconButton(
          label: '스케줄 보기',
          trailingIcon: Icons.arrow_forward,
          variant: BridgePillVariant.tonal,
          onPressed: onSchedulePressed,
        ),
      if (showUsageReportAction)
        BridgePillIconButton(
          label: '사용리포트 보기',
          trailingIcon: Icons.arrow_forward,
          variant: BridgePillVariant.tonal,
          onPressed: onUsageReportPressed,
        ),
    ];

    final Text title = Text(
      '일별 시간 분배',
      style: AppTypography.heading2Bold.copyWith(color: AppColors.gray800),
    );

    if (actions.isEmpty) {
      return Align(alignment: Alignment.centerLeft, child: title);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        title,
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              runAlignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ),
        ),
      ],
    );
  }
}

/// Wraps the day-rows region in a 1.2px rounded-8 border when the user is
/// over/under budget. Per spec §v2-6/v2-7 the error frame uses
/// `destructiveBorderSoft` (over) / `primary` (under); the chip below the
/// frame remains the `BridgeDeltaBanner`. When neither condition holds the
/// wrapper is a transparent passthrough so layout is unaffected.
class _DayRowsFrame extends StatelessWidget {
  const _DayRowsFrame({
    required this.child,
    required this.isOver,
    required this.isUnder,
    required this.showFrame,
  });

  final Widget child;
  final bool isOver;
  final bool isUnder;
  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    if (!showFrame || (!isOver && !isUnder)) return child;
    final Color borderColor = isOver
        ? AppColors.destructiveBorderSoft
        : AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.errorBannerRadius),
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
        color: AppColors.white,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.gray200, width: 1),
        ),
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

int _scheduledMinutesForWeekday(TimeSchedule schedule, int weekday) {
  int total = 0;
  for (final DayAllocation allocation in schedule.dayAllocations) {
    if (allocation.weekdayIndices.contains(weekday)) {
      total += allocation.totalMinutes;
    }
  }
  return total;
}

String _formatMinutes(int totalMinutes) {
  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;
  return '$hours시간 ${minutes.toString().padLeft(2, '0')}분';
}
