import '../../../../core/models/result.dart';
import '../mock/notifications_mock.dart';
import '../models/notification_item.dart';
import 'notification_repository.dart';

/// Mock implementation backed by [NotificationsMock] fixtures.
///
/// Used while [currentEnvironment.useMocks] is true. All methods complete
/// synchronously-via-Future with Success outcomes. The fixture list is copied
/// into memory so read/delete state survives navigation during a mock session.
class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository({List<NotificationItem>? seed})
    : _items = List<NotificationItem>.from(seed ?? NotificationsMock.filled);

  final List<NotificationItem> _items;

  @override
  Future<Result<List<NotificationItem>>> listNotifications() async {
    return Result<List<NotificationItem>>.success(
      List<NotificationItem>.from(_items),
    );
  }

  @override
  Future<Result<void>> deleteNotification(String id) async {
    _items.removeWhere((NotificationItem item) => item.id == id);
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    for (int index = 0; index < _items.length; index++) {
      if (_items[index].id == id) {
        _items[index] = _items[index].copyWith(isRead: true);
        break;
      }
    }
    return Result<void>.success(null);
  }
}
