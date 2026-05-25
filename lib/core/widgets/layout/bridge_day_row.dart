import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Row card used on the daily time-distribution screen.
///
/// Shares the visual chrome of `BridgeWeekRow` (white card, radius
/// [AppTokens.cardRadiusSmall] = 16, padding 18×15, inner row h=45) and adds:
/// - A vertical divider between the [daysLabel] and the time cluster.
/// - A trailing 24×24 pencil icon (`solar_pen-bold-duotone.svg`, fallback
///   [Icons.edit_outlined]) that serves as a visual edit affordance.
///
/// The entire card is the hit target; the pencil is a non-interactive
/// indicator. When [onEdit] is null the row is rendered read-only and the
/// pencil can be hidden via [showPencil].
///
/// Spec: docs/figma-specs/08b-time-v1-daily.md
class BridgeDayRow extends StatelessWidget {
  const BridgeDayRow({
    super.key,
    required this.daysLabel,
    required this.hours,
    required this.minutes,
    this.onEdit,
    this.showPencil = true,
  });

  /// Days assigned to this allocation, e.g. "월,수,금".
  final String daysLabel;

  /// Hours portion of the allocated time. 0 + 0 minutes => placeholder state.
  final int hours;

  /// Minutes portion of the allocated time. 0 + 0 hours => placeholder state.
  final int minutes;

  /// Optional edit handler. When null the row is rendered read-only (no
  /// [InkWell], no pencil).
  final VoidCallback? onEdit;

  /// Whether to render the trailing pencil icon when [onEdit] is non-null.
  /// Pencil is always hidden when [onEdit] is null.
  final bool showPencil;

  static const double _rowHeight = 45;
  static const double _horizontalPadding = 18;
  static const double _verticalPadding = 15;
  static const double _unitGap = 10;
  static const double _dividerHeight = 22;
  static const double _dividerInset = 12;
  static const double _pencilSize = 24;
  static const String _pencilAsset = 'assets/icons/solar_pen-bold-duotone.svg';

  @override
  Widget build(BuildContext context) {
    final bool isPlaceholder = hours == 0 && minutes == 0;
    final Color valueColor = isPlaceholder
        ? AppColors.gray300
        : AppColors.gray800;
    final bool showTrailingPencil = showPencil && onEdit != null;

    final Widget innerRow = SizedBox(
      height: _rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              daysLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headlineSemiBold.copyWith(
                color: AppColors.gray800,
              ),
            ),
          ),
          const SizedBox(width: _dividerInset),
          Container(width: 1, height: _dividerHeight, color: AppColors.gray200),
          const SizedBox(width: _dividerInset),
          _TimeInline(
            hours: hours,
            minutes: minutes,
            valueColor: valueColor,
            unitGap: _unitGap,
          ),
          const Spacer(),
          if (showTrailingPencil) const _PencilIcon(),
        ],
      ),
    );

    final Widget card = SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: _verticalPadding,
            ),
            child: innerRow,
          ),
        ),
      ),
    );

    return IgnorePointer(ignoring: onEdit == null, child: card);
  }
}

class _PencilIcon extends StatelessWidget {
  const _PencilIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: BridgeDayRow._pencilSize,
      height: BridgeDayRow._pencilSize,
      child: SvgPicture.asset(
        BridgeDayRow._pencilAsset,
        width: BridgeDayRow._pencilSize,
        height: BridgeDayRow._pencilSize,
        fit: BoxFit.contain,
        // Fallback to a material icon if the asset is missing at runtime.
        placeholderBuilder: (_) => const Icon(
          Icons.edit_outlined,
          size: BridgeDayRow._pencilSize,
          color: AppColors.gray800,
        ),
      ),
    );
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
    final TextStyle valueStyle = AppTypography.headlineSemiBold.copyWith(
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
