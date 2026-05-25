import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Visual variant of [BridgePillIconButton].
///
/// * [tonal] — soft primary surface (used for 수정하기, 자동계산 actions).
/// * [ghost] — transparent surface, neutral foreground (used for
///   `사용리포트 보기` and similar tertiary affordances).
enum BridgePillVariant { tonal, ghost }

/// Small pill-shaped icon+label button (h=32, radius 16, padding 12/0).
///
/// Used for inline secondary actions such as `수정하기`, `자동계산`, and
/// `사용리포트 보기`. Built on [Material] + [InkWell] so disabled / pressed
/// states come straight from the design tokens.
///
/// Figma source: `docs/figma-specs/10-time-confirm.md` (수정하기 pill).
class BridgePillIconButton extends StatelessWidget {
  const BridgePillIconButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = BridgePillVariant.tonal,
  });

  /// Label text shown between any leading / trailing icons.
  final String label;

  /// Tap handler. Pass `null` to render the disabled state.
  final VoidCallback? onPressed;

  /// Optional leading icon, rendered before the label.
  final IconData? icon;

  /// Optional trailing icon, rendered after the label.
  final IconData? trailingIcon;

  /// Visual variant — see [BridgePillVariant].
  final BridgePillVariant variant;

  static const double _height = 32;
  static const double _horizontalPadding = 12;
  static const double _radius = 16;
  static const double _iconSize = 14;
  static const double _gap = 4;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final _PillPalette palette = _resolvePalette();
    final BorderRadius borderRadius = BorderRadius.circular(_radius);

    final TextStyle textStyle = AppTypography.captionSemiBold.copyWith(
      color: palette.foreground,
    );

    final List<Widget> rowChildren = <Widget>[
      if (icon != null) ...<Widget>[
        Icon(icon, size: _iconSize, color: palette.foreground),
        const SizedBox(width: _gap),
      ],
      Text(
        label,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      if (trailingIcon != null) ...<Widget>[
        const SizedBox(width: _gap),
        Icon(trailingIcon, size: _iconSize, color: palette.foreground),
      ],
    ];

    final Widget tappable = Material(
      color: palette.background,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        splashColor: palette.splash,
        highlightColor: palette.highlight,
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: rowChildren,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: label,
      child: tappable,
    );
  }

  _PillPalette _resolvePalette() {
    if (!_enabled) {
      return const _PillPalette(
        background: AppColors.gray200,
        foreground: AppColors.gray300,
        splash: Colors.transparent,
        highlight: Colors.transparent,
      );
    }

    switch (variant) {
      case BridgePillVariant.tonal:
        return _PillPalette(
          background: AppColors.primaryLight,
          foreground: AppColors.primary,
          splash: AppColors.primary.withValues(alpha: 0.12),
          highlight: AppColors.primary.withValues(alpha: 0.06),
        );
      case BridgePillVariant.ghost:
        return _PillPalette(
          background: Colors.transparent,
          foreground: AppColors.gray600,
          splash: AppColors.gray600.withValues(alpha: 0.10),
          highlight: AppColors.gray600.withValues(alpha: 0.05),
        );
    }
  }
}

@immutable
class _PillPalette {
  const _PillPalette({
    required this.background,
    required this.foreground,
    required this.splash,
    required this.highlight,
  });

  final Color background;
  final Color foreground;
  final Color splash;
  final Color highlight;
}
