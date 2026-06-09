import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/config/dio_config.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/models/result.dart';
import '../../../../core/services/device_block_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../mission/data/models/mission.dart' as mission_model;
import '../../../mission/data/repositories/mission_repository.dart';
import '../../../notifications/data/models/notification_item.dart';
import '../../../notifications/data/repositories/notification_repository.dart';

class ChildHomePage extends StatefulWidget {
  const ChildHomePage({super.key, this.showContent = true, this.dio});

  final bool showContent;
  @visibleForTesting
  final Dio? dio;

  @override
  State<ChildHomePage> createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage>
    with WidgetsBindingObserver {
  late final Dio _dio = widget.dio ?? DioConfig.create();
  bool get _ownsDio => widget.dio == null;
  late final NotificationRepository _notificationRepository =
      createNotificationRepository();

  bool _hasSchedule = false;
  bool _hasNotification = false;
  _HomeTimeSnapshot? _timeSnapshot;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  bool _appliedExpiryBlock = false;
  bool _isReadingRemainingSeconds = false;
  bool _showBlockerPermissionPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.showContent) {
      unawaited(_loadHomeTime());
      unawaited(_loadNotificationIndicator());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    if (_ownsDio) {
      _dio.close(force: true);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _timeSnapshot != null) {
      unawaited(_refreshBlockerPermissionPrompt());
    }
  }

  Future<void> _loadHomeTime() async {
    try {
      final _HomeTimeSnapshot? snapshot = await _fetchHomeTimeSnapshot();
      final int remainingSeconds = snapshot == null
          ? 0
          : await _configureScreenTimeAndReadRemaining(snapshot);
      if (!mounted) {
        return;
      }
      setState(() {
        _timeSnapshot = snapshot;
        _hasSchedule = snapshot != null && snapshot.totalMinutes > 0;
        _remainingSeconds = remainingSeconds;
        _appliedExpiryBlock = false;
        if (snapshot == null) {
          _showBlockerPermissionPrompt = false;
        }
      });
      if (snapshot == null) {
        _countdownTimer?.cancel();
        unawaited(DeviceBlockController.instance.clearScreenTime());
        return;
      }
      unawaited(_refreshBlockerPermissionPrompt());
      _syncDeviceBlocker();
      _restartCountdown();
    } on DioException catch (e) {
      debugPrint('Child home time load failed: ${e.message}');
      if (!mounted) {
        return;
      }
      setState(() {
        _hasSchedule = false;
        _timeSnapshot = null;
        _remainingSeconds = 0;
        _showBlockerPermissionPrompt = false;
      });
      unawaited(DeviceBlockController.instance.clearScreenTime());
    } on FormatException catch (e) {
      debugPrint('Child home time parse failed: ${e.message}');
    }
  }

  Future<void> _loadNotificationIndicator() async {
    final Result<List<NotificationItem>> result = await _notificationRepository
        .listNotifications();
    if (!mounted) {
      return;
    }
    setState(() {
      _hasNotification =
          result is Success<List<NotificationItem>> &&
          result.data.any((NotificationItem item) => !item.isRead);
    });
  }

