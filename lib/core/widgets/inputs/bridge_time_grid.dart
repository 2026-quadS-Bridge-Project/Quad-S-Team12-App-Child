import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Weekly hour-slot grid used by the schedule registration screens
/// (`scr/child-초기 시간설정-스케줄등록-*`, nodes `695:8924` / `695:9115`).
///
/// Layout:
///   • Top row: 7 weekday headers (월–일).
///   • Left column: hour-axis labels (default 07–23, 17 rows).
///   • Body: 7 × 17 tappable cells. Each cell toggles its `(weekday, hour)`
///     entry in [selected]; the new state is reported via [onToggle].
///
/// Sizing follows the Figma frame (overall width ≈ 327): a 28 px hour-axis
/// column on the left and 7 equal-width day columns filling the remaining
/// width. Cell height is 28 px to match the spec's `~40 × 28` cell target.
/// Cells share a 1 px [AppColors.gray200] border (drawn with `Border.all`,
/// so adjacent borders visually collapse).
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
      '07',
      '08',
      '09',
      '10',
      '11',
      '12',
      '13',
      '14',
      '15',
      '16',
      '17',
      '18',
      '19',
      '20',
      '21',
      '22',
      '23',
    ],
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

  /// Width of the left-hand hour-axis column.
  static const double _axisWidth = 28;

  /// Height of every grid row (header + body cells).
  static const double _rowHeight = 28;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.captionRegular.copyWith(
      color: AppColors.gray400,
    );
    final axisStyle = AppTypography.captionRegular.copyWith(
      color: AppColors.gray400,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a finite width: prefer parent constraint, fall back to the
        // Figma reference width when the parent is unbounded (e.g. inside
        // an unconstrained Row).
        final totalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 327.0;
        final dayWidth = (totalWidth - _axisWidth) / weekdays.length;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(headerStyle, dayWidth),
            for (var row = 0; row < hours.length; row++)
              _buildBodyRow(
                rowIndex: row,
                axisStyle: axisStyle,
                dayWidth: dayWidth,
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderRow(TextStyle headerStyle, double dayWidth) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          const SizedBox(width: _axisWidth),
          for (var col = 0; col < weekdays.length; col++)
            SizedBox(
              width: dayWidth,
              height: _rowHeight,
              child: Center(
                child: Text(
                  weekdays[col],
                  style: headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBodyRow({
    required int rowIndex,
    required TextStyle axisStyle,
    required double dayWidth,
  }) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: _axisWidth,
            height: _rowHeight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  hours[rowIndex],
                  style: axisStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          for (var col = 0; col < weekdays.length; col++)
            _GridCell(
              width: dayWidth,
              height: _rowHeight,
              isSelected: selected.contains((weekday: col, hour: rowIndex)),
              onTap: () => onToggle(col, rowIndex),
              weekdayLabel: weekdays[col],
              hourLabel: hours[rowIndex],
            ),
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
    required this.hourLabel,
  });

  final double width;
  final double height;
  final bool isSelected;
  final VoidCallback onTap;
  final String weekdayLabel;
  final String hourLabel;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? AppColors.primarySubtle : AppColors.white;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$weekdayLabel $hourLabel',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(width: 1, color: AppColors.gray200),
          ),
        ),
      ),
    );
  }
}
