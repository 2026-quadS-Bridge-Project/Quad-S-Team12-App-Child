import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Row card used on the weekly time-entry screen.
///
/// Visual:
/// - White card, radius [AppTokens.cardRadiusSmall] (16).
/// - Outer padding 18 horizontal / 15 vertical.
/// - Inner row height 45, [MainAxisAlignment.spaceBetween]:
///   - Leading: week label (e.g. "1주차") rendered as
///     [AppTypography.headlineBold] in [AppColors.gray800].
///   - Trailing: inline time cluster — `H 시간   M 분`. When both [hours] and
///     [minutes] are 0, the cluster renders as a placeholder (`00`/`00`) in
///     [AppColors.gray300]; otherwise values render in [AppColors.gray800].
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

  static const double _rowHeight = 45;
  static const double _horizontalPadding = 18;
  static const double _verticalPadding = 15;
  static const double _unitGap = 10;

  @override
  Widget build(BuildContext context) {
    final bool isPlaceholder = hours == 0 && minutes == 0;
    final Color valueColor = isPlaceholder
        ? AppColors.gray300
        : AppColors.gray800;

    final Widget card = Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: _verticalPadding,
          ),
          child: SizedBox(
            height: _rowHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  weekLabel,
                  style: AppTypography.headlineBold.copyWith(
                    color: AppColors.gray800,
                  ),
                ),
                _TimeInline(
                  hours: hours,
                  minutes: minutes,
                  valueColor: valueColor,
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
    required this.unitGap,
  });

  final int hours;
  final int minutes;
  final Color valueColor;
  final double unitGap;

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = AppTypography.headlineBold.copyWith(
      color: valueColor,
    );
    final TextStyle unitStyle = AppTypography.headlineRegular.copyWith(
      color: valueColor,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(_twoDigits(hours), style: valueStyle),
        Text('시간', style: unitStyle),
        SizedBox(width: unitGap),
        Text(_twoDigits(minutes), style: valueStyle),
        Text('분', style: unitStyle),
      ],
    );
  }
}