  Future<_HomeTimeSnapshot?> _fetchHomeTimeSnapshot() async {
    if (currentEnvironment.useMocks && widget.dio == null) {
      return null;
    }
    final DateTime today = DateTime.now();
    final String dateKey = _yyyyMmDd(today);
    try {
      final Response<dynamic> dailyResponse = await _dio.get<dynamic>(
        '/api/v1/schedules/daily',
        queryParameters: <String, dynamic>{'date': dateKey},
      );
      final Map<String, dynamic>? daily = _jsonMap(dailyResponse.data);
      if (daily != null) {
        final int baseMinutes = _intValue(daily['baseMinutes']);
        final int extendedMinutes = _intValue(daily['extendedMinutes']);
        final int totalMinutes = _intValue(
          daily['totalAvailableMinutes'],
          fallback: baseMinutes + extendedMinutes,
        );
        if (totalMinutes <= 0) {
          return null;
        }
        return _HomeTimeSnapshot(
          dateKey: dateKey,
          baseMinutes: _intValue(daily['baseMinutes']),
          bonusMinutes: await _fetchRewardPoolMinutes(),
          totalMinutes: totalMinutes,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }

    return null;
  }

  Future<int> _fetchRewardPoolMinutes() async {
    final String? memberId = await AuthSession.memberId();
    if (memberId == null || memberId.isEmpty) {
      return 0;
    }

    try {
      final Response<dynamic> policyResponse = await _dio.get<dynamic>(
        '/api/v1/children/$memberId/policies',
      );
      final Map<String, dynamic>? policy = _jsonMap(policyResponse.data);
      if (policy == null) {
        return 0;
      }
      return _intValue(policy['accumulatedRewardTime']);
    } on DioException catch (e) {
      debugPrint('Child home reward pool load failed: ${e.message}');
      return 0;
    }
  }

  Future<int> _configureScreenTimeAndReadRemaining(
    _HomeTimeSnapshot snapshot,
  ) async {
    final String? memberId = await AuthSession.memberId();
    final String trackerKey =
        '${memberId ?? 'child'}:${snapshot.dateKey}:today-screen-time';
    final int allocatedSeconds = snapshot.totalMinutes * 60;
    await DeviceBlockController.instance.configureScreenTime(
      key: trackerKey,
      allocatedSeconds: allocatedSeconds,
    );
    return await DeviceBlockController.instance.remainingScreenTimeSeconds() ??
        allocatedSeconds;
  }

  Future<void> _refreshBlockerPermissionPrompt() async {
    if (!DeviceBlockController.instance.isSupported || _timeSnapshot == null) {
      if (mounted && _showBlockerPermissionPrompt) {
        setState(() {
          _showBlockerPermissionPrompt = false;
        });
      }
      return;
    }
    final bool hasPermission = await DeviceBlockController.instance
        .hasPermission();
    if (!mounted) {
      return;
    }
    setState(() {
      _showBlockerPermissionPrompt = !hasPermission;
    });
  }

  Future<void> _openBlockerPermissionSettings() async {
    await DeviceBlockController.instance.requestPermission();
    await _refreshBlockerPermissionPrompt();
  }

  void _restartCountdown() {
    _countdownTimer?.cancel();
    if (_remainingSeconds <= 0) {
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) {
        return;
      }
      if (_isReadingRemainingSeconds) {
        return;
      }
      _isReadingRemainingSeconds = true;
      final int? nativeRemaining = await DeviceBlockController.instance
          .remainingScreenTimeSeconds();
      if (!mounted) {
        _isReadingRemainingSeconds = false;
        return;
      }
      setState(() {
        _remainingSeconds =
            nativeRemaining ??
            (_remainingSeconds > 0 ? _remainingSeconds - 1 : 0);
      });
      _isReadingRemainingSeconds = false;
      _syncDeviceBlocker();
      if (_remainingSeconds <= 0) {
        _countdownTimer?.cancel();
      }
    });
  }

  void _syncDeviceBlocker() {
    final int remainingMinutes = _remainingSeconds <= 0
        ? 0
        : (_remainingSeconds / 60).ceil();
    if (remainingMinutes <= 0) {
      if (_appliedExpiryBlock) {
        return;
      }
      _appliedExpiryBlock = true;
    }
    unawaited(
      DeviceBlockController.instance.applyForRemainingMinutes(remainingMinutes),
    );
  }

