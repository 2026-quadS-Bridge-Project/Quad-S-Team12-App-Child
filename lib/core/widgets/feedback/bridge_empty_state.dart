import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Compact, centered empty-state placeholder used across screens whose primary
/// content list is empty.
///
/// Figma sources:
/// - `docs/figma-specs/06-notifications.md` (text-only empty state in the
///   알림 tab when no notifications exist).
/// - `docs/figma-specs/10-time-confirm.md` (시간규칙 미설정 empty state shown
///   inside the time-confirm sheet when no time rule has been configured).
///
/// The widget centers its content and lays out (top → bottom):
///   1. Optional [icon] (32px, [AppColors.gray400]) with a 12px gap below.
///   2. The [message] text (supports `\n` for multi-line copy), centered.
///   3. Optional [action] widget (e.g. a `BridgeButton`) with a 24px gap above.
class BridgeEmptyState extends StatelessWidget {
  const BridgeEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.action,
    this.messageStyle,
  });

  /// Empty-state copy. Centered and supports explicit `\n` line breaks.
  final String message;

  /// Optional leading icon rendered above the message.
  final IconData? icon;

  /// Optional widget (typically a button) rendered below the message.
  final Widget? action;

  /// Optional override for the message text style. Defaults to
  /// `AppTypography.bodyMedium` in `AppColors.gray500`.
  final TextStyle? messageStyle;

  static const double _iconSize = 32;
  static const double _iconGap = 12;
  static const double _actionGap = 24;

  @override
  Widget build(BuildContext context) {
    final IconData? leadingIcon = icon;
    final Widget? trailingAction = action;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: _iconSize, color: AppColors.gray400),
            const SizedBox(height: _iconGap),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                messageStyle ??
                AppTypography.bodyMedium.copyWith(color: AppColors.gray500),
          ),
          if (trailingAction != null) ...[
            const SizedBox(height: _actionGap),
            trailingAction,
          ],
        ],
      ),
    );
  }
}
