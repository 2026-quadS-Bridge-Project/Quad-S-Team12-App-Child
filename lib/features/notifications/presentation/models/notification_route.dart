import '../../data/models/notification_item.dart';

String childNotificationFallbackRoute(NotificationType type) {
  switch (type) {
    case NotificationType.weeklyReport:
      return '/child-home/report';
    case NotificationType.timeConfigured:
      return '/child-home/time-setup';
    case NotificationType.missionCompleted:
    case NotificationType.missionConfirmationRequested:
    case NotificationType.missionRejected:
      return '/child-home';
  }
}