  void _toggleHasScheduleForDebug() {
    setState(() {
      _hasSchedule = !_hasSchedule;
      if (_hasSchedule && _timeSnapshot == null) {
        _timeSnapshot = _HomeTimeSnapshot(
          dateKey: _yyyyMmDd(DateTime.now()),
          baseMinutes: 90,
          bonusMinutes: 30,
          totalMinutes: 120,
        );
        _remainingSeconds = 120 * 60;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.gray100,
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTokens.mobileFrameWidth,
            ),
            child: SafeArea(
              bottom: false,
              child: _ChildHomeContent(
                hasContent: widget.showContent,
                hasSchedule: _hasSchedule,
                hasNotification: _hasNotification,
                timeSnapshot: _timeSnapshot,
                remainingSeconds: _remainingSeconds,
                showBlockerPermissionPrompt: _showBlockerPermissionPrompt,
                onRequestBlockerPermission: _openBlockerPermissionSettings,
                onNotificationsChanged: () =>
                    unawaited(_loadNotificationIndicator()),
                onDebugToggleSchedule: kDebugMode
                    ? _toggleHasScheduleForDebug
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTimeSnapshot {
  const _HomeTimeSnapshot({
    required this.dateKey,
    required this.baseMinutes,
    required this.bonusMinutes,
    required this.totalMinutes,
  });

  final String dateKey;
  final int baseMinutes;
  final int bonusMinutes;
  final int totalMinutes;
}

Map<String, dynamic>? _jsonMap(dynamic data) {
  if (data is Map && data['data'] is Map) {
    return Map<String, dynamic>.from(data['data'] as Map);
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  return null;
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _yyyyMmDd(DateTime date) {
  final String year = date.year.toString().padLeft(4, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _formatMinutes(int totalMinutes) {
  final int safeMinutes = totalMinutes < 0 ? 0 : totalMinutes;
  final int hours = safeMinutes ~/ 60;
  final int minutes = safeMinutes % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}';
}

String _formatRemainingSeconds(int totalSeconds) {
  final int safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
  final int hours = safeSeconds ~/ 3600;
  final int minutes = (safeSeconds % 3600) ~/ 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}';
}

class _ChildHomeContent extends StatelessWidget {
  const _ChildHomeContent({
    required this.hasContent,
    required this.hasSchedule,
    required this.hasNotification,
    required this.timeSnapshot,
    required this.remainingSeconds,
    required this.showBlockerPermissionPrompt,
    required this.onRequestBlockerPermission,
    required this.onNotificationsChanged,
    required this.onDebugToggleSchedule,
  });

  final bool hasContent;
  final bool hasSchedule;
  final bool hasNotification;
  final _HomeTimeSnapshot? timeSnapshot;
  final int remainingSeconds;
  final bool showBlockerPermissionPrompt;
  final VoidCallback onRequestBlockerPermission;
  final VoidCallback onNotificationsChanged;
  // Null in release builds — see ChildHomePage build(). Keeps the long-press
  // debug toggle from silently flipping schedule state for end users.
  final VoidCallback? onDebugToggleSchedule;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double visibleHeight =
        MediaQuery.sizeOf(context).height - padding.top - padding.bottom;
    const double emptyContentTopGap = 20;
    const double populatedContentTopGap = 30;

    return SingleChildScrollView(
      physics: hasContent
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: visibleHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.pageHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTokens.mediumGap),
              _TopBar(
                hasNotification: hasContent && hasNotification,
                onNotificationsChanged: onNotificationsChanged,
              ),
              // Figma: topbar bottom y=88, content y=108 (empty) / 118 (v2).
              SizedBox(
                height: hasContent
                    ? populatedContentTopGap
                    : emptyContentTopGap,
              ),
              _TodayTimeSection(
                hasContent: hasContent,
                hasSchedule: hasSchedule,
                timeSnapshot: timeSnapshot,
                remainingSeconds: remainingSeconds,
                showBlockerPermissionPrompt: showBlockerPermissionPrompt,
                onRequestBlockerPermission: onRequestBlockerPermission,
                onDebugToggleSchedule: onDebugToggleSchedule,
              ),
              const SizedBox(height: 50),
              _MissionSection(hasContent: hasContent),
              if (hasContent) const SizedBox(height: AppTokens.sectionGap),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.hasNotification,
    required this.onNotificationsChanged,
  });

  final bool hasNotification;
  final VoidCallback onNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _MyPageButton(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await context.push('/child-home/notifications');
              onNotificationsChanged();
            },
            child: Stack(
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
  const _TodayTimeSection({
    required this.hasContent,
    required this.hasSchedule,
    required this.timeSnapshot,
    required this.remainingSeconds,
    required this.showBlockerPermissionPrompt,
    required this.onRequestBlockerPermission,
    required this.onDebugToggleSchedule,
  });

  final bool hasContent;
  final bool hasSchedule;
  final _HomeTimeSnapshot? timeSnapshot;
  final int remainingSeconds;
  final bool showBlockerPermissionPrompt;
  final VoidCallback onRequestBlockerPermission;
  // Null in release builds; long-press becomes a no-op.
  final VoidCallback? onDebugToggleSchedule;

  @override
  Widget build(BuildContext context) {
    // Donut + bonus details only when there's actually a registered schedule.
    // All other states fall through to the empty card with a tappable + button.
    final bool showDonut = hasContent && hasSchedule && timeSnapshot != null;

    return SizedBox(
      height: showBlockerPermissionPrompt ? 275 : 223,
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
                const SizedBox(width: AppTokens.smallGap),
                // Per audit Issue 4 / fix-request #3: the bar-chart "사용 리포트"
                // entry point must render whenever the user has app content,
                // regardless of whether a schedule is registered yet.
                // The gear (schedule confirm) only makes sense once a schedule
                // exists, so it stays gated behind showDonut.
                if (hasContent)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        visualDensity: VisualDensity.compact,
                        icon: SvgPicture.asset(
                          'assets/icons/bar_chart.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            AppColors.gray600,
                            BlendMode.srcIn,
                          ),
                          placeholderBuilder: (_) => const Icon(
                            Icons.bar_chart_rounded,
                            size: 20,
                            color: AppColors.gray600,
                          ),
                        ),
                        onPressed: () => context.push('/child-home/report'),
                      ),
                      if (showDonut) ...[
                        const SizedBox(width: AppTokens.smallGap),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          visualDensity: VisualDensity.compact,
                          icon: SvgPicture.asset(
                            'assets/icons/settings.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              AppColors.gray600,
                              BlendMode.srcIn,
                            ),
                            placeholderBuilder: (_) => const Icon(
                              Icons.settings_outlined,
                              size: 20,
                              color: AppColors.gray600,
                            ),
                          ),
                          onPressed: () =>
                              context.push('/child-home/time-setup/confirm'),
                        ),
                      ],
                    ],
                  )
                else
                  const Icon(
                    Icons.settings,
                    color: AppColors.gray300,
                    size: 22,
                  ),
                if (!hasContent) ...[
                  const Spacer(),
                  Text(
                    '사용 리포트',
                    style: AppTypography.labelSemiBold.copyWith(
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
            child: GestureDetector(
              // Debug-only long-press to flip between schedule states until
              // real state is wired up. Hit area is the card.
              behavior: HitTestBehavior.opaque,
              onLongPress: onDebugToggleSchedule,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(
                    AppTokens.cardRadiusSmall,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppTokens.cardShadowColor,
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                // Three card states:
                // - has schedule: donut + bonus details
                // - no schedule (normal path): empty-state with tappable + button
                // - hasContent=false (legacy onboarding path): same empty-state
                //   so the + button is always reachable.
                child: showDonut
                    ? _TimeSummaryContent(
                        snapshot: timeSnapshot!,
                        remainingSeconds: remainingSeconds,
                      )
                    : const _ScheduleEmptyState(),
              ),
            ),
          ),
          if (showBlockerPermissionPrompt)
            Positioned(
              left: 0,
              right: 0,
              top: 235,
              child: _BlockerPermissionBanner(
                onTap: onRequestBlockerPermission,
              ),
            ),
        ],
      ),
    );
  }
}

class _BlockerPermissionBanner extends StatelessWidget {
  const _BlockerPermissionBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.lock_clock_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '화면 시간 차감을 위해 접근성 권한을 켜주세요.',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.gray700,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
            TextButton(onPressed: onTap, child: const Text('설정')),
          ],
        ),
      ),
    );
  }
}

