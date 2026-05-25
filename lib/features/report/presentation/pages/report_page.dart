import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/result.dart';
import '../../../../core/services/calendar_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/charts/bridge_bar_chart.dart';
import '../../../../core/widgets/charts/bridge_pie_chart.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../data/mock/usage_report_mock.dart';
import '../../data/models/usage_report.dart';
import '../../data/repositories/usage_report_repository.dart';

/// Weekly usage report screen.
///
/// Spec: `docs/figma-specs/07-report.md` (`scr/child-weekly report`,
/// Figma node `662:11497`, file `tzJjQmXtXO7vGlfCT9SASu`).
///
/// Stacked vertically inside a [ListView]:
///   1. Card 1 — Weekly Intro: caption + primary-colored title +
///      `primarySoft` speech bubble (4 lines) + cat illustration.
///   2. Card 2 — Plan summary (total hours + per-dayset rows).
///   3. Card 3 — Weekly analysis: grouped bar chart + per-day breakdown
///      rows (each row = gray100 tile / day label / divider / hours /
///      trailing triangle delta chip).
///   4. Card 4 — Compliance pie chart (3 slices at 124×124).
///   5. Card 5 — AI adjustment suggestions per day group.
///   6. Footer — primary CTA `다음주 계획 짜러가기 →` (327×54, radius 8).
///
/// This page is presented as a push-style route from the home dashboard
/// (the bottom-nav shell has been removed), so it owns a [BridgeAppBar]
/// with a back button that pops via `context.pop()`. The in-body weekly
/// period header (`_WeeklyIntroCard`) is retained per Figma `662:11497`.
///
/// Phase 2A: the page now consults [UsageReportRepository] via
/// [createUsageReportRepository] so backend wiring can be swapped in
/// without touching the widget tree. The state seed is the synchronous
/// [UsageReportMock.currentWeek] fixture to avoid a cold-open flicker;
/// [initState] then dispatches `_load()` which calls the repository and
/// `setState`s on Success. Failure outcomes retain the seed data and
/// surface a one-time SnackBar so the user knows the refresh failed
/// (no auto-retry).
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late final UsageReportRepository _repository = createUsageReportRepository();

  /// Synchronous seed avoids a one-frame empty state on cold open.
  /// `_load()` overwrites this with whatever the repository returns.
  late UsageReport _report = UsageReportMock.currentWeek;

  /// Guards the failure SnackBar so we surface it at most once per page
  /// lifetime (no auto-retry; user can navigate back/in to re-fetch).
  bool _didNotifyLoadFailure = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.fetchCurrentWeekReport();
    if (!mounted) return;
    switch (result) {
      case Success<UsageReport>(:final data):
        setState(() => _report = data);
      case Failure<UsageReport>():
        // Retain the seed fixture and notify the user once.
        if (!_didNotifyLoadFailure) {
          _didNotifyLoadFailure = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('리포트를 새로고침하지 못했어요.')),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final UsageReport report = _report;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BridgeAppBar(title: '사용 리포트'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.pageHorizontal,
            0,
            AppTokens.pageHorizontal,
            16,
          ),
          children: [
            _WeeklyIntroCard(weekLabel: report.weekLabel),
            const SizedBox(height: 20),
            _PlanCard(plan: report.plan),
            const SizedBox(height: 20),
            _BarChartCard(dailyRows: report.dailyRows),
            const SizedBox(height: 20),
            _PieChartCard(compliance: report.compliance),
            const SizedBox(height: 20),
            _SuggestionCard(suggestions: report.suggestions),
            const SizedBox(height: 24),
            BridgeButton(
              label: '다음주 계획 짜러가기 →',
              variant: BridgeButtonVariant.primary,
              size: BridgeButtonSize.large,
              fullWidth: true,
              onPressed: () => context.push('/child-home/time-setup/v2'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// region: shared building blocks ---------------------------------------------

/// White card chrome shared by every section card on this screen.
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

// region: Card 1 — Weekly Intro ---------------------------------------------

/// Card 1 — `Weekly Intro` (`750:11937`).
///
/// Spec: docs/figma-specs/07-report.md §"Card 1 — Weekly Intro".
/// Caption + primary-colored title + `primarySoft` speech bubble (4 lines)
/// with a polygon tail and a 44×43 cat illustration in the bottom-right.
class _WeeklyIntroCard extends StatelessWidget {
  const _WeeklyIntroCard({required this.weekLabel});

  /// e.g. `2월 1주차 사용리포트` — rendered as the primary-colored title.
  final String weekLabel;

  // Bubble copy, verbatim per spec §"Texts (verbatim)" — Card 1.
  static const List<String> _bubbleLines = [
    '내 기존 계획을 확인하고,',
    '계획대로 사용했는지,',
    '계획대로 사용하지 못했다면 그 이유는 무엇인지,',
    '다음주에 어떻게 조정하는 것이 좋을지 생각해봐요!',
  ];

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이번주 나는 어떻게 사용했을까?',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.gray400,
                ),
              ),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text(
                  weekLabel,
                  style: AppTypography.heading2Bold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _IntroSpeechBubble(lines: _bubbleLines),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox(
              width: 44,
              height: 43,
              child: SvgPicture.asset(
                'assets/icons/cat.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `primarySoft` speech bubble with a small polygon tail anchored
/// down-right. Body lines render as Caption/Medium 12, gray500.
class _IntroSpeechBubble extends StatelessWidget {
  const _IntroSpeechBubble({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < lines.length; i++) ...[
                Text(
                  lines[i],
                  style: AppTypography.captionMedium.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                if (i < lines.length - 1) const SizedBox(height: 2),
              ],
            ],
          ),
        ),
        // Polygon tail (down-right). Rendered with CustomPaint so the
        // triangle inherits the speech-bubble color without an SVG dep.
        Padding(
          padding: const EdgeInsets.only(right: 28),
          child: Align(
            alignment: Alignment.centerRight,
            child: CustomPaint(
              size: const Size(12, 8),
              painter: _BubbleTailPainter(color: AppColors.primarySoft),
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.35, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color;
}

// region: Card 2 — Plan summary ----------------------------------------------

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final WeeklyTotalPlan plan;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${createCalendarService().currentWeekLabel()} 나의 계획은',
            style: AppTypography.labelMedium.copyWith(color: AppColors.gray400),
          ),
          const SizedBox(height: 4),
          Text(
            '주 ${plan.totalHours}시간',
            style: AppTypography.heading2Bold.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < plan.daySets.length; i++) ...[
            _PlanDaySetRow(daySet: plan.daySets[i]),
            if (i < plan.daySets.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PlanDaySetRow extends StatelessWidget {
  const _PlanDaySetRow({required this.daySet});

  final DaySetPlan daySet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              daySet.daysLabel,
              style: AppTypography.headlineBold.copyWith(
                color: AppColors.gray800,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 22,
            color: AppColors.gray200,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          _ReportTimeText(hours: daySet.hoursPerDay),
        ],
      ),
    );
  }
}

// region: Card 3 — Weekly bar chart + per-day breakdown ----------------------

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({required this.dailyRows});

  final List<DailyUsageRow> dailyRows;

  @override
  Widget build(BuildContext context) {
    final List<BridgeBarChartDay> chartDays = [
      for (final row in dailyRows)
        BridgeBarChartDay(
          label: row.dayKor,
          plannedMinutes: row.plannedMinutes,
          actualMinutes: row.actualMinutes,
        ),
    ];

    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번주 사용 분석',
            style: AppTypography.heading2Bold.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '화·토·일에 계획보다 많이 사용했어요.',
            style: AppTypography.labelMedium.copyWith(color: AppColors.gray400),
          ),
          const SizedBox(height: 2),
          Text(
            '월·금에는 계획보다 적게 사용하는 날이 많았어요.',
            style: AppTypography.labelMedium.copyWith(color: AppColors.gray400),
          ),
          const SizedBox(height: 16),
          BridgeBarChart(days: chartDays),
          const SizedBox(height: 16),
          // Per-day breakdown: BridgeDayRow-style tiles (gray100 tile · day ·
          // 1×22 gray200 divider · hours · trailing triangle delta chip).
          // Spec: 07-report.md §"Card 3 / Per-day breakdown list".
          for (int i = 0; i < dailyRows.length; i++) ...[
            _DayBreakdownRow(row: dailyRows[i]),
            if (i < dailyRows.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Per-day breakdown tile used inside Card 3.
///
/// Visual: `[day] | [H시간 MM분]   [△ N시간]`
///  - gray100 tile, radius 16, padding 16h/12v.
///  - 1×22 gray200 vertical divider between day label and hours.
///  - Trailing delta chip:
///      over plan  → `Icons.arrow_drop_up`   + `N시간` in [AppColors.destructive]
///      under plan → `Icons.arrow_drop_down` + `N시간` in [AppColors.positive]
///      on plan    → short gray line marker (matches `imgLine2` treatment).
class _DayBreakdownRow extends StatelessWidget {
  const _DayBreakdownRow({required this.row});

  final DailyUsageRow row;

  @override
  Widget build(BuildContext context) {
    final int totalMinutes = row.actualMinutes;
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;

    final int deltaMinutes = row.deltaMinutes;
    final bool isOnPlan = deltaMinutes.abs() <= 5;
    final bool isOver = deltaMinutes > 5;
    final int deltaAbsHours = (deltaMinutes.abs() / 60).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
      ),
      child: Row(
        children: [
          Text(
            row.dayKor,
            style: AppTypography.headlineBold.copyWith(
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 22, color: AppColors.gray200),
          const SizedBox(width: 12),
          _ReportTimeText(hours: hours, minutes: minutes),
          const Spacer(),
          if (isOnPlan)
            const _OnPlanMarker()
          else
            _DeltaTriangleChip(hours: deltaAbsHours, isOver: isOver),
        ],
      ),
    );
  }
}

/// Trailing triangle + `N시간` chip used in the per-day breakdown list.
///
/// Per spec, "on plan" rows render a small `imgLine2` wave/dash line in place
/// of the chip. We approximate it with a short rounded gray line.
class _DeltaTriangleChip extends StatelessWidget {
  const _DeltaTriangleChip({required this.hours, required this.isOver});

  final int hours;
  final bool isOver;

  @override
  Widget build(BuildContext context) {
    final Color color = isOver ? AppColors.destructive : AppColors.positive;
    final IconData triangle = isOver
        ? Icons.arrow_drop_up
        : Icons.arrow_drop_down;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(triangle, size: 16, color: color),
        const SizedBox(width: 2),
        Text(
          '$hours시간',
          style: AppTypography.captionMedium.copyWith(
            color: color,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

// region: Card 4 — Compliance pie --------------------------------------------

/// Card 4 — Compliance pie. Per Figma 662:11551 / spec 07-report.md §"Card 4",
/// the layout is `[legend column on left] [pie 124×124 on right]` inside a
/// single Row — not stacked vertically (audit Issue 11).
///
/// The header `계획 이행률 50%` sits on top via [BridgePieChart]'s built-in
/// header (passes [ComplianceBreakdown.overallCompliancePct], which now
/// resolves to the over-plan slice per audit Issue 12).
class _PieChartCard extends StatelessWidget {
  const _PieChartCard({required this.compliance});

  final ComplianceBreakdown compliance;

  static const List<_LegendEntry> _legendEntries = [
    _LegendEntry(color: AppColors.positive, label: '계획대로 사용한 날'),
    _LegendEntry(color: AppColors.primary, label: '계획보다 많이 사용한 날'),
    _LegendEntry(color: AppColors.destructive, label: '계획보다 적게 사용한 날'),
  ];

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header `계획 이행률 NN%` lives on Card 4's own Column so it can
          // span the full card width, while the body Row below splits into
          // [legend | pie]. (BridgePieChart still renders its internal
          // header when `complianceRatePct` is non-null, so we suppress it
          // here by not passing the rate.)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '계획 이행률 ',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${compliance.overallCompliancePct.toInt()}%',
                style: AppTypography.headlineBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Vertical legend strip — 3 colored dots + labels stacked.
              // Mirrors Figma's `imgEllipseGroupContainer` (5×43 dot strip
              // + 3 right-aligned labels).
              const _LegendColumn(entries: _legendEntries),
              const SizedBox(width: 16),
              // Pie on the right; size locked at 124×124 per spec.
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: BridgePieChart(
                    slices: [
                      BridgePieChartSlice(
                        label: '계획대로',
                        percent: compliance.onPlanPct,
                        color: AppColors.positive,
                      ),
                      BridgePieChartSlice(
                        label: '많이 사용',
                        percent: compliance.overPct,
                        color: AppColors.primary,
                      ),
                      BridgePieChartSlice(
                        label: '적게 사용',
                        percent: compliance.underPct,
                        color: AppColors.destructive,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendEntry {
  const _LegendEntry({required this.color, required this.label});
  final Color color;
  final String label;
}

/// Vertical legend column — 5×5 colored dots (matches the Figma
/// `imgEllipseGroupContainer` 5-wide strip) paired with right-side labels.
/// Replaces the previous horizontal `_LegendRow` stack (audit Issue 11/13).
class _LegendColumn extends StatelessWidget {
  const _LegendColumn({required this.entries});

  final List<_LegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: entries[i].color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entries[i].label,
                style: AppTypography.captionMedium.copyWith(
                  color: AppColors.gray300,
                ),
              ),
            ],
          ),
          if (i < entries.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

// region: Card 5 — AI suggestions --------------------------------------------

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestions});

  final List<AiSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '다음주는 이렇게 조정해보자',
            style: AppTypography.labelMedium.copyWith(color: AppColors.gray400),
          ),
          const SizedBox(height: 4),
          Text(
            'AI 조정 제안',
            style: AppTypography.heading2Bold.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < suggestions.length; i++) ...[
            _SuggestionRow(suggestion: suggestions[i]),
            if (i < suggestions.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Card 5 row — mirrors Card 3's `_DayBreakdownRow` layout per Figma
/// 662:11585 (audit Issue 14): `[days] | 1×22 gray200 divider |
/// [H시간 MM분] | [delta chip]`.
class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion});

  final AiSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final int hours = suggestion.suggestedHours;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
      ),
      child: Row(
        children: [
          Text(
            suggestion.daysLabel,
            style: AppTypography.headlineBold.copyWith(
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 22, color: AppColors.gray200),
          const SizedBox(width: 12),
          _ReportTimeText(hours: hours, minutes: 0),
          const Spacer(),
          _SuggestionDeltaIndicator(suggestion: suggestion),
        ],
      ),
    );
  }
}

/// Triangle or line marker used in the AI suggestion rows.
class _SuggestionDeltaIndicator extends StatelessWidget {
  const _SuggestionDeltaIndicator({required this.suggestion});

  final AiSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    switch (suggestion.tone) {
      case AiSuggestionTone.positive:
        return _DeltaTriangleChip(
          hours: suggestion.deltaHours.abs(),
          isOver: false,
        );
      case AiSuggestionTone.destructive:
        return _DeltaTriangleChip(
          hours: suggestion.deltaHours.abs(),
          isOver: true,
        );
      case AiSuggestionTone.neutral:
        return const _OnPlanMarker();
    }
  }
}

class _ReportTimeText extends StatelessWidget {
  const _ReportTimeText({required this.hours, this.minutes = 0});

  final int hours;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final TextStyle numberStyle = AppTypography.headlineBold.copyWith(
      color: AppColors.gray800,
    );
    final TextStyle unitStyle = AppTypography.headlineRegular.copyWith(
      color: AppColors.gray800,
    );

    return RichText(
      text: TextSpan(
        children: <InlineSpan>[
          TextSpan(text: '$hours', style: numberStyle),
          TextSpan(text: ' 시간 ', style: unitStyle),
          TextSpan(
            text: minutes.toString().padLeft(2, '0'),
            style: numberStyle,
          ),
          TextSpan(text: ' 분', style: unitStyle),
        ],
      ),
    );
  }
}

class _OnPlanMarker extends StatelessWidget {
  const _OnPlanMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 2,
      decoration: BoxDecoration(
        color: AppColors.gray300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
