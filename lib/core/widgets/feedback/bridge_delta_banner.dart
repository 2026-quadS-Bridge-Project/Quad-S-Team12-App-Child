import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Semantic variant for [BridgeDeltaBanner].
///
/// - [over]   → destructive palette (`AppColors.destructiveSubtle` bg,
///              `AppColors.destructive` text), prefix `+`. Indicates the user
///              has over-allocated relative to the weekly budget.
/// - [under]  → primary palette (`AppColors.primaryLight` bg,
///              `AppColors.primary` text), prefix `-`. Indicates remaining /
///              under-allocated time; treated as an informational cue per
///              design (not a destructive error).
enum BridgeDeltaBannerVariant { over, under }

/// Inline, page-level delta pill banner used at the bottom of the daily time
/// distribution list (step 3 of 일별 시간 분배) to communicate how far the
/// user's current allocation is from the weekly budget.
///
/// Figma source: `docs/figma-specs/08c-time-v1-errors-done.md` —
/// frames `695:10675` (초과) and `695:10817` (남음).
///
/// Geometry:
/// - Full content width (caller controls outer width; banner expands via
///   `double.infinity`), height 46.
/// - Radius `AppTokens.errorBannerRadius` (8).
/// - Padding `EdgeInsets.symmetric(horizontal: 17, vertical: 10)`.
/// - Single right-aligned line of text, no icon, no dismiss action.
///
/// Text format: `'$prefix${hours}시간 ${minutes}분 $suffix'` where the
/// caller supplies a localised [suffix] (e.g. `'초과'` for over, `'남음'`
/// for under).
class BridgeDeltaBanner extends StatelessWidget {
  const BridgeDeltaBanner({
    super.key,
    required this.variant,
    required this.hours,
    required this.minutes,
    required this.suffix,
  });

  /// Convenience constructor for the over-budget (초과) variant.
  factory BridgeDeltaBanner.over({
    Key? key,
    required int hours,
    required int minutes,
    String suffix = '초과',
  }) {
    return BridgeDeltaBanner(
      key: key,
      variant: BridgeDeltaBannerVariant.over,
      hours: hours,
      minutes: minutes,
      suffix: suffix,
    );
  }

  /// Convenience constructor for the under-budget (남음) variant.
  factory BridgeDeltaBanner.under({
    Key? key,
    required int hours,
    required int minutes,
    String suffix = '남음',
  }) {
    return BridgeDeltaBanner(
      key: key,
      variant: BridgeDeltaBannerVariant.under,
      hours: hours,
      minutes: minutes,
      suffix: suffix,
    );
  }

  /// Visual + semantic variant. See [BridgeDeltaBannerVariant].
  final BridgeDeltaBannerVariant variant;

  /// Hours portion of the delta. Rendered verbatim (no zero-padding).
  final int hours;

  /// Minutes portion of the delta. Rendered verbatim (no zero-padding).
  final int minutes;

  /// Trailing word describing the delta state, supplied by the caller
  /// (e.g. `'초과'`, `'남음'`).
  final String suffix;

  static const double _height = 46;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 17,
    vertical: 10,
  );

  @override
  Widget build(BuildContext context) {
    final bool isOver = variant == BridgeDeltaBannerVariant.over;
    final Color background = isOver
        ? AppColors.destructiveSubtle
        : AppColors.primaryLight;
    final Color textColor = isOver ? AppColors.destructive : AppColors.primary;
    final String prefix = isOver ? '+' : '-';

    return Container(
      width: double.infinity,
      height: _height,
      padding: _padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.errorBannerRadius),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$prefix$hours시간 $minutes분 $suffix',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySemiBold.copyWith(color: textColor),
        ),
      ),
    );
  }
}