class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '아직 등록된 시간 계획이 없어요.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: AppTokens.itemGap),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/child-home/time-setup'),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSummaryContent extends StatelessWidget {
  const _TimeSummaryContent({
    required this.snapshot,
    required this.remainingSeconds,
  });

  final _HomeTimeSnapshot snapshot;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Row(
        children: [
          _TimeDonutChart(
            snapshot: snapshot,
            remainingSeconds: remainingSeconds,
          ),
          const SizedBox(width: 40),
          _TimeDetails(snapshot: snapshot, remainingSeconds: remainingSeconds),
        ],
      ),
    );
  }
}

class _TimeDonutChart extends StatelessWidget {
  const _TimeDonutChart({
    required this.snapshot,
    required this.remainingSeconds,
  });

  final _HomeTimeSnapshot snapshot;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      height: 124,
      child: CustomPaint(
        painter: _TimeDonutChartPainter(
          snapshot: snapshot,
          remainingSeconds: remainingSeconds,
        ),
      ),
    );
  }
}

class _TimeDonutChartPainter extends CustomPainter {
  const _TimeDonutChartPainter({
    required this.snapshot,
    required this.remainingSeconds,
  });

  final _HomeTimeSnapshot snapshot;
  final int remainingSeconds;

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

    final int totalSeconds = snapshot.totalMinutes * 60;
    final double remainingProgress = totalSeconds <= 0
        ? 0
        : (remainingSeconds / totalSeconds).clamp(0, 1).toDouble();
    final double bonusProgress = snapshot.totalMinutes <= 0
        ? 0
        : (snapshot.bonusMinutes / snapshot.totalMinutes)
              .clamp(0, 1)
              .toDouble();

