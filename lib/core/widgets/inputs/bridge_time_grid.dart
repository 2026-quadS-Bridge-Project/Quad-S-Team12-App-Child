import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Weekly hour-slot grid used by the schedule registration screens
/// (`scr/child-초기 시간설정-스케줄등록-*`, nodes `695:8924` / `695:9115`).
///
/// Layout:
///   • Top row: 7 weekday headers (월–일).
///   • Left column: hour-axis labels (default 7–12, 1–11, 17 rows).
///   • Body: 7 × 17 tappable cells. Each cell toggles its `(weekday, hour)`
///     entry in [selected]; the new state is reported via [onToggle].
///
/// Sizing follows the Figma frame (overall width ≈ 327): a compact hour-axis
/// column on the left and 7 equal-width day columns filling the remaining
/// width with fixed gutters. Header chips are 34 px tall; body cells are
/// 27 px tall with 0.5 px row gaps, matching the 501 px table rhythm in the
/// schedule specs.
///
/// Selection state is held by the caller (stateless widget). The selection
/// uses a record type `({int weekday, int hour})` where `weekday` is the
/// column index `0..6` and `hour` is the row index `0..len(hours)-1`
/// (not the literal hour-of-day — the label list is independent of the key).
///
/// Implementation note on record types: the project targets Dart SDK
/// `^3.11.1` which fully supports record types, so the spec's record API is
/// used directly. The `weekday * 100 + hour` `Set<int>` fallback is not
/// required.
class BridgeTimeGrid extends StatelessWidget {
  const BridgeTimeGrid({
    super.key,
    required this.selected,
    required this.onToggle,
    this.weekdays = const ['월', '화', '수', '목', '금', '토', '일'],
    this.hours = const [
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
    ],
    this.startHourOfDay = 7,
  });

  /// Currently selected `(weekday, hour)` cells.
  final Set<({int weekday, int hour})> selected;

  /// Invoked when a body cell is tapped. The caller is expected to update
  /// [selected] and rebuild.
  final void Function(int weekday, int hour) onToggle;

  /// Weekday column headers (left → right). Length should equal 7.
  final List<String> weekdays;

  /// Hour-axis row labels (top → bottom). Length determines the row count.
  final List<String> hours;

  /// Literal hour-of-day represented by row 0. The grid still reports row
  /// indices through [onToggle]; this value is only used for unambiguous
  /// accessibility labels.
  final int startHourOfDay;

  /// Width of the left-hand hour-axis column.
  static const double _axisWidth = 20;

  /// Figma header chip height.
  static const double _headerHeight = 34;

  /// Figma body cell height.
  static const double _cellHeight = 27;

  /// Horizontal gutter between weekday columns.
  static const double _columnGap = 4;

  /// Vertical gutter between body rows.
  static const double _rowGap = 0.5;

  static const double _referenceWidth = 327;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.bodyBold.copyWith(
      color: AppColors.gray400,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a finite width: prefer parent constraint, fall back to the
        // Figma reference width when the parent is unbounded (e.g. inside
        // an unconstrained Row).
        final totalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : _referenceWidth;
        final gapCount = weekdays.length > 1 ? weekdays.length - 1 : 0;
        final gapWidth = _columnGap * gapCount;
        final availableWidth = totalWidth - _axisWidth - gapWidth;
        final dayWidth = weekdays.isEmpty || availableWidth <= 0
            ? 0.0
            : availableWidth / weekdays.length;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(headerStyle, dayWidth),
            const SizedBox(height: _rowGap),
            for (var row = 0; row < hours.length; row++) ...[
              if (row > 0) const SizedBox(height: _rowGap),
              _buildBodyRow(rowIndex: row, dayWidth: dayWidth),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeaderRow(TextStyle headerStyle, double dayWidth) {
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          const SizedBox(width: _axisWidth),
          for (var col = 0; col < weekdays.length; col++) ...[
            if (col > 0) const SizedBox(width: _columnGap),
            Container(
              width: dayWidth,
              height: _headerHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                weekdays[col],
                style: headerStyle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBodyRow({required int rowIndex, required double dayWidth}) {
    final axisStyle =
        (rowIndex < 2
                ? AppTypography.captionMedium
                : AppTypography.captionRegular)
            .copyWith(color: AppColors.gray400);

    return SizedBox(
      height: _cellHeight,
      child: Row(
        children: [
          SizedBox(
            width: _axisWidth,
            height: _cellHeight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  hours[rowIndex],
                  style: axisStyle,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ),
          ),
          for (var col = 0; col < weekdays.length; col++) ...[
            if (col > 0) const SizedBox(width: _columnGap),
            _GridCell(
              width: dayWidth,
              height: _cellHeight,
              isSelected: selected.contains((weekday: col, hour: rowIndex)),
              onTap: () => onToggle(col, rowIndex),
              weekdayLabel: weekdays[col],
              hourOfDay: startHourOfDay + rowIndex,
            ),
          ],
        ],
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.width,
    required this.height,
    required this.isSelected,
    required this.onTap,
    required this.weekdayLabel,
    required this.hourOfDay,
  });

  final double width;
  final double height;
  final bool isSelected;
  final VoidCallback onTap;
  final String weekdayLabel;
  final int hourOfDay;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? AppColors.primary : AppColors.gray150;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$weekdayLabel요일 $hourOfDay시',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(color: bg),
            child: CustomPaint(
              painter: isSelected ? null : const _GridCellHatchPainter(),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridCellHatchPainter extends CustomPainter {
  const _GridCellHatchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray200
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.88),
      Offset(size.width * 0.88, size.height * 0.12),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GridCellHatchPainter oldDelegate) => false;
}
