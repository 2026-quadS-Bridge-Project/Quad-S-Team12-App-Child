import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

class ChildHomePage extends StatefulWidget {
  const ChildHomePage({super.key, this.showOnboarding = false});

  final bool showOnboarding;

  @override
  State<ChildHomePage> createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> {
  late bool _showOnboarding = widget.showOnboarding;

  @override
  void didUpdateWidget(covariant ChildHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showOnboarding != widget.showOnboarding) {
      _showOnboarding = widget.showOnboarding;
    }
  }

  void _dismissOnboarding() {
    if (!_showOnboarding) {
      return;
    }
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _showOnboarding
            ? AppColors.gray050
            : AppColors.gray100,
        body: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTokens.mobileFrameWidth,
                ),
                child: SafeArea(
                  bottom: false,
                  child: _ChildHomeContent(onboarding: _showOnboarding),
                ),
              ),
            ),
            if (_showOnboarding)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _dismissOnboarding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppTokens.mobileFrameWidth,
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: const [_ParentConnectGuide()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChildHomeContent extends StatelessWidget {
  const _ChildHomeContent({required this.onboarding});

  final bool onboarding;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double visibleHeight =
        MediaQuery.sizeOf(context).height - padding.top - padding.bottom;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: visibleHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const _TopBar(),
              SizedBox(height: onboarding ? 29 : 20),
              Opacity(
                opacity: onboarding ? 0.2 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TodayTimeSection(),
                    SizedBox(height: onboarding ? 46 : 50),
                    _MissionSection(onboardingCopy: onboarding),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _MyPageButton(),
          Icon(
            Icons.notifications_none_rounded,
            size: 30,
            color: AppColors.gray900,
          ),
        ],
      ),
    );
  }
}

class _MyPageButton extends StatelessWidget {
  const _MyPageButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 26,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.gray800, width: 2)),
        ),
        child: Center(
          child: Text(
            'my',
            style: AppTypography.labelRegular.copyWith(
              color: AppColors.gray800,
              fontSize: 14,
              height: 1.429,
              letterSpacing: 0.203,
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayTimeSection extends StatelessWidget {
  const _TodayTimeSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 223,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Row(
              children: [
                Text(
                  '오늘의 시간',
                  style: AppTypography.heading2Bold.copyWith(
                    color: AppColors.black,
                    letterSpacing: -0.24,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.settings, color: AppColors.gray300, size: 22),
                const Spacer(),
                Text(
                  '사용 리포트',
                  style: AppTypography.labelBold.copyWith(
                    color: AppColors.gray400,
                    fontSize: 14,
                    height: 1.429,
                    letterSpacing: 0.203,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 48,
            height: 175,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80D9D9D9),
                    offset: Offset(0, 4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Center(child: _AddCircleButton()),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCircleButton extends StatelessWidget {
  const _AddCircleButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFEBF5FE),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 30),
    );
  }
}

class _MissionSection extends StatelessWidget {
  const _MissionSection({required this.onboardingCopy});

  final bool onboardingCopy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: onboardingCopy ? 367 : 281,
      width: double.infinity,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                onboardingCopy ? '미션 현황' : '오늘의 미션',
                style: AppTypography.heading2Bold.copyWith(
                  color: AppColors.black,
                  letterSpacing: -0.24,
                ),
              ),
              if (onboardingCopy) ...[
                const SizedBox(width: 8),
                const Icon(Icons.settings, color: AppColors.gray300, size: 22),
              ],
              if (!onboardingCopy) ...[
                const Spacer(),
                Text(
                  '0개 완료',
                  style: AppTypography.labelBold.copyWith(
                    color: AppColors.gray700,
                    fontSize: 14,
                    height: 1.429,
                    letterSpacing: 0.203,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 14, color: AppColors.gray200),
                const SizedBox(width: 8),
                Text(
                  '0',
                  style: AppTypography.labelBold.copyWith(
                    color: AppColors.gray200,
                    fontSize: 14,
                    height: 1.429,
                    letterSpacing: 0.203,
                  ),
                ),
              ],
            ],
          ),
          Positioned(
            top: onboardingCopy ? 88 : 78,
            left: 0,
            right: 0,
            child: Text(
              onboardingCopy ? '부모님이 아직 미션을 등록하지 않았어요' : '아직 등록된 미션이 없어요',
              textAlign: TextAlign.center,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.gray500,
                fontSize: 14,
                height: 1.429,
                letterSpacing: 0.203,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentConnectGuide extends StatelessWidget {
  const _ParentConnectGuide();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 62,
      top: 21,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Padding(padding: EdgeInsets.only(top: 12), child: _GuidePointer()),
          _GuideBubble(),
        ],
      ),
    );
  }
}

class _GuidePointer extends StatelessWidget {
  const _GuidePointer();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _GuidePointerClipper(),
      child: Container(width: 11, height: 14, color: const Color(0xFFE1F0FE)),
    );
  }
}

class _GuideBubble extends StatelessWidget {
  const _GuideBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 204,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F0FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _GuideStepBadge(),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '부모님 계정과 연결하기',
                    maxLines: 1,
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                      height: 1.334,
                      letterSpacing: 0.302,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'my 버튼에서 자녀 코드를 확인해\n부모님 계정과 연결해 주세요.',
            style: AppTypography.captionRegular.copyWith(
              color: AppColors.gray600,
              fontSize: 12,
              height: 1.334,
              letterSpacing: 0.302,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStepBadge extends StatelessWidget {
  const _GuideStepBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFFC2DFFD),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '1',
          style: AppTypography.captionBold.copyWith(
            color: AppColors.primary,
            fontSize: 12,
            height: 1.334,
            letterSpacing: 0.302,
          ),
        ),
      ),
    );
  }
}

class _GuidePointerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