    drawRing(
      radius: 55,
      strokeWidth: 14,
      baseColor: AppColors.gray150,
      progressColor: AppColors.primary,
      progress: remainingProgress,
    );
    drawRing(
      radius: 39,
      strokeWidth: 11,
      baseColor: AppColors.gray150,
      progressColor: AppColors.bonusAmber,
      progress: bonusProgress,
    );
  }

  @override
  bool shouldRepaint(covariant _TimeDonutChartPainter oldDelegate) {
    return oldDelegate.remainingSeconds != remainingSeconds ||
        oldDelegate.snapshot != snapshot;
  }
}

class _TimeDetails extends StatelessWidget {
  const _TimeDetails({required this.snapshot, required this.remainingSeconds});

  final _HomeTimeSnapshot snapshot;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 101,
      height: 124,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 101,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimeDetailGroup(
                label: '남은시간',
                value: _formatRemainingSeconds(remainingSeconds),
                color: AppColors.primary,
              ),
              const SizedBox(height: 14),
              _TimeDetailGroup(
                label: '보너스시간',
                value: _formatMinutes(snapshot.bonusMinutes),
                color: AppColors.bonusAmber,
              ),
            ],
          ),
        ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
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
          style: AppTypography.heading1SemiBold.copyWith(
            color: color,
            fontSize: 24,
            height: 1.364,
            letterSpacing: -0.466,
          ),
        ),
      ],
    );
  }
}

class _MissionSection extends StatelessWidget {
  const _MissionSection({required this.hasContent});

  final bool hasContent;

  @override
  Widget build(BuildContext context) {
    if (hasContent) {
      return const _MissionListSection();
    }

    return SizedBox(
      height: 281,
      width: double.infinity,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                '0개 완료',
                style: AppTypography.labelSemiBold.copyWith(
                  color: AppColors.gray700,
                  fontSize: 14,
                  height: 1.429,
                  letterSpacing: 0.203,
                ),
              ),
              const SizedBox(width: AppTokens.smallGap),
              Container(width: 1, height: 14, color: AppColors.gray200),
              const SizedBox(width: AppTokens.smallGap),
              Text(
                '0',
                style: AppTypography.labelSemiBold.copyWith(
                  color: AppColors.gray200,
                  fontSize: 14,
                  height: 1.429,
                  letterSpacing: 0.203,
                ),
              ),
            ],
          ),
          Positioned(
            top: 98,
            left: 0,
            right: 0,
            child: Text(
              '아직 등록된 미션이 없어요',
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

class _MissionListSection extends StatefulWidget {
  const _MissionListSection();

  @override
  State<_MissionListSection> createState() => _MissionListSectionState();
}

class _MissionListSectionState extends State<_MissionListSection> {
  // Source of truth post-Phase-2B: the repository. The list starts empty and
  // [_loadMissions] hydrates it from the repo (mock today, HTTP once
  // useMocks flips off). No loading/error UI by design — the repo load fills
  // the (currently instant) async window; an empty list is retained on failure.
  late final MissionRepository _repository = createMissionRepository();
  late List<_MissionItemData> _missions = <_MissionItemData>[];

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    final Result<List<mission_model.Mission>> result = await _repository
        .listMissions();
    if (!mounted) return;
    if (result case Success<List<mission_model.Mission>>(data: final fresh)) {
      setState(() {
        _missions = _mapMissions(fresh);
      });
    } else {
      // Keep silent for the user — home is a low-frequency view and a SnackBar
      // on open would be intrusive. Surface a dev-only warning so an empty
      // mission list isn't mistaken for a successful repo fetch.
      debugPrint(
        '[_MissionListSection] listMissions() failed; '
        'retaining empty mission list.',
      );
    }
  }

  static List<_MissionItemData> _mapMissions(
    List<mission_model.Mission> source,
  ) {
    return <_MissionItemData>[
      for (final mission_model.Mission m in source)
        _MissionItemData(
          id: m.id,
          status: _statusFromModel(m.status),
          title: m.title,
          rewardText: m.rewardLabel,
          iconAsset: _iconAssetForCategory(m.category),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<_MissionItemData> missions = _missions;
    final int completedCount = missions
        .where((m) => m.status == _MissionStatus.completed)
        .length;
    final int totalCount = missions.length;

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
                '$completedCount개 완료',
                style: AppTypography.labelSemiBold.copyWith(
                  color: AppColors.gray700,
                  fontSize: 14,
                  height: 1.429,
                  letterSpacing: 0.203,
                ),
              ),
              const SizedBox(width: AppTokens.smallGap),
              Container(width: 1, height: 14, color: AppColors.gray200),
              const SizedBox(width: AppTokens.smallGap),
              Text(
                '$totalCount',
                style: AppTypography.labelSemiBold.copyWith(
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
            if (index != missions.length - 1)
              const SizedBox(height: AppTokens.mediumGap),
          ],
        ],
      ),
    );
  }
}

