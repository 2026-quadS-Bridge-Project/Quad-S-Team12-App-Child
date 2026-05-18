import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../../../core/widgets/layout/bridge_step_circle.dart';
import '../../state/time_setup_controller.dart';
import '../../state/time_setup_scope.dart';

/// v2 intro / splash screen shown before entering the 3-step next-week
/// edit wizard.
///
/// Per Figma `750:13034` (docs/figma-specs/09-time-v2.md §v2-1), the v2
/// flow opens with a dedicated description screen listing the three
/// upcoming steps and a single `시작` CTA. Tapping the CTA advances the
/// controller to [TimeSetupStep.scheduleRegister].
///
/// This page is v2-only — the v1 root constructs the controller directly
/// into [TimeSetupStep.scheduleRegister] and never reaches intro.
class TimeSetupIntroPage extends StatelessWidget {
  const TimeSetupIntroPage({super.key});

  // Step labels verbatim per Figma 08a 695:8850 (nodes 695:8862 / 695:8865 /
  // 695:8868).
  static const List<({int number, String label})> _steps = [
    (number: 1, label: '스케줄 등록'),
    (number: 2, label: '주별 시간 분배'),
    (number: 3, label: '일별 시간 분배'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = TimeSetupScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BridgeAppBar(title: '시간 설정'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Title verbatim per Figma 695:8857.
              Text(
                '사용시간 설정',
                style: AppTypography.heading1Bold.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // 2-line subtitle verbatim per Figma 695:8858, gap=40 per spec.
              Text(
                '한 달 동안 쓸 시간을, 스스로 나눠볼거에요\n3단계만 따라오면 끝나요',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              for (int i = 0; i < _steps.length; i++) ...[
                _StepRow(number: _steps[i].number, label: _steps[i].label),
                if (i != _steps.length - 1) const SizedBox(height: 20),
              ],
              const Spacer(),
              BridgeButton(
                label: '시작',
                variant: BridgeButtonVariant.primary,
                size: BridgeButtonSize.large,
                fullWidth: true,
                onPressed: () =>
                    controller.goToStep(TimeSetupStep.scheduleRegister),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.label});

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BridgeStepCircle(number: number),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.gray600),
          ),
        ),
      ],
    );
  }
}
