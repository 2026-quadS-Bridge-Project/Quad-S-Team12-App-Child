import '../../../../core/models/result.dart';
import '../models/notification_item.dart';
import 'notification_repository.dart';

/// HTTP-backed implementation of [NotificationRepository].
///
/// Stub for Phase 2A — every method throws [UnimplementedError] until
/// backend endpoints are confirmed and wired through `DioConfig`.
class ApiNotificationRepository implements NotificationRepository {
  @override
  Future<Result<List<NotificationItem>>> listNotifications() async {
    throw UnimplementedError(
      'ApiNotificationRepository.listNotifications: backend not wired yet.',
    );
  }

  @override
  Future<Result<void>> deleteNotification(String id) async {
    throw UnimplementedError(
      'ApiNotificationRepository.deleteNotification: backend not wired yet.',
    );
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    throw UnimplementedError(
      'ApiNotificationRepository.markAsRead: backend not wired yet.',
    );
  }
}