enum _MissionStatus { pendingCheck, rejected, reviewing, completed }

_MissionStatus _statusFromModel(mission_model.MissionStatus status) {
  switch (status) {
    case mission_model.MissionStatus.pendingCheck:
      return _MissionStatus.pendingCheck;
    case mission_model.MissionStatus.rejected:
      return _MissionStatus.rejected;
    case mission_model.MissionStatus.reviewing:
      return _MissionStatus.reviewing;
    case mission_model.MissionStatus.completed:
      return _MissionStatus.completed;
  }
}

/// Maps a Mission.category to its SVG asset on disk. Falls back to the
/// generic 루틴 icon when an unknown category arrives, matching the default
/// from [mission_model.Mission].
String _iconAssetForCategory(String category) {
  switch (category) {
    case '청소':
      return 'assets/icons/청소.svg';
    case '학습':
      return 'assets/icons/학습.svg';
    case '운동':
      return 'assets/icons/운동.svg';
    case '심부름':
      return 'assets/icons/심부름.svg';
    case '루틴':
    default:
      return 'assets/icons/루틴.svg';
  }
}

class _MissionItemData {
  const _MissionItemData({
    required this.id,
    required this.status,
    required this.title,
    required this.rewardText,
    required this.iconAsset,
  });

  final String id;
  final _MissionStatus status;
  final String title;
  final String rewardText;
  final String iconAsset;
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.data});

  final _MissionItemData data;

  bool get _isCompleted => data.status == _MissionStatus.completed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/child-home/mission/${data.id}'),
      child: Container(
        height: 84,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 18),
        decoration: BoxDecoration(
          color: _isCompleted ? AppColors.gray150 : AppColors.white,
          borderRadius: BorderRadius.circular(AppTokens.cardRadiusSmall),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: _isCompleted ? 0.3 : 1,
              child: SvgPicture.asset(data.iconAsset, width: 48, height: 48),
            ),
            const SizedBox(width: 19),
            Expanded(
              child: _MissionText(
                title: data.title,
                rewardText: data.rewardText,
                completed: _isCompleted,
              ),
            ),
            _MissionStatusIcon(status: data.status),
          ],
        ),
      ),
    );
  }
}

class _MissionText extends StatelessWidget {
  const _MissionText({
    required this.title,
    required this.rewardText,
    required this.completed,
  });

  final String title;
  final String rewardText;
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
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: color,
            fontSize: 16,
            height: 1.5,
            letterSpacing: 0.0912,
            decoration: decoration,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          rewardText,
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
      // Softer amber variant — see AppColors.bonusAmberSoft (distinct from
      // bonusAmber #FFBF00); used for completed-mission ring per Figma.
      _MissionStatus.completed => const _CircleStatusIcon(
        color: AppColors.bonusAmberSoft,
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
        color: AppColors.positive,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.sync_rounded, size: 13, color: AppColors.white),
      ),
    );
  }
}
