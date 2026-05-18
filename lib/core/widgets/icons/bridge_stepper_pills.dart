import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A row of pill-shaped step indicators used at the top of multi-step flows
/// such as the weekly time-setup screens (see
/// `docs/figma-specs/08a-time-v1-entry-weekly.md`).
///
/// Pills are laid out horizontally with an 8 logical pixel gap between them.
/// Each pill colour reflects its state relative to [currentStep] (1-indexed):
/// the current pill uses [AppColors.primarySubtle] (`#C2DFFD`), while both
/// completed and upcoming pills use [AppColors.gray150] (`#EDEEF1`). This
/// matches the Figma spec (08a `695:8924` §Colors and `695:11870` §Layout
/// line 240: "this Figma uses gray150 for past steps, primarySubtle for
/// current").
class BridgeStepperPills extends StatelessWidget {
  const BridgeStepperPills({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    this.pillWidth = 55,
    this.pillHeight = 7,
  });

  /// 1-indexed position of the active step.
  final int currentStep;

  /// Total number of pills in the row.
  final int totalSteps;

  /// Width of each individual pill in logical pixels.
  final double pillWidth;

  /// Height of each individual pill in logical pixels.
  final double pillHeight;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(pillHeight / 2);
    final children = <Widget>[];

    for (var i = 0; i < totalSteps; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: _gap));
      }

      final Color color;
      if (i == currentStep - 1) {
        color = AppColors.primarySubtle;
      } else {
        color = AppColors.gray150;
      }

      children.add(
        Container(
          width: pillWidth,
          height: pillHeight,
          decoration: BoxDecoration(color: color, borderRadius: radius),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
