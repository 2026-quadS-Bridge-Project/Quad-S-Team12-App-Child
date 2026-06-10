import 'dart:async';

import 'package:bridge_k/app/app.dart';
import 'package:bridge_k/app/router/app_router.dart';
import 'package:bridge_k/core/models/result.dart';
import 'package:bridge_k/core/services/fcm_bootstrap.dart';
import 'package:bridge_k/core/services/fcm_messaging_service.dart';
import 'package:bridge_k/features/devices/data/repositories/device_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    appRouter.go('/');
    await FcmBootstrap.dispose();
  });

  tearDown(() async {
    await FcmBootstrap.dispose();
  });

  testWidgets('opened FCM message navigates to child target route', (
    WidgetTester tester,
  ) async {
    final _FakeFcmMessagingService messaging = _FakeFcmMessagingService();

    await tester.pumpWidget(const BridgeKApp());
    await FcmBootstrap.initialize(
      messagingService: messaging,
      deviceRepository: const _NoopDeviceRepository(),
    );

    messaging.openedMessages.add(
      const FcmMessage(type: 'GENERAL', deeplink: '/child-home/time-setup'),
    );
    await tester.pumpAndSettle();

    expect(
      appRouter.routeInformationProvider.value.uri.path,
      '/child-home/time-setup',
    );
  });

  testWidgets('initial FCM message waits for first frame before navigation', (
    WidgetTester tester,
  ) async {
    final _FakeFcmMessagingService messaging = _FakeFcmMessagingService(
      initialMessage: const FcmMessage(
        type: 'MISSION_APPROVED',
        deeplink: '/child-home/mission/42',
      ),
    );

    await tester.pumpWidget(const BridgeKApp());
    await FcmBootstrap.initialize(
      messagingService: messaging,
      deviceRepository: const _NoopDeviceRepository(),
    );
    await tester.pumpAndSettle();

    expect(
      appRouter.routeInformationProvider.value.uri.path,
      '/child-home/mission/42',
    );
  });

  testWidgets('FCM navigation ignores non-router paths', (
    WidgetTester tester,
  ) async {
    final _FakeFcmMessagingService messaging = _FakeFcmMessagingService();

    await tester.pumpWidget(const BridgeKApp());
    await FcmBootstrap.initialize(
      messagingService: messaging,
      deviceRepository: const _NoopDeviceRepository(),
    );

    messaging.openedMessages.add(
      const FcmMessage(type: 'GENERAL', deeplink: 'https://example.com'),
    );
    await tester.pumpAndSettle();

    expect(appRouter.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets('foreground FCM message emits notification refresh event', (
    WidgetTester tester,
  ) async {
    final _FakeFcmMessagingService messaging = _FakeFcmMessagingService();
    final List<FcmMessage> refreshes = <FcmMessage>[];
    final StreamSubscription<FcmMessage> sub = FcmBootstrap
        .notificationRefreshes
        .listen(refreshes.add);
    addTearDown(sub.cancel);

    await tester.pumpWidget(const BridgeKApp());
    await FcmBootstrap.initialize(
      messagingService: messaging,
      deviceRepository: const _NoopDeviceRepository(),
    );

    messaging.foregroundMessages.add(
      const FcmMessage(type: 'MISSION_APPROVED', deeplink: '/child-home'),
    );
    await tester.pump();

    expect(refreshes, hasLength(1));
    expect(refreshes.single.type, 'MISSION_APPROVED');
  });

  testWidgets('opened FCM message emits notification refresh event', (
    WidgetTester tester,
  ) async {
    final _FakeFcmMessagingService messaging = _FakeFcmMessagingService();
    final List<FcmMessage> refreshes = <FcmMessage>[];
    final StreamSubscription<FcmMessage> sub = FcmBootstrap
        .notificationRefreshes
        .listen(refreshes.add);
    addTearDown(sub.cancel);

    await tester.pumpWidget(const BridgeKApp());
    await FcmBootstrap.initialize(
      messagingService: messaging,
      deviceRepository: const _NoopDeviceRepository(),
    );

    messaging.openedMessages.add(
      const FcmMessage(
        type: 'MISSION_CREATED',
        deeplink: 'https://example.com',
      ),
    );
    await tester.pump();

    expect(refreshes, hasLength(1));
    expect(refreshes.single.type, 'MISSION_CREATED');
  });
}

class _FakeFcmMessagingService implements FcmMessagingService {
  _FakeFcmMessagingService({this.initialMessage});

  final FcmMessage? initialMessage;
  final StreamController<FcmMessage> foregroundMessages =
      StreamController<FcmMessage>.broadcast();
  final StreamController<FcmMessage> openedMessages =
      StreamController<FcmMessage>.broadcast();

  @override
  Future<FcmMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<String?> getToken() async => 'fake-token';

  @override
  Stream<FcmMessage> get onForegroundMessage => foregroundMessages.stream;

  @override
  Stream<FcmMessage> get onMessageOpenedApp => openedMessages.stream;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<bool> requestPermission() async => true;
}

class _NoopDeviceRepository implements DeviceRepository {
  const _NoopDeviceRepository();

  @override
  Future<Result<String>> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    return Result<String>.success('noop-device');
  }

  @override
  Future<Result<void>> unregisterDevice(String deviceId) async {
    return Result<void>.success(null);
  }
}
