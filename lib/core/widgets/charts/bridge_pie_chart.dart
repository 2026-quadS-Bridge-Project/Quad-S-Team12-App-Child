import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// A single slice in a [BridgePieChart].
///
/// [percent] is expressed in the 0..100 range. The sum of all slice
/// percents in a chart is expected to equal 100, but the widget will
/// still render correctly if it does not (slice angles are computed
/// proportionally to the percent values supplied).
class BridgePieChartSlice {
  const BridgePieChartSlice({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;
}

/// Reusable pie chart used by the weekly compliance card (see
/// `docs/figma-specs/07-report.md`, Card 4).
///
/// Renders three (or more) solid slices at the given [size] with
/// percentage labels positioned *outside* the slice arcs. fl_chart
/// 0.69's [PieChartSectionData.titlePositionPercentageOffset] only
/// positions section titles along the radial line within the chart's
/// own canvas — values >1.0 push the text past the arc but the text is
/// still clipped to the chart's bounding rect and is not anchored to a
/// guaranteed external position. To get the spec's "label sits outside
/// the slice with extra padding" behaviour we overlay our own
/// [Positioned] text widgets on top of a transparent-title [PieChart]
/// using pre-computed polar coordinates.
///
/// Label positioning: defaults to radial placement at each slice's
/// mid-angle, [_labelRadialPadding] px outside the arc. Figma spec
/// (07-report.md:88-91) lists exact per-slice offsets — those are not
/// applied here because the new Card 4 row layout constrains the pie's
/// horizontal box, and the Figma 50% label coord (x=216) would clip the
/// rebuilt layout. The radial fallback preserves the same directional
/// intent (top / right / bottom-left for 20/50/30) without overflow.
class BridgePieChart extends StatelessWidget {
  const BridgePieChart({
    super.key,
    required this.slices,
    this.size = 124,
    this.complianceRatePct,
  });

  final List<BridgePieChartSlice> slices;
  final double size;

  /// When provided, renders `계획 이행률 NN%` above the pie.
  final double? complianceRatePct;

  /// Extra radial padding (in logical pixels) between the slice edge
  /// and the centre of the percentage label.
  static const double _labelRadialPadding = 14;

  /// Width/height reserved for each external label. Sized to fit
  /// strings like `"100%"` at Caption/Bold 12.
  static const double _labelBoxWidth = 40;
  static const double _labelBoxHeight = 18;

  @override
  Widget build(BuildContext context) {
    final double totalPercent = slices.fold<double>(
      0,
      (sum, s) => sum + s.percent,
    );
    // Guard against degenerate input.
    final double safeTotal = totalPercent <= 0 ? 1 : totalPercent;

    // Stack canvas needs to accommodate labels that overflow the pie's
    // bounding box. Reserve label box on each side.
    final double stackSize = size + (_labelBoxWidth);
    final double pieOffset = (stackSize - size) / 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (complianceRatePct != null) ...[
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
                '${complianceRatePct!.toInt()}%',
                style: AppTypography.headlineBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: stackSize,
          height: stackSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: pieOffset,
                top: pieOffset,
                width: size,
                height: size,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 0,
                    startDegreeOffset: -90,
                    sections: [
                      for (final slice in slices)
                        PieChartSectionData(
                          value: slice.percent,
                          color: slice.color,
                          radius: size / 2,
                          // Hide built-in title; we render external
                          // labels via Positioned overlays.
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
              ),
              ..._buildExternalLabels(
                stackSize: stackSize,
                safeTotal: safeTotal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildExternalLabels({
    required double stackSize,
    required double safeTotal,
  }) {
    final double centerX = stackSize / 2;
    final double centerY = stackSize / 2;
    final double labelRadius = (size / 2) + _labelRadialPadding;

    final List<Widget> labels = [];
    double accumulatedPercent = 0;

    for (final slice in slices) {
      // Compute the angle of the slice's mid-point. Pie starts at the
      // 12-o'clock position (startDegreeOffset: -90) and sweeps
      // clockwise — match that convention here.
      final double midPercent = accumulatedPercent + (slice.percent / 2);
      accumulatedPercent += slice.percent;

      final double sweepFraction = midPercent / safeTotal;
      // -pi/2 == top of circle; clockwise sweep.
      final double angleRad = (-math.pi / 2) + (sweepFraction * 2 * math.pi);

      final double labelCenterX = centerX + labelRadius * math.cos(angleRad);
      final double labelCenterY = centerY + labelRadius * math.sin(angleRad);

      labels.add(
        Positioned(
          left: labelCenterX - (_labelBoxWidth / 2),
          top: labelCenterY - (_labelBoxHeight / 2),
          width: _labelBoxWidth,
          height: _labelBoxHeight,
          child: Center(
            child: Text(
              '${slice.percent.toInt()}%',
              textAlign: TextAlign.center,
              style: AppTypography.captionBold.copyWith(color: slice.color),
            ),
          ),
        ),
      );
    }

    return labels;
  }
}
