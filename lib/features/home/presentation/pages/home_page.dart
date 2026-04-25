import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

const TextStyle _bridgeTitleStyle = TextStyle(
  color: Color(0xFF6DB5FF),
  fontFamily: 'Sigmar',
  fontFamilyFallback: <String>[AppTypography.fontFamily],
  fontSize: 40,
  fontStyle: FontStyle.normal,
  fontWeight: FontWeight.w400,
  height: 1.364,
  letterSpacing: -0.776,
);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.gray050,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppTokens.mobileFrameWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.mobileHorizontalPadding,
                    ),
                    child: Column(
                      children: [
                        const Expanded(
                          child: Align(
                            alignment: Alignment(0, -0.08),
                            child: _IntroContent(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _BottomActions(
                            isCompact: constraints.maxHeight < 700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IntroContent extends StatelessWidget {
  const _IntroContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Bridge', textAlign: TextAlign.center, style: _bridgeTitleStyle),
        const SizedBox(height: 20),
        const _BridgeIcon(),
        const SizedBox(height: 28),
        Text(
          '통제를 넘어 자율로,\n자기주도적 스마트폰 사용의 시작',
          textAlign: TextAlign.center,
          style: AppTypography.heading2Regular.copyWith(
            color: AppColors.gray600,
            letterSpacing: -0.24,
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.push('/signup'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: AppTypography.headlineMedium.copyWith(
                color: AppColors.white,
                letterSpacing: -0.02,
              ),
            ),
            child: const Text('자녀 회원가입'),
          ),
        ),
        SizedBox(height: isCompact ? 14 : 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '이미 계정이 있나요?',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray400,
                letterSpacing: 0.09,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/login'),
              child: Text(
                '로그인',
                style: AppTypography.bodyBold.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 0.09,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BridgeIcon extends StatelessWidget {
  const _BridgeIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/Icon Container.svg',
      width: 99,
      height: 98,
      fit: BoxFit.contain,
    );
  }
}
