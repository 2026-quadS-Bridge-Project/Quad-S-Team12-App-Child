enum NotificationType {
  missionCompleted,
  missionConfirmationRequested,
  timeConfigured,
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.actionLabel = '확인하러 가기',
    this.deeplink,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String timeAgo;
  final String actionLabel;

  /// Optional per-item override for tap routing. When `null`, the page falls
  /// back to a type-based default (see `NotificationsPage._defaultRouteFor`).
  /// Backend will populate this once notification deeplinks land.
  final String? deeplink;
}
