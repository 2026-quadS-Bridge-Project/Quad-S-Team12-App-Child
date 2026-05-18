import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Visual variant of [BridgeButton].
///
/// Validated against Figma across login/signup/mypage/password_change/home/
/// delete/time/mission screens. See docs/figma-specs/00-CATALOG.md §2.1.
enum BridgeButtonVariant {
  /// Solid primary CTA (e.g. 로그인, 다음, 확인).
  primary,

  /// Tonal/outlined secondary CTA (e.g. dialog 취소).
  outlined,

  /// Soft-surface destructive chip (e.g. mypage 탈퇴하기).
  ///
  /// NOTE: Per Figma, the destructive variant uses a soft red surface with
  /// red text — NOT a solid red background.
  destructive,

  /// Transparent label-only link (e.g. inline navigation).
  textLink,
}

/// Size variant of [BridgeButton].
enum BridgeButtonSize {
  /// 54-height page-level CTA (full-width by default).
  large,

  /// 42-height dialog button (fixed 120 width by default).
  medium,

  /// 35-height chip button (fixed 80 width by default).
  ///
  /// Used for compact action chips such as the mypage 탈퇴하기 button
  /// (Figma node `257:3713` — 80×35, radius 8, caption-bold typography).
  small,
}

/// Reusable button used across the Bridge child app.
///
/// Built with [Material] + [InkWell] (rather than [ElevatedButton] /
/// [OutlinedButton]) so every visual property comes directly from the
/// design tokens without having to fight ThemeData defaults.
///
/// Disabled state is triggered when [onPressed] is `null`.
class BridgeButton extends StatelessWidget {
  const BridgeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BridgeButtonVariant.primary,
    this.size = BridgeButtonSize.large,
    this.fullWidth = true,
    this.leading,
    this.trailing,
  });

  /// Button label text.
  final String label;

  /// Tap handler. Pass `null` to render the disabled state.
  final VoidCallback? onPressed;

  /// Visual variant — see [BridgeButtonVariant].
  final BridgeButtonVariant variant;

  /// Size variant — see [BridgeButtonSize].
  final BridgeButtonSize size;

  /// When `true` (default) the button stretches to fill its parent's width.
  /// For [BridgeButtonSize.medium] dialog buttons this is typically set to
  /// `false` so the natural 120-width applies; [BridgeButtonSize.small]
  /// chips with `fullWidth: false` render at the natural 80-width.
  final bool fullWidth;

  /// Optional icon rendered before the label.
  final Widget? leading;

  /// Optional icon rendered after the label.
  final Widget? trailing;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final _ButtonPalette palette = _resolvePalette();
    final _ButtonMetrics metrics = _resolveMetrics();

    final TextStyle textStyle = metrics.textStyle.copyWith(
      color: palette.foreground,
    );

    final Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (leading != null) ...<Widget>[
          IconTheme.merge(
            data: IconThemeData(color: palette.foreground, size: 20),
            child: leading!,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            style: textStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 8),
          IconTheme.merge(
            data: IconThemeData(color: palette.foreground, size: 20),
            child: trailing!,
          ),
        ],
      ],
    );

    final BorderRadius borderRadius = BorderRadius.circular(
      AppTokens.buttonRadius,
    );

    final Widget tappable = Material(
      color: palette.background,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        splashColor: palette.splash,
        highlightColor: palette.highlight,
        child: Container(
          height: metrics.height,
          width: fullWidth ? double.infinity : metrics.fixedWidth,
          padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: palette.border == null
                ? null
                : Border.all(color: palette.border!, width: 1),
          ),
          alignment: Alignment.center,
          child: content,
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

  _ButtonPalette _resolvePalette() {
    if (!_enabled) {
      // Disabled tokens — spec only defines primary disabled colors.
      // Other variants reuse the same neutral pair for consistency.
      return const _ButtonPalette(
        background: AppColors.gray200,
        foreground: AppColors.gray300,
        border: null,
        splash: Colors.transparent,
        highlight: Colors.transparent,
      );
    }

    switch (variant) {
      case BridgeButtonVariant.primary:
        return _ButtonPalette(
          background: AppColors.primary,
          foreground: AppColors.white,
          border: null,
          splash: AppColors.white.withValues(alpha: 0.16),
          highlight: AppColors.white.withValues(alpha: 0.08),
        );
      case BridgeButtonVariant.outlined:
        return _ButtonPalette(
          background: AppColors.primaryLight,
          foreground: AppColors.primary,
          border: AppColors.primary,
          splash: AppColors.primary.withValues(alpha: 0.12),
          highlight: AppColors.primary.withValues(alpha: 0.06),
        );
      case BridgeButtonVariant.destructive:
        return _ButtonPalette(
          background: AppColors.destructiveSubtle,
          foreground: AppColors.destructive,
          border: null,
          splash: AppColors.destructive.withValues(alpha: 0.12),
          highlight: AppColors.destructive.withValues(alpha: 0.06),
        );
      case BridgeButtonVariant.textLink:
        return _ButtonPalette(
          background: Colors.transparent,
          foreground: AppColors.primary,
          border: null,
          splash: AppColors.primary.withValues(alpha: 0.12),
          highlight: AppColors.primary.withValues(alpha: 0.06),
        );
    }
  }

  _ButtonMetrics _resolveMetrics() {
    // textLink ignores [size] sizing chrome but keeps SemiBold 16 typography
    // for large/medium; small textLinks use the caption-bold ramp.
    if (variant == BridgeButtonVariant.textLink) {
      switch (size) {
        case BridgeButtonSize.large:
          return _ButtonMetrics(
            height: 54,
            fixedWidth: null,
            horizontalPadding: 8,
            textStyle: AppTypography.bodyBold,
          );
        case BridgeButtonSize.medium:
          return _ButtonMetrics(
            height: 42,
            fixedWidth: null,
            horizontalPadding: 8,
            textStyle: AppTypography.bodyBold,
          );
        case BridgeButtonSize.small:
          return _ButtonMetrics(
            height: 35,
            fixedWidth: null,
            horizontalPadding: 8,
            textStyle: AppTypography.captionBold,
          );
      }
    }

    switch (size) {
      case BridgeButtonSize.large:
        return _ButtonMetrics(
          height: 54,
          fixedWidth: null,
          horizontalPadding: 20,
          textStyle: AppTypography.headlineMedium,
        );
      case BridgeButtonSize.medium:
        return _ButtonMetrics(
          height: 42,
          // Dialog buttons are a fixed 120 unless the caller opts into
          // fullWidth (e.g. stacked confirm flows).
          fixedWidth: fullWidth ? null : 120,
          horizontalPadding: 16,
          textStyle: AppTypography.bodyBold,
        );
      case BridgeButtonSize.small:
        // Compact 80×35 chip (Figma mypage 탈퇴하기 257:3713).
        // 12 horizontal / 8 vertical padding around captionBold (12px) text.
        // Vertical padding is implicit via the fixed 35-height container.
        return _ButtonMetrics(
          height: 35,
          fixedWidth: fullWidth ? null : 80,
          horizontalPadding: 12,
          textStyle: AppTypography.captionBold,
        );
    }
  }
}

@immutable
class _ButtonPalette {
  const _ButtonPalette({
    required this.background,
    required this.foreground,
    required this.border,
    required this.splash,
    required this.highlight,
  });

  final Color background;
  final Color foreground;
  final Color? border;
  final Color splash;
  final Color highlight;
}

@immutable
class _ButtonMetrics {
  const _ButtonMetrics({
    required this.height,
    required this.fixedWidth,
    required this.horizontalPadding,
    required this.textStyle,
  });

  final double height;
  final double? fixedWidth;
  final double horizontalPadding;
  final TextStyle textStyle;
}
