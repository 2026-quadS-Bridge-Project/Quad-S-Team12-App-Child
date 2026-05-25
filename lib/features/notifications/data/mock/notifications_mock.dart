import '../models/notification_item.dart';

/// Mock notifications for the child filled state in Figma node `426:19293`.
/// Copy is intentionally child-facing; the parent app seed uses a different
/// actor perspective and is not the source of truth for this surface.
class NotificationsMock {
  const NotificationsMock._();

  static const List<NotificationItem> filled = <NotificationItem>[
    NotificationItem(
      id: 'weekly-report',
      type: NotificationType.weeklyReport,
      title: '위클리 사용 리포트',
      message: '2월 1주차 사용 분석이 담긴 리포트가 도착했어요!\n리포트를 통해 더 나은 계획을 세워봐요.',
      timeAgo: '15분 전',
      deeplink: '/child-home/report',
    ),
    NotificationItem(
      id: 'time-configured',
      type: NotificationType.timeConfigured,
      title: '시간설정 완료',
      message: '부모님이 1월달 총 사용 시간을 설정했어요!\n이제 시간을 분배할 시간이에요!',
      timeAgo: '15분 전',
      deeplink: '/child-home/time-setup/confirm',
    ),
    NotificationItem(
      id: 'mission-completed-ai',
      type: NotificationType.missionCompleted,
      title: '미션 완료',
      message: '숙제하기 미션 수행을 AI가 확인했어요.\n보너스 시간 15분 획득!',
      timeAgo: '15분 전',
    ),
    NotificationItem(
      id: 'mission-completed-parent',
      type: NotificationType.missionCompleted,
      title: '미션 완료',
      message: '숙제하기 미션 수행을 부모님이 확인했어요.\n보너스 시간 15분 획득!',
      timeAgo: '15분 전',
    ),
    NotificationItem(
      id: 'mission-rejected-parent',
      type: NotificationType.missionRejected,
      title: '미션 반려',
      message: '숙제하기 미션 수행을 부모님이 반려했어요.',
      timeAgo: '15분 전',
    ),
    NotificationItem(
      id: 'mission-rejected-ai',
      type: NotificationType.missionRejected,
      title: '미션 반려',
      message: '숙제하기 미션 수행을 AI가 반려했어요.\n부모님이 한번더 확인중이에요.',
      timeAgo: '15분 전',
    ),
  ];

  static const List<NotificationItem> empty = <NotificationItem>[];
}
