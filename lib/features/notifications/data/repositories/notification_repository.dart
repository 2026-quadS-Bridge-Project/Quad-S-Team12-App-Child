import '../../../../core/config/environment.dart';
import '../../../../core/models/result.dart';
import '../models/notification_item.dart';
import 'api_notification_repository.dart';
import 'mock_notification_repository.dart';

/// Repository contract for the Notifications feature.
///
/// Concrete implementations:
///   * [MockNotificationRepository] — returns canned fixtures from
///     `NotificationsMock` (used while [EnvironmentConfig.useMocks] is true).
///   * [ApiNotificationRepository] — calls the real backend (stubbed for now).
abstract interface class NotificationRepository {
  /// Load all notifications for the current user.
  Future<Result<List<NotificationItem>>> listNotifications();

  /// Delete the notification identified by [id]. Server is the source of
  /// truth; the page mirrors the removal in local state on success.
  Future<Result<void>> deleteNotification(String id);

  /// Mark the notification identified by [id] as read. Fire-and-forget from
  /// the page; failures surface via the returned [Result] for future hooks.
  Future<Result<void>> markAsRead(String id);
}

/// Cached singleton — lazy-initialized at first access.
final NotificationRepository _notificationRepository =
    currentEnvironment.useMocks
        ? MockNotificationRepository()
        : ApiNotificationRepository();

/// Factory that returns the cached repo for the current environment.
NotificationRepository createNotificationRepository() =>
    _notificationRepository;
