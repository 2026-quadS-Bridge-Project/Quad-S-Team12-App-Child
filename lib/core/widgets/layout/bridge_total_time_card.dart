import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Read-only total time display used at the top of weekly time distribution
/// screens. Renders an inline "{hours} 시간 {minutes} 분" string with the
/// numeric values emphasised in the primary color.
///
/// Layout:
/// - Outer [Container] with white background, [AppTokens.cardRadiusSmall]
///   corners, and [AppTokens.cardPadding] padding.
/// - Row arranged via [MainAxisAlignment.spaceBetween]:
///   - Leading [Column] (start-aligned): optional [title] above the inline
///     number row.
///   - Optional [trailing] slot on the right edge (e.g. a small "수정" button).
///
/// Spec: docs/figma-specs/08a-time-v1-entry-weekly.md
class BridgeTotalTimeCard extends StatelessWidget {
  const BridgeTotalTimeCard({
    super.key,
    required this.hours,
    required this.minutes,
    this.title,
    this.trailing,
  });

  /// Hour value rendered in the leading number slot.
  final int hours;

  /// Minute value rendered in the trailing number slot.
  final int minutes;

  /// Optional label rendered above the number row.
  final String? title;

  /// Optional widget rendered at the right edge of the card.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
                      style: AppTypography.heading1Bold.copyWith(
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
                      style: AppTypography.heading1Bold.copyWith(
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
}
