import 'package:bridge_k/core/models/result.dart';
import 'package:bridge_k/features/notifications/data/models/notification_item.dart';
import 'package:bridge_k/features/notifications/data/repositories/notification_repository.dart';
import 'package:bridge_k/features/notifications/presentation/pages/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('notification tap waits for mark-as-read before routing', (
    WidgetTester tester,
  ) async {
    final _RecordingNotificationRepository repository =
        _RecordingNotificationRepository(
          markAsReadResult: Result<void>.success(null),
        );
    final GoRouter router = _routerFor(repository);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('미션 도착'));
    await tester.pumpAndSettle();

    expect(repository.markedReadIds, <String>['n-1']);
    expect(find.text('mission 42'), findsOneWidget);
  });

  testWidgets('notification read failure is surfaced without local success', (
    WidgetTester tester,
  ) async {
    final _RecordingNotificationRepository repository =
        _RecordingNotificationRepository(
          markAsReadResult: Result<void>.failure('알림 읽음 처리에 실패했어요.'),
        );
    final GoRouter router = _routerFor(repository);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('미션 도착'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(repository.markedReadIds, <String>['n-1']);
    expect(repository.notifications.single.isRead, isFalse);
    expect(find.text('알림 읽음 처리에 실패했어요.'), findsOneWidget);
  });
}

GoRouter _routerFor(_RecordingNotificationRepository repository) {
  return GoRouter(
    initialLocation: '/notifications',
    routes: <RouteBase>[
      GoRoute(
        path: '/notifications',
        builder: (BuildContext context, GoRouterState state) =>
            NotificationsPage(repository: repository),
      ),
      GoRoute(
        path: '/child-home/mission/:missionId',
        builder: (BuildContext context, GoRouterState state) => Scaffold(
          body: Text('mission ${state.pathParameters['missionId']}'),
        ),
      ),
    ],
  );
}

class _RecordingNotificationRepository implements NotificationRepository {
  _RecordingNotificationRepository({required this.markAsReadResult})
    : notifications = <NotificationItem>[
        NotificationItem(
          id: 'n-1',
          type: NotificationType.missionConfirmationRequested,
          title: '미션 도착',
          message: '새 미션이 도착했어요.',
          createdAt: DateTime(2026, 6, 9, 10),
          deeplink: '/child-home/mission/42',
        ),
      ];

  final Result<void> markAsReadResult;
  final List<String> markedReadIds = <String>[];
  final List<NotificationItem> notifications;

  @override
  Future<Result<List<NotificationItem>>> listNotifications() async {
    return Result<List<NotificationItem>>.success(
      List<NotificationItem>.from(notifications),
    );
  }

  @override
  Future<Result<void>> deleteNotification(String id) async {
    notifications.removeWhere((NotificationItem item) => item.id == id);
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    markedReadIds.add(id);
    if (markAsReadResult is Success<void>) {
      for (int index = 0; index < notifications.length; index++) {
        if (notifications[index].id == id) {
          notifications[index] = notifications[index].copyWith(isRead: true);
          break;
        }
      }
    }
    return markAsReadResult;
  }
}
