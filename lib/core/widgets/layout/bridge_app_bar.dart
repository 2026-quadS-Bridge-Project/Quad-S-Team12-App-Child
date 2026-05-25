import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Standard top bar used across mypage, password_change, mission info,
/// time settings, and similar secondary screens.
///
/// Layout (Stack):
/// - Left: 24x24 back chevron at 14px from the left edge
/// - Center: title text, centered on both axes
/// - Right: optional [trailing] widget at 14px from the right edge
///
/// Spec: docs/figma-specs/03-mypage.md (Cmp/topbar 325:17287)
/// Height: [AppTokens.topBarHeight] (52)
class BridgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BridgeAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.showBack = true,
  });

  /// Title shown centered. Rendered with [AppTypography.headlineMedium].
  final String title;

  /// Override for back button tap. When null, defaults to `context.pop()`.
  final VoidCallback? onBack;

  /// Optional trailing widget anchored to the right edge.
  final Widget? trailing;

  /// Hides the back button entirely when false.
  final bool showBack;

  /// Visual edge inset so the 24px back icon sits 14px from the left edge.
  /// The hit target is 44px wide (Material / HIG minimum) and centred on
  /// the icon, so the wrapping box is positioned at
  /// `_edgeInset - (_backHitSize - _backIconSize) / 2` = 4 from the edge.
  static const double _edgeInset = 14;
  static const double _backIconSize = 24;
  static const double _backHitSize = 44;
  static const double _backHitOffset =
      _edgeInset - (_backHitSize - _backIconSize) / 2;
  static const String _backAssetPath = 'assets/icons/cmp/btn/back.svg';

  /// Status-bar inset read from the platform view at preferredSize time.
  ///
  /// `PreferredSizeWidget.preferredSize` is a context-free getter, so we
  /// cannot use `MediaQuery.of(context)` here. We instead read the OS-level
  /// view padding via [WidgetsBinding.instance.platformDispatcher], which is
  /// always valid once the app is running. This matches the pattern Material
  /// `AppBar` uses internally to size itself for the notch / status bar.
  static double get _topInset {
    final view = WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
        ? WidgetsBinding.instance.platformDispatcher.views.first
        : null;
    if (view == null) return 0;
    return view.padding.top / view.devicePixelRatio;
  }

  @override
  Size get preferredSize => Size.fromHeight(AppTokens.topBarHeight + _topInset);

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.only(top: topInset),
      child: SizedBox(
        height: AppTokens.topBarHeight,
        width: double.infinity,
        child: Stack(
          children: [
            // Centered title
            Center(
              child: Text(
                title,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Leading back button. Positioned at _backHitOffset (4px) so the
            // 44px hit box centres the 24px icon at the 14px visual inset.
            if (showBack)
              Positioned(
                left: _backHitOffset,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _BackButton(onTap: onBack ?? () => context.pop()),
                ),
              ),
            // Trailing slot
            if (trailing != null)
              Positioned(
                right: _edgeInset,
                top: 0,
                bottom: 0,
                child: Center(child: trailing!),
              ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 44×44 hit zone (Material / HIG minimum tappable size) wrapping a
    // visually centred 24×24 icon. InkResponse splash radius matches the
    // hit-zone radius so feedback covers the full tap target.
    return Semantics(
      button: true,
      label: 'Back',
      child: SizedBox(
        width: BridgeAppBar._backHitSize,
        height: BridgeAppBar._backHitSize,
        child: InkResponse(
          onTap: onTap,
          radius: BridgeAppBar._backHitSize / 2,
          containedInkWell: false,
          child: Center(
            child: SizedBox(
              width: BridgeAppBar._backIconSize,
              height: BridgeAppBar._backIconSize,
              child: SvgPicture.asset(
                BridgeAppBar._backAssetPath,
                width: BridgeAppBar._backIconSize,
                height: BridgeAppBar._backIconSize,
                fit: BoxFit.contain,
                // If the asset is ever missing at runtime, flutter_svg throws.
                // We catch with a placeholder to avoid crashing the whole screen.
                placeholderBuilder: (_) => const SizedBox(
                  width: BridgeAppBar._backIconSize,
                  height: BridgeAppBar._backIconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
