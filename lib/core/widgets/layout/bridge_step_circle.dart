import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Small numbered badge used to mark a step in the initial time-setting
/// wizard (entry / weekly / daily flow).
///
/// Visual:
/// - Circle of [size] (default 28) filled with [AppColors.primarySubtle].
/// - Centered number rendered with [AppTypography.bodyBold] in
///   [AppColors.primary].
///
/// Spec: docs/figma-specs/08a-time-v1-entry-weekly.md
class BridgeStepCircle extends StatelessWidget {
  const BridgeStepCircle({super.key, required this.number, this.size = 28});

  /// Step number rendered inside the circle (1-based).
  final int number;

  /// Diameter of the circle in logical pixels. Defaults to 28.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primarySubtle,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: AppTypography.bodyBold.copyWith(color: AppColors.primary),
      ),
    );
  }
}
