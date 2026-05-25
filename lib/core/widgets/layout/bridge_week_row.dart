import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Row card used on the weekly time-entry screen.
///
/// Visual:
/// - White card, radius 12.
/// - Fixed 50px height with 8 horizontal / 11 vertical padding.
/// - Leading week label (e.g. "1주차"), 22px divider, and inline time cluster.
/// - When both [hours] and [minutes] are 0, the numeric placeholders render
///   in [AppColors.gray200]; otherwise values render in [AppColors.inkBlack].
///
/// Interaction:
/// - When [onTap] is non-null the entire card is a hit target wrapped in
///   [InkWell]; when null the row is read-only.
/// - When [isPast] is true the card is dimmed via [Opacity] (0.2) to indicate
///   a past week per v2 spec.
///
/// Spec: docs/figma-specs/08a-time-v1-entry-weekly.md §11870
class BridgeWeekRow extends StatelessWidget {
  const BridgeWeekRow({
    super.key,
    required this.weekLabel,
    required this.hours,
    required this.minutes,
    this.onTap,
    this.isPast = false,
  });

  /// Label shown on the leading side (e.g. "1주차").
  final String weekLabel;

  /// Hours portion of the allocated time. 0 + 0 minutes => placeholder state.
  final int hours;

  /// Minutes portion of the allocated time. 0 + 0 hours => placeholder state.
  final int minutes;

  /// Optional tap handler. When null the row is rendered read-only (no
  /// [InkWell]).
  final VoidCallback? onTap;

  /// When true, dims the entire card to 20% opacity to mark a past week.
  final bool isPast;

  static const double _rowHeight = 50;
  static const double _borderRadius = 12;
  static const double _horizontalPadding = 8;
  static const double _verticalPadding = 11;
  static const double _labelWidth = 55;
  static const double _dividerHeight = 22;
  static const double _dividerGap = 22;
  static const double _numberUnitGap = 4;
  static const double _unitGap = 10;

  @override
  Widget build(BuildContext context) {
    final bool isPlaceholder = hours == 0 && minutes == 0;
    final Color valueColor = isPlaceholder
        ? AppColors.gray200
        : AppColors.inkBlack;

    final Widget card = SizedBox(
      height: _rowHeight,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: _verticalPadding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Text(
                    weekLabel,
                    style: AppTypography.headlineSemiBold.copyWith(
                      color: AppColors.inkBlack,
                    ),
                  ),
                ),
                const SizedBox(width: _dividerGap),
                Container(
                  width: 1,
                  height: _dividerHeight,
                  color: AppColors.gray200,
                ),
                const SizedBox(width: _dividerGap),
                _TimeInline(
                  hours: hours,
                  minutes: minutes,
                  valueColor: valueColor,
                  unitColor: AppColors.inkBlack,
                  numberUnitGap: _numberUnitGap,
                  unitGap: _unitGap,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final Widget content = isPast ? Opacity(opacity: 0.2, child: card) : card;

    // Disable the InkWell when there is no tap handler so the row reads as
    // non-interactive (no splash, no hover state).
    return IgnorePointer(ignoring: onTap == null, child: content);
  }
}

class _TimeInline extends StatelessWidget {
  const _TimeInline({
    required this.hours,
    required this.minutes,
    required this.valueColor,
    required this.unitColor,
    required this.numberUnitGap,
    required this.unitGap,
  });

  final int hours;
  final int minutes;
  final Color valueColor;
  final Color unitColor;
  final double numberUnitGap;
  final double unitGap;

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = AppTypography.headlineSemiBold.copyWith(
      color: valueColor,
    );
    final TextStyle unitStyle = AppTypography.headlineRegular.copyWith(
      color: unitColor,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(_twoDigits(hours), style: valueStyle),
        SizedBox(width: numberUnitGap),
        Text('시간', style: unitStyle),
        SizedBox(width: unitGap),
        Text(_twoDigits(minutes), style: valueStyle),
        SizedBox(width: numberUnitGap),
        Text('분', style: unitStyle),
      ],
    );
  }
}
