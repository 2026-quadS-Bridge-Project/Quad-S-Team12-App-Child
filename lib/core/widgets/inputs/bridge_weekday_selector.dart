import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Seven-chip weekday selector used in the daily time-allocation bottom sheet.
///
/// Renders one pill per weekday label (defaults: 월~일). Tapping a chip toggles
/// the corresponding index (0..6) in [selected] and emits the new set via
/// [onChanged]. The widget is stateless — callers own the selection state.
///
/// Visual spec (per chip): 36×36 pill, radius 18, 7px gap between chips.
/// Unselected: bg gray100, text gray600 / bodyMedium.
/// Selected:   bg primary, text white / bodyBold.
class BridgeWeekdaySelector extends StatelessWidget {
  const BridgeWeekdaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.weekdays = const ['월', '화', '수', '목', '금', '토', '일'],
  });

  /// Indices (0..6) of currently-selected weekdays.
  final Set<int> selected;

  /// Called with the new selection set after a chip toggle.
  final ValueChanged<Set<int>> onChanged;

  /// Display labels for each weekday. Length should equal 7.
  final List<String> weekdays;

  static const double _chipSize = 36;
  static const double _chipGap = 7;
  static const Duration _animDuration = Duration(milliseconds: 200);

  void _handleTap(int index) {
    final next = Set<int>.from(selected);
    if (next.contains(index)) {
      next.remove(index);
    } else {
      next.add(index);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < weekdays.length; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: _chipGap));
      }
      children.add(
        _WeekdayChip(
          label: weekdays[i],
          isSelected: selected.contains(i),
          onTap: () => _handleTap(i),
          size: _chipSize,
          duration: _animDuration,
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.size,
    required this.duration,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? AppColors.primary : AppColors.gray100;
    final textStyle = isSelected
        ? AppTypography.bodySemiBold.copyWith(color: AppColors.white)
        : AppTypography.bodyMedium.copyWith(color: AppColors.gray600);
    final radius = BorderRadius.circular(size / 2);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bgColor, borderRadius: radius),
            child: Text(label, style: textStyle, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
