import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// One day of planned vs actual usage data for [BridgeBarChart].
///
/// `plannedMinutes` and `actualMinutes` are in minutes (e.g. 7h = 420).
/// A small +/-5 minute tolerance is used to classify a day as on-plan, so
/// minor rounding doesn't flip the rod color.
class BridgeBarChartDay {
  const BridgeBarChartDay({
    required this.label,
    required this.plannedMinutes,
    required this.actualMinutes,
  });

  /// Single-character weekday label, e.g. '월'..'일'.
  final String label;
  final int plannedMinutes;
  final int actualMinutes;

  int get deltaMinutes => actualMinutes - plannedMinutes;
  bool get isOver => deltaMinutes > 5;
  bool get isUnder => deltaMinutes < -5;
  bool get isOnPlan => !isOver && !isUnder;
}

/// Grouped bar chart used in the weekly report card (Card 3 in 07-report.md).
///
/// Renders one [BarChartGroupData] per day with two rods (planned, actual).
/// The actual rod color reflects whether the child used more, less, or roughly
/// the planned time. No grid, no Y axis labels, and only weekday tick labels
/// on the bottom — matches the Figma `Usage Graph Container`.
class BridgeBarChart extends StatelessWidget {
  const BridgeBarChart({super.key, required this.days, this.height = 180});

  /// Expected to be 7 entries (월..일). Renders an empty chart shell if empty.
  final List<BridgeBarChartDay> days;
  final double height;

  static const double _rodWidth = 8;
  static const double _barsSpace = 4;
  static const double _groupsSpace = 12;
  static const Radius _rodTopRadius = Radius.circular(4);

  Color _actualColor(BridgeBarChartDay day) {
    if (day.isOver) return AppColors.destructive;
    if (day.isUnder) return AppColors.positive;
    return AppColors.primary; // on plan → same as planned
  }

  /// Rounds [value] up to the next multiple of 60. Falls back to 60 when the
  /// dataset is all zeros so the chart still has a sensible axis.
  double _ceilToHour(double value) {
    if (value <= 0) return 60;
    return (value / 60).ceil() * 60.0;
  }

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return SizedBox(height: height);
    }

    final double rawMax = days.fold<double>(0, (m, d) {
      final localMax = math.max(d.plannedMinutes, d.actualMinutes).toDouble();
      return localMax > m ? localMax : m;
    });
    final double maxY = _ceilToHour(rawMax);

    final groups = <BarChartGroupData>[
      for (int i = 0; i < days.length; i++)
        BarChartGroupData(
          x: i,
          barsSpace: _barsSpace,
          barRods: [
            BarChartRodData(
              toY: days[i].plannedMinutes.toDouble(),
              color: AppColors.primary,
              width: _rodWidth,
              borderRadius: const BorderRadius.only(
                topLeft: _rodTopRadius,
                topRight: _rodTopRadius,
              ),
            ),
            BarChartRodData(
              toY: days[i].actualMinutes.toDouble(),
              color: _actualColor(days[i]),
              width: _rodWidth,
              borderRadius: const BorderRadius.only(
                topLeft: _rodTopRadius,
                topRight: _rodTopRadius,
              ),
            ),
          ],
        ),
    ];

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          groupsSpace: _groupsSpace,
          barGroups: groups,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= days.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      days[i].label,
                      style: AppTypography.captionRegular.copyWith(
                        color: AppColors.gray400,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
