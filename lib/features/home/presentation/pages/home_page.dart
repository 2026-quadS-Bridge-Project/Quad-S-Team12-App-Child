import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            onPressed: () {},
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
              onTap: () {},
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
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFADD5FF),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(1, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(painter: _BridgeIconPainter()),
            ),
          ),
          Positioned(
            right: 7,
            bottom: 6,
            child: Text(
              'K',
              style: AppTypography.captionMedium.copyWith(
                color: AppColors.white.withValues(alpha: 0.5),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BridgeIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = const Color(0xFFC2DFFD)
      ..style = PaintingStyle.fill;
    final Paint linePaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final Path leftWave = Path()
      ..moveTo(0, size.height * 0.74)
      ..cubicTo(
        size.width * 0.10,
        size.height * 0.74,
        size.width * 0.13,
        size.height * 0.67,
        size.width * 0.19,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.44,
        size.width * 0.31,
        size.height * 0.36,
        size.width * 0.39,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.47,
        size.height * 0.36,
        size.width * 0.53,
        size.height * 0.42,
        size.width * 0.62,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.48,
        size.height * 0.32,
        size.width * 0.35,
        size.height * 0.27,
        size.width * 0.23,
        size.height * 0.27,
      )
      ..cubicTo(
        size.width * 0.13,
        size.height * 0.27,
        size.width * 0.05,
        size.height * 0.32,
        0,
        size.height * 0.43,
      )
      ..lineTo(0, size.height * 0.74)
      ..close();

    final Path rightWave = Path()
      ..moveTo(size.width * 0.26, size.height * 0.51)
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.60,
        size.width * 0.36,
        size.height * 0.67,
        size.width * 0.42,
        size.height * 0.74,
      )
      ..cubicTo(
        size.width * 0.48,
        size.height * 0.79,
        size.width * 0.56,
        size.height * 0.82,
        size.width * 0.71,
        size.height * 0.82,
      )
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.82,
        size.width * 0.89,
        size.height * 0.76,
        size.width,
        size.height * 0.43,
      )
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.31,
        size.width * 0.86,
        size.height * 0.27,
        size.width * 0.78,
        size.height * 0.27,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.27,
        size.width * 0.58,
        size.height * 0.31,
        size.width * 0.46,
        size.height * 0.49,
      )
      ..lineTo(size.width * 0.26, size.height * 0.51)
      ..close();

    final Path centerWave = Path()
      ..moveTo(size.width * 0.44, size.height * 0.58)
      ..cubicTo(
        size.width * 0.49,
        size.height * 0.68,
        size.width * 0.57,
        size.height * 0.72,
        size.width * 0.66,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.72,
        size.width * 0.84,
        size.height * 0.67,
        size.width * 0.93,
        size.height * 0.60,
      )
      ..lineTo(size.width, size.height * 0.74)
      ..lineTo(size.width, size.height * 0.82)
      ..cubicTo(
        size.width * 0.93,
        size.height * 0.81,
        size.width * 0.87,
        size.height * 0.78,
        size.width * 0.80,
        size.height * 0.71,
      )
      ..cubicTo(
        size.width * 0.73,
        size.height * 0.60,
        size.width * 0.64,
        size.height * 0.54,
        size.width * 0.49,
        size.height * 0.54,
      )
      ..cubicTo(
        size.width * 0.45,
        size.height * 0.54,
        size.width * 0.41,
        size.height * 0.55,
        size.width * 0.36,
        size.height * 0.57,
      );

    final Path leftLine = Path()
      ..moveTo(0, size.height * 0.74)
      ..cubicTo(
        size.width * 0.10,
        size.height * 0.74,
        size.width * 0.13,
        size.height * 0.67,
        size.width * 0.19,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.44,
        size.width * 0.31,
        size.height * 0.36,
        size.width * 0.39,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.47,
        size.height * 0.36,
        size.width * 0.53,
        size.height * 0.42,
        size.width * 0.62,
        size.height * 0.58,
      );

    final Path rightLine = Path()
      ..moveTo(size.width * 0.26, size.height * 0.51)
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.60,
        size.width * 0.36,
        size.height * 0.67,
        size.width * 0.42,
        size.height * 0.74,
      )
      ..cubicTo(
        size.width * 0.48,
        size.height * 0.79,
        size.width * 0.56,
        size.height * 0.82,
        size.width * 0.71,
        size.height * 0.82,
      )
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.82,
        size.width * 0.89,
        size.height * 0.76,
        size.width,
        size.height * 0.43,
      );

    final Path centerLine = Path()
      ..moveTo(size.width * 0.44, size.height * 0.58)
      ..cubicTo(
        size.width * 0.49,
        size.height * 0.68,
        size.width * 0.57,
        size.height * 0.72,
        size.width * 0.66,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.72,
        size.width * 0.84,
        size.height * 0.67,
        size.width * 0.93,
        size.height * 0.60,
      );

    canvas.drawPath(leftWave, fillPaint);
    canvas.drawPath(rightWave, fillPaint);
    canvas.drawPath(centerWave, fillPaint);

    canvas.drawPath(leftLine, linePaint);
    canvas.drawPath(rightLine, linePaint);
    canvas.drawPath(centerLine, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
