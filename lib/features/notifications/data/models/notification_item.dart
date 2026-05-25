enum NotificationType {
  weeklyReport,
  timeConfigured,
  missionCompleted,
  missionConfirmationRequested,
  missionRejected,
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.actionLabel = '확인하러 가기',
    this.deeplink,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final String actionLabel;

  /// Optional per-item override for tap routing. When `null`, the page falls
  /// back to a type-based default (see `NotificationsPage._defaultRouteFor`).
  /// Backend will populate this once notification deeplinks land.
  final String? deeplink;

  /// Relative Korean time label computed from [createdAt]. The getter defers
  /// to [DateTime.now] so widgets always render fresh values; tests can call
  /// [_formatTimeAgo] indirectly by clock-injection at a higher layer.
  String get timeAgo => _formatTimeAgo(DateTime.now());

  String _formatTimeAgo(DateTime now) {
    final Duration diff = now.difference(createdAt);
    if (diff.inMinutes < 1) {
      return '방금 전';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    }
    final String yyyy = createdAt.year.toString().padLeft(4, '0');
    final String mm = createdAt.month.toString().padLeft(2, '0');
    final String dd = createdAt.day.toString().padLeft(2, '0');
    return '$yyyy.$mm.$dd';
  }
}
