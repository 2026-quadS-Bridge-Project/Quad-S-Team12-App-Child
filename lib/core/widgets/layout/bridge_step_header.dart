import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'bridge_step_circle.dart';

/// Header block shown at the top of each step in the initial time-setting
/// wizard. Combines a [BridgeStepCircle] with a title row and an optional
/// description paragraph.
///
/// Layout:
/// - Row: circle + title (Heading2/Bold, textPrimary), gap 12.
/// - When [description] is provided: 12px gap then description text
///   (Body/Medium, gray600).
///
/// Spec: docs/figma-specs/08a-time-v1-entry-weekly.md
class BridgeStepHeader extends StatelessWidget {
  const BridgeStepHeader({
    super.key,
    required this.step,
    required this.title,
    this.description,
  });

  /// Step number shown in the leading [BridgeStepCircle].
  final int step;

  /// Title text rendered to the right of the circle.
  final String title;

  /// Optional supporting copy rendered below the title row.
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BridgeStepCircle(number: step),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.heading2Bold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 12),
          Text(
            description!,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.gray600),
          ),
        ],
      ],
    );
  }
}
