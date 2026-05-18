import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../buttons/bridge_button.dart';

/// Reusable confirmation dialog shared by 탈퇴 (account deletion) and
/// 알림 삭제 (notification deletion) flows.
///
/// Figma source: `docs/figma-specs/05-delete.md` and `docs/figma-specs/06-notifications.md`.
///
/// Layout:
///   * Card 328 × 211, white background, 12pt radius, 1px `gray200` border.
///   * Warning icon (32 × 32) centered, 24pt below card top.
///   * Title text 18pt below icon (`AppTypography.bodyBold`).
///   * Optional body text below title (`AppTypography.bodyMedium`, `gray600`).
///   * Two `BridgeButton`s (medium 120 × 42) at the bottom, 15pt gap,
///     24pt above card bottom. Cancel is outlined, Confirm is primary
///     (per Figma — primary blue even for destructive actions).
class BridgeConfirmDialog extends StatelessWidget {
  const BridgeConfirmDialog({
    super.key,
    required this.title,
    this.body,
    this.cancelLabel = '취소',
    this.confirmLabel = '확인',
    this.onCancel,
    this.onConfirm,
  });

  /// Title text (rendered with `AppTypography.bodyBold`).
  final String title;

  /// Optional body text below the title.
  final String? body;

  /// Cancel button label. Defaults to `취소`.
  final String cancelLabel;

  /// Confirm button label. Defaults to `확인`.
  final String confirmLabel;

  /// Tap handler for the cancel button. If null and shown via [show], the
  /// helper wires `Navigator.pop(false)`.
  final VoidCallback? onCancel;

  /// Tap handler for the confirm button. If null and shown via [show], the
  /// helper wires `Navigator.pop(true)`.
  final VoidCallback? onConfirm;

  static const double _cardWidth = 328;
  static const double _cardHeight = 211;
  static const double _topPadding = 24;
  static const double _bottomPadding = 24;
  static const double _iconToTitleGap = 18;
  static const double _titleToBodyGap = 8;
  static const double _buttonGap = 15;
  static const double _iconSize = 32;

  /// Shows the dialog and resolves with `true` (confirm), `false` (cancel),
  /// or `null` (scrim dismiss).
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? body,
    String cancelLabel = '취소',
    String confirmLabel = '확인',
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (dialogContext, _, _) => Center(
        child: BridgeConfirmDialog(
          title: title,
          body: body,
          cancelLabel: cancelLabel,
          confirmLabel: confirmLabel,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        ),
      ),
      transitionBuilder: (_, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: _cardWidth,
        height: _cardHeight,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTokens.dialogRadius),
          border: Border.all(color: AppColors.gray200, width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(24, _topPadding, 24, _bottomPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_buildHeader(), _buildActions()],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _WarningIcon(size: _iconSize),
        const SizedBox(height: _iconToTitleGap),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
        ),
        if (body != null && body!.isNotEmpty) ...[
          const SizedBox(height: _titleToBodyGap),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.gray600),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BridgeButton(
          label: cancelLabel,
          variant: BridgeButtonVariant.outlined,
          size: BridgeButtonSize.medium,
          onPressed: onCancel,
        ),
        const SizedBox(width: _buttonGap),
        BridgeButton(
          label: confirmLabel,
          variant: BridgeButtonVariant.primary,
          size: BridgeButtonSize.medium,
          onPressed: onConfirm,
        ),
      ],
    );
  }
}

/// Renders the 32×32 warning glyph. Tries the bundled SVG asset first; if it
/// is missing (or fails to decode) we fall back to a Material warning icon
/// tinted with `AppColors.cautionary`.
class _WarningIcon extends StatefulWidget {
  const _WarningIcon({required this.size});

  final double size;

  @override
  State<_WarningIcon> createState() => _WarningIconState();
}

class _WarningIconState extends State<_WarningIcon> {
  static const String _assetPath = 'assets/icons/경고.svg';
  static bool? _assetExistsCache;

  late Future<bool> _assetExists;

  @override
  void initState() {
    super.initState();
    _assetExists = _resolveAsset();
  }

  Future<bool> _resolveAsset() async {
    final cached = _assetExistsCache;
    if (cached != null) return cached;
    try {
      await rootBundle.load(_assetPath);
      _assetExistsCache = true;
      return true;
    } catch (_) {
      _assetExistsCache = false;
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FutureBuilder<bool>(
        future: _assetExists,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          if (snapshot.data == true) {
            return SvgPicture.asset(
              _assetPath,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            );
          }
          return Icon(
            Icons.warning_amber_rounded,
            size: widget.size,
            color: AppColors.cautionary,
          );
        },
      ),
    );
  }
}
