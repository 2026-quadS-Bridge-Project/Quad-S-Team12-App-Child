import '../../../../core/models/result.dart';
import '../mock/notifications_mock.dart';
import '../models/notification_item.dart';
import 'notification_repository.dart';

/// Mock implementation backed by [NotificationsMock] fixtures.
///
/// Used while [currentEnvironment.useMocks] is true. All methods complete
/// synchronously-via-Future with Success outcomes; delete and markAsRead
/// are no-ops because the page mirrors state locally until the real
/// backend lands.
class MockNotificationRepository implements NotificationRepository {
  @override
  Future<Result<List<NotificationItem>>> listNotifications() async {
    return Result<List<NotificationItem>>.success(
      List<NotificationItem>.from(NotificationsMock.filled),
    );
  }

  @override
  Future<Result<void>> deleteNotification(String id) async {
    // No-op for now — backend wiring deferred. UI removes from local state.
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    return Result<void>.success(null);
  }
}
