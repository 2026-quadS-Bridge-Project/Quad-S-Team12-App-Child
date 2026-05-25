import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';

/// Step 3 completion / success screen ("완료" / `695:12086`).
///
/// Full-bleed celebration layout — no [BridgeAppBar] per the Figma spec.
/// Vertically centered hero stack (check circle + title + body) above a
/// single primary CTA that exits the wizard back to the child home.
class TimeSetupCompletePage extends StatelessWidget {
  const TimeSetupCompletePage({super.key});

  static const double _checkCircleSize = 60;
  static const double _checkIconSize = 32;

  @override
  Widget build(BuildContext context) {
    // Per Figma spec (09-time-v2.md frame 750-13624) and audit phase 5:
    // v2-9 copy is identical to v1 — title `시간 설정 완료!` and body
    // `이번주 시간 계획이 부모님께 전달되었어요.\n이제 계획대로 사용해봐요!`.
    // Controller mode is no longer used to gate copy; both v1 and v2NextWeek
    // share the same completion strings.
    const title = '시간 설정 완료!';
    const body = '이번주 시간 계획이 부모님께 전달되었어요.\n이제 계획대로 사용해봐요!';

    return Scaffold(
      backgroundColor: AppColors.gray050,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                title,
                style: AppTypography.heading1SemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              // Hero stack gaps per Figma 08c 695:12086 §"Main container"
              // line 195: vertical gap = 40 between title / icon / message.
              const SizedBox(height: 40),
              // 60×60 primary-filled circle with a white check mark — the
              // reusable "success" hero icon used on completion screens.
              Center(
                child: Container(
                  width: _checkCircleSize,
                  height: _checkCircleSize,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: AppColors.white,
                      size: _checkIconSize,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                body,
                style: AppTypography.bodySemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              BridgeButton(
                label: '홈으로',
                variant: BridgeButtonVariant.primary,
                size: BridgeButtonSize.large,
                fullWidth: true,
                onPressed: () => context.go('/child-home'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
