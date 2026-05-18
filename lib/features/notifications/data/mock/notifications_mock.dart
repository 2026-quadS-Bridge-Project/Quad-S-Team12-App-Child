import '../models/notification_item.dart';

/// Mock notifications mirroring the parent app's `notifications_page.dart`
/// seed (3 categories) verbatim. Per product decision ("디자인 결정은 다 figma
/// 기반"), child surface uses parent-app copy 1:1 for visual fidelity even
/// though the voice references "자녀가..." (parent-facing phrasing).
/// Source of truth: `Quad-S-Team12-App-Parent/lib/features/notifications/
/// presentation/pages/notifications_page.dart:18-40`.
class NotificationsMock {
  const NotificationsMock._();

  static const List<NotificationItem> filled = <NotificationItem>[
    NotificationItem(
      id: 'mission-completed',
      type: NotificationType.missionCompleted,
      title: '미션완료',
      message: '자녀가 숙제하기 미션을 완료했어요.\n보너스 시간 15분 획득!',
      timeAgo: '15분 전',
    ),
    NotificationItem(
      id: 'mission-confirmation-requested',
      type: NotificationType.missionConfirmationRequested,
      title: '미션 확인 요청',
      message: '자녀가 숙제하기 미션 완료 확인을 요청했어요.',
      timeAgo: '15분 전',
    ),
    NotificationItem(
      id: 'time-configured',
      type: NotificationType.timeConfigured,
      title: '시간설정 완료',
      message: '자녀가 1월달 사용 시간 설정을 완료했어요!',
      timeAgo: '15분 전',
    ),
  ];

  static const List<NotificationItem> empty = <NotificationItem>[];
}
