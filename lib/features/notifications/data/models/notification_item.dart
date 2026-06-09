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
    this.isRead = false,
    this.actionLabel = '확인하러 가기',
    this.deeplink,
  });

  /// Deserialize from a backend JSON payload. [NotificationType] is matched
  /// against [NotificationType.values] by `.name`; [createdAt] is parsed as
  /// ISO-8601 via [DateTime.parse]. [deeplink] is optional.
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      // Backend sends notificationId as a number (Long); stringify to avoid a
      // cast crash that would take down the whole list parse.
      id: (json['notificationId'] ?? '').toString(),
      type: _typeFromName((json['notificationType'] ?? '').toString()),
      title: (json['title'] ?? '').toString(),
      message: (json['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      isRead: _boolValue(json['isRead']),
      actionLabel: json['actionLabel'] as String? ?? '확인하러 가기',
      deeplink: _deeplinkFromJson(json),
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      actionLabel: actionLabel,
      deeplink: deeplink,
    );
  }

  static String? _deeplinkFromJson(Map<String, dynamic> json) {
    for (final Object? value in <Object?>[
      json['deeplink'],
      json['targetRoute'],
      if (json['payload'] is Map) (json['payload'] as Map)['deeplink'],
      if (json['payload'] is Map) (json['payload'] as Map)['targetRoute'],
    ]) {
      if (value != null && value.toString().startsWith('/')) {
        return value.toString();
      }
    }
    return null;
  }

  static bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  /// Resolve [NotificationType] from a wire name. Matches the app enum names
  /// first (mock compatibility), then maps the backend NotificationType enum
  /// {MISSION_CREATED, MISSION_APPROVED, MISSION_REJECTED, GENERAL}. Falls back
  /// to a safe default instead of throwing on unknown values.
  static NotificationType _typeFromName(String name) {
    for (final NotificationType t in NotificationType.values) {
      if (t.name == name) {
        return t;
      }
    }
    switch (name) {
      case 'MISSION_APPROVED':
        return NotificationType.missionCompleted;
      case 'MISSION_REJECTED':
        return NotificationType.missionRejected;
      case 'MISSION_CREATED':
      case 'MISSION_REQUESTED':
        return NotificationType.missionConfirmationRequested;
      case 'GENERAL':
      default:
        return NotificationType.timeConfigured;
    }
  }

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String actionLabel;

  /// Optional per-item override for tap routing. When `null`, the page falls
  /// back to a type-based default (see `NotificationsPage._defaultRouteFor`).
  /// Backend will populate this once notification deeplinks land.
  final String? deeplink;

  /// Serialize to the wire format. Keys mirror [fromJson] (backend contract:
  /// notificationId / notificationType / content) so toJson→fromJson round-trips.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'notificationId': id,
      'notificationType': type.name,
      'title': title,
      'content': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'actionLabel': actionLabel,
      'deeplink': deeplink,
    };
  }

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
