import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

class ChildHomePage extends StatefulWidget {
  const ChildHomePage({
    super.key,
    this.showOnboarding = false,
    this.showContent = true,
  });

  final bool showOnboarding;
  final bool showContent;

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
                  child: _ChildHomeContent(
                    onboarding: _showOnboarding,
                    hasContent: widget.showContent,
                  ),
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
  const _ChildHomeContent({required this.onboarding, required this.hasContent});

  final bool onboarding;
  final bool hasContent;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double visibleHeight =
        MediaQuery.sizeOf(context).height - padding.top - padding.bottom;

    return SingleChildScrollView(
      physics: hasContent
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: visibleHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _TopBar(hasNotification: hasContent),
              SizedBox(height: onboarding ? 29 : (hasContent ? 30 : 20)),
              Opacity(
                opacity: onboarding ? 0.2 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TodayTimeSection(hasContent: hasContent),
                    SizedBox(height: onboarding ? 46 : 50),
                    _MissionSection(
                      emptyOnboardingCopy: onboarding,
                      hasContent: hasContent,
                    ),
                    if (hasContent) const SizedBox(height: 32),
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
  const _TopBar({required this.hasNotification});

  final bool hasNotification;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _MyPageButton(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 30,
                color: AppColors.gray900,
              ),
              if (hasNotification)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.destructive,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
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
    return GestureDetector(
      onTap: () => context.push('/mypage'),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 26,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.gray800, width: 2),
            ),
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
      ),
    );
  }
}

class _TodayTimeSection extends StatelessWidget {
  const _TodayTimeSection({required this.hasContent});

  final bool hasContent;

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
                if (!hasContent) ...[
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
              child: hasContent
                  ? const _TimeSummaryContent()
                  : const Center(child: _AddCircleButton()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSummaryContent extends StatelessWidget {
  const _TimeSummaryContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Row(
        children: const [
          _TimeDonutChart(),
          SizedBox(width: 40),
          _TimeDetails(),
        ],
      ),
    );
  }
}

class _TimeDonutChart extends StatelessWidget {
  const _TimeDonutChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      height: 124,
      child: CustomPaint(painter: _TimeDonutChartPainter()),
    );
  }
}

