import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

enum BridgeTotalTimeCardVariant { standard, compact }

/// Read-only total time display used at the top of weekly time distribution
/// screens.
///
/// Standard layout:
/// - Outer [Container] with white background, [AppTokens.cardRadiusSmall]
///   corners, and [AppTokens.cardPadding] padding.
/// - Row arranged via [MainAxisAlignment.spaceBetween]:
///   - Leading [Column] (start-aligned): optional [title] above the inline
///     number row.
///   - Optional [trailing] slot on the right edge (e.g. a small "수정" button).
///
/// Compact layout:
/// - Optional section title row above a 50px bordered time box.
/// - Inline "{hours} 시간 {minutes} 분" centered with 18px typography.
///
/// Spec: docs/figma-specs/08a-time-v1-entry-weekly.md
class BridgeTotalTimeCard extends StatelessWidget {
  const BridgeTotalTimeCard({
    super.key,
    required this.hours,
    required this.minutes,
    this.title,
    this.trailing,
    this.variant = BridgeTotalTimeCardVariant.standard,
  });

  /// Hour value rendered in the leading number slot.
  final int hours;

  /// Minute value rendered in the trailing number slot.
  final int minutes;

  /// Optional label rendered above the number row.
  final String? title;

  /// Optional widget rendered at the right edge of the card.
  final Widget? trailing;

  /// Visual treatment for the time display.
  final BridgeTotalTimeCardVariant variant;

  static const double _compactHeight = 50;
  static const double _compactRadius = 12;
  static const double _compactBorderWidth = 2;
  static const double _compactTitleGap = 12;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      BridgeTotalTimeCardVariant.standard => _buildStandard(),
      BridgeTotalTimeCardVariant.compact => _buildCompact(),
    };
  }

  Widget _buildStandard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
      ),
      padding: const EdgeInsets.all(AppTokens.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$hours',
                      style: AppTypography.heading1SemiBold.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '시간',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.gray800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$minutes',
                      style: AppTypography.heading1SemiBold.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '분',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.gray800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }

  Widget _buildCompact() {
    final Widget timeBox = SizedBox(
      height: _compactHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.gray200,
            width: _compactBorderWidth,
          ),
          borderRadius: BorderRadius.circular(_compactRadius),
        ),
        child: Center(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            mainAxisSize: MainAxisSize.min,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _compactHourText(hours),
                style: AppTypography.headlineSemiBold.copyWith(
                  color: AppColors.inkBlack,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '시간',
                style: AppTypography.headlineRegular.copyWith(
                  color: AppColors.inkBlack,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _twoDigits(minutes),
                style: AppTypography.headlineSemiBold.copyWith(
                  color: AppColors.inkBlack,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '분',
                style: AppTypography.headlineRegular.copyWith(
                  color: AppColors.inkBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (title == null && trailing == null) {
      return timeBox;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title != null)
              Expanded(
                child: Text(
                  title!,
                  style: AppTypography.heading2Bold.copyWith(
                    color: AppColors.gray800,
                  ),
                ),
              )
            else
              const Spacer(),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
        const SizedBox(height: _compactTitleGap),
        timeBox,
      ],
    );
  }

  static String _compactHourText(int value) {
    if (value == 0) return _twoDigits(value);
    return '$value';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
