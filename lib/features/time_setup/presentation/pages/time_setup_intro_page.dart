import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../../../core/widgets/layout/bridge_step_circle.dart';
import '../../state/time_setup_controller.dart';
import '../../state/time_setup_scope.dart';

/// Intro / splash screen shown before entering the 3-step time setup wizard.
///
/// Per Figma `695:8850` (v1) and `750:13034` (v2), both flows open with a
/// dedicated description screen listing the three upcoming steps and a single
/// `시작` CTA. Tapping the CTA advances the controller to
/// [TimeSetupStep.scheduleRegister].
class TimeSetupIntroPage extends StatelessWidget {
  const TimeSetupIntroPage({super.key});

  // Step labels verbatim per Figma 08a 695:8850 (nodes 695:8862 / 695:8865 /
  // 695:8868).
  static const List<({int number, String label})> _steps = [
    (number: 1, label: '스케줄 등록'),
    (number: 2, label: '주별 시간 분배'),
    (number: 3, label: '일별 시간 분배'),
  ];

  static const String _v1Subtitle = '한 달 동안 쓸 시간을, 스스로 나눠볼거에요\n3단계만 따라오면 끝나요';
  static const String _v2Subtitle = '저번주 피드백을 고려해서\n더 나아진 이번주 계획을 짜봐요!';

  @override
  Widget build(BuildContext context) {
    final controller = TimeSetupScope.of(context);
    final String subtitle = switch (controller.mode) {
      TimeSetupMode.v1Initial => _v1Subtitle,
      TimeSetupMode.v2NextWeek => _v2Subtitle,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BridgeAppBar(title: ''),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 109),
              Text(
                '사용시간 설정',
                style: AppTypography.heading1Bold.copyWith(
                  color: AppColors.inkBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 42),
              Align(
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < _steps.length; i++) ...[
                      _StepRow(
                        number: _steps[i].number,
                        label: _steps[i].label,
                      ),
                      if (i != _steps.length - 1) const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BridgeStepCircle(number: number),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.headlineBold.copyWith(color: AppColors.gray500),
        ),
      ],
    );
  }
}
