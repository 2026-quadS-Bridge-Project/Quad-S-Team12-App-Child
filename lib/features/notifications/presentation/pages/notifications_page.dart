import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/mock/notifications_mock.dart';
import '../../data/models/notification_item.dart';
import '../../data/repositories/notification_repository.dart';
import '../widgets/notification_card.dart';

/// 알림 (Notifications) screen.
///
/// Child notification surface. State is held inline via `StatefulWidget.setState`
/// until the real notification service lands.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationRepository _repository = createNotificationRepository();

  // Seed with mock fixtures so the list paints on first frame without a
  // loading state; `_loadNotifications` then overwrites with the repo result.
  List<NotificationItem> _notifications = List<NotificationItem>.from(
    NotificationsMock.filled,
  );

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final Result<List<NotificationItem>> result =
        await _repository.listNotifications();
    if (!mounted) {
      return;
    }
    switch (result) {
      case Success<List<NotificationItem>>(:final List<NotificationItem> data):
        setState(() {
          _notifications = data;
        });
      case Failure<List<NotificationItem>>():
        // One-time hint that the list may be stale; the seed (fixture mock)
        // remains on-screen so the user is never left blank.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림을 새로고침하지 못했어요.')),
        );
    }
  }

  /// Maps a notification to a sensible default route. Used when the item has
  /// no explicit `deeplink` override.
  // TODO: once the notifications service ships, prefer backend deeplinks and
  // remove the type-based fallback below.
  String _defaultRouteFor(NotificationType type) {
    switch (type) {
      case NotificationType.weeklyReport:
        return '/child-home/report';
      case NotificationType.timeConfigured:
        return '/child-home/time-setup/confirm';
      case NotificationType.missionCompleted:
        return '/child-home';
      case NotificationType.missionConfirmationRequested:
        return '/child-home';
      case NotificationType.missionRejected:
        return '/child-home';
    }
  }

  void _handleCardTap(NotificationItem item) {
    // Fire-and-forget: the route push runs synchronously below, so we don't
    // await the repository here. Any failure is silent for now; surface via
    // SnackBar once the backend ships and read-state matters to the user.
    unawaited(_repository.markAsRead(item.id));
    final String route = item.deeplink ?? _defaultRouteFor(item.type);
    context.push(route);
  }

  Future<void> _confirmDelete(NotificationItem item) async {
    final Result<void> result = await _repository.deleteNotification(item.id);
    if (!mounted) {
      return;
    }
    switch (result) {
      case Success<void>():
        setState(() {
          _notifications.removeWhere(
            (NotificationItem candidate) => candidate.id == item.id,
          );
        });
      case Failure<void>(:final String message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
    }
  }

  Future<void> _showDeleteDialog(NotificationItem item) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'notification-delete-dialog',
      barrierColor: AppColors.scrim,
      pageBuilder: (BuildContext context, _, _) {
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 375),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  child: _DeleteNotificationDialog(
                    onConfirm: () {
                      // Gate against double-tap: pop first so a second tap on
                      // the (now-detached) button cannot re-enter delete.
                      if (!Navigator.canPop(context)) {
                        return;
                      }
                      context.pop();
                      _confirmDelete(item);
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 160),
      transitionBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _notifications.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _NotificationsTopBar(onBack: context.pop),
                  if (isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            '확인하지 않은 알림이 없습니다.',
                            textAlign: TextAlign.center,
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.gray300,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: _notifications.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 15),
                          itemBuilder: (BuildContext context, int index) {
                            final NotificationItem item = _notifications[index];
                            return NotificationCard(
                              item: item,
                              onTap: () => _handleCardTap(item),
                              onDeleteIntent: _showDeleteDialog,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteNotificationDialog extends StatelessWidget {
  const _DeleteNotificationDialog({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 294.897,
        height: 189.705,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 33, 18, 27),
          child: Column(
            children: <Widget>[
              Container(
                width: 28.77,
                height: 28.77,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryYellow,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 8,
                    height: 16,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Positioned(
                          top: 1.5,
                          child: Container(
                            width: 2.4,
                            height: 9.6,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0.5,
                          child: Container(
                            width: 2.4,
                            height: 2.4,
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '알림을 삭제하시겠습니까?',
                style: AppTypography.labelBold.copyWith(
                  fontSize: 14.39,
                  height: 1.5,
                  letterSpacing: 0.082,
                  color: AppColors.gray800,
                  decoration: TextDecoration.none,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _DeleteDialogButton(
                    label: '취소',
                    filled: false,
                    onTap: context.pop,
                  ),
                  const SizedBox(width: 13.486),
                  _DeleteDialogButton(
                    label: '확인',
                    filled: true,
                    onTap: onConfirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteDialogButton extends StatelessWidget {
  const _DeleteDialogButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 107.889,
        height: 37.761,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
          border: filled
              ? null
              : Border.all(color: AppColors.primary, width: 0.899),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 12.59,
            height: 1.429,
            letterSpacing: 0.1826,
            color: filled ? AppColors.white : AppColors.primary,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _NotificationsTopBar extends StatelessWidget {
  const _NotificationsTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: 14,
            width: 24,
            height: 24,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: SvgPicture.asset(
                  'assets/icons/cmp/btn/back.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '알림',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.inkBlack,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