class _TimeDonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    const double startAngle = -1.57079632679;

    void drawRing({
      required double radius,
      required double strokeWidth,
      required Color baseColor,
      required Color progressColor,
      required double progress,
    }) {
      final Rect rect = Rect.fromCircle(center: center, radius: radius);
      final Paint basePaint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      final Paint progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, 0, 6.28318530718, false, basePaint);
      canvas.drawArc(
        rect,
        startAngle,
        6.28318530718 * progress,
        false,
        progressPaint,
      );
    }

    drawRing(
      radius: 55,
      strokeWidth: 14,
      baseColor: const Color(0xFFEDEEF1),
      progressColor: AppColors.primary,
      progress: 0.76,
    );
    drawRing(
      radius: 39,
      strokeWidth: 11,
      baseColor: const Color(0xFFEDEEF1),
      progressColor: const Color(0xFFFFBF00),
      progress: 0.78,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TimeDetails extends StatelessWidget {
  const _TimeDetails();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 101,
      height: 124,
      child: Stack(
        children: const [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: _TimeDetailGroup(
              label: '기본시간',
              value: '01:30',
              color: AppColors.primary,
            ),
          ),
          Positioned(
            left: 0,
            top: 72,
            right: 0,
            child: _TimeDetailGroup(
              label: '보너스시간',
              value: '00:30',
              color: Color(0xFFFFBF00),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeDetailGroup extends StatelessWidget {
  const _TimeDetailGroup({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontSize: 14,
              height: 1.429,
              letterSpacing: 0.203,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.heading1Bold.copyWith(
              color: color,
              fontSize: 24,
              height: 1.364,
              letterSpacing: -0.466,
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
  const _MissionSection({
    required this.emptyOnboardingCopy,
    required this.hasContent,
  });

  final bool emptyOnboardingCopy;
  final bool hasContent;

  @override
  Widget build(BuildContext context) {
    if (hasContent) {
      return const _MissionListSection();
    }

    return SizedBox(
      height: emptyOnboardingCopy ? 367 : 281,
      width: double.infinity,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                emptyOnboardingCopy ? '미션 현황' : '오늘의 미션',
                style: AppTypography.heading2Bold.copyWith(
                  color: AppColors.black,
                  letterSpacing: -0.24,
                ),
              ),
              if (emptyOnboardingCopy) ...[
                const SizedBox(width: 8),
                const Icon(Icons.settings, color: AppColors.gray300, size: 22),
              ],
              if (!emptyOnboardingCopy) ...[
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
            top: emptyOnboardingCopy ? 88 : 78,
            left: 0,
            right: 0,
            child: Text(
              emptyOnboardingCopy ? '부모님이 아직 미션을 등록하지 않았어요' : '아직 등록된 미션이 없어요',
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

class _MissionListSection extends StatelessWidget {
  const _MissionListSection();

  @override
  Widget build(BuildContext context) {
    const List<_MissionItemData> missions = [
      _MissionItemData(status: _MissionStatus.pendingCheck),
      _MissionItemData(status: _MissionStatus.rejected),
      _MissionItemData(status: _MissionStatus.reviewing),
      _MissionItemData(status: _MissionStatus.completed),
      _MissionItemData(status: _MissionStatus.completed),
    ];

    return SizedBox(
      height: 520,
      width: double.infinity,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '오늘의 미션',
                style: AppTypography.heading2Bold.copyWith(
                  color: AppColors.black,
                  letterSpacing: -0.24,
                ),
              ),
              const Spacer(),
              Text(
                '2개 완료',
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
                '4',
                style: AppTypography.labelBold.copyWith(
                  color: AppColors.gray200,
                  fontSize: 14,
                  height: 1.429,
                  letterSpacing: 0.203,
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          for (int index = 0; index < missions.length; index++) ...[
            _MissionCard(data: missions[index]),
            if (index != missions.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

enum _MissionStatus { pendingCheck, rejected, reviewing, completed }

class _MissionItemData {
  const _MissionItemData({required this.status});

  final _MissionStatus status;
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.data});

  final _MissionItemData data;

  bool get _isCompleted => data.status == _MissionStatus.completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 18),
      decoration: BoxDecoration(
        color: _isCompleted ? const Color(0xFFEDEEF1) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: _isCompleted ? 0.3 : 1,
            child: SvgPicture.asset(
              'assets/icons/청소.svg',
              width: 48,
              height: 48,
            ),
          ),
          const SizedBox(width: 19),
          Expanded(child: _MissionText(completed: _isCompleted)),
          _MissionStatusIcon(status: data.status),
        ],
      ),
    );
  }
}

class _MissionText extends StatelessWidget {
  const _MissionText({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final Color color = completed ? AppColors.gray300 : AppColors.gray800;
    final TextDecoration decoration = completed
        ? TextDecoration.lineThrough
        : TextDecoration.none;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '방청소 하기',
          style: AppTypography.bodyMedium.copyWith(
            color: color,
            fontSize: 16,
            height: 1.5,
            letterSpacing: 0.091,
            decoration: decoration,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '1시간 지급',
          style: AppTypography.captionRegular.copyWith(
            color: completed ? AppColors.gray300 : AppColors.gray500,
            fontSize: 12,
            height: 1.334,
            letterSpacing: 0.302,
            decoration: decoration,
          ),
        ),
      ],
    );
  }
}

class _MissionStatusIcon extends StatelessWidget {
  const _MissionStatusIcon({required this.status});

  final _MissionStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _MissionStatus.pendingCheck => const _CircleStatusIcon(
        color: AppColors.gray200,
        icon: Icons.check_rounded,
      ),
      _MissionStatus.rejected => const _CircleStatusIcon(
        color: AppColors.destructive,
        icon: Icons.close_rounded,
      ),
      _MissionStatus.reviewing => const _ReviewingStatusIcon(),
      _MissionStatus.completed => const _CircleStatusIcon(
        color: Color(0xFFFFD980),
        icon: Icons.check_rounded,
      ),
    };
  }
}

class _CircleStatusIcon extends StatelessWidget {
  const _CircleStatusIcon({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 15, color: AppColors.white),
    );
  }
}

class _ReviewingStatusIcon extends StatelessWidget {
  const _ReviewingStatusIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF16BF40),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.sync_rounded, size: 13, color: AppColors.white),
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
