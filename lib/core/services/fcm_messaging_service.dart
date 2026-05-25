import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/environment.dart';

/// Parsed shape of an FCM push relevant to the child app — extracted from
/// the `data` payload defined in `docs/api-contract.md` §"Push payload
/// 명세". Fields default to safe values when keys are missing so handlers
/// never have to null-check the basics.
class FcmMessage {
  const FcmMessage({
    required this.type,
    required this.deeplink,
    this.notificationId,
    this.entityId,
    this.title,
    this.body,
  });

  /// NotificationType enum name (e.g. `'missionCompleted'`).
  final String type;

  /// Router path the user should land on when tapping the notification.
  final String deeplink;

  /// In-app notification row id — used to mark-as-read on tap.
  final String? notificationId;

  /// Domain id (`missionId` / `reportId` / `scheduleId` — first one found).
  final String? entityId;

  /// `notification.title` from the OS payload — useful for foreground UX.
  final String? title;

  /// `notification.body` from the OS payload.
  final String? body;

  factory FcmMessage.fromRemoteMessage(RemoteMessage message) {
    final Map<String, dynamic> data = message.data;
    final String? entityId = (data['missionId'] as String?) ??
        (data['reportId'] as String?) ??
        (data['scheduleId'] as String?);
    return FcmMessage(
      type: data['type'] as String? ?? 'unknown',
      deeplink: data['deeplink'] as String? ?? '/child-home',
      notificationId: data['notificationId'] as String?,
      entityId: entityId,
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }
}

/// Abstraction over [FirebaseMessaging] so the mock environment (tests,
/// dev without google-services credentials) can no-op while production
/// wires the real streams. Construction is via [createFcmMessagingService]
/// which honors `currentEnvironment.useMocks`.
abstract interface class FcmMessagingService {
  /// Request push permission. iOS + Android 13+ both gate on this. Returns
  /// true when the user granted (or provisionally granted) permission.
  Future<bool> requestPermission();

  /// Current device FCM token. Null when permission has been denied or
  /// the platform has not yet provisioned a token.
  Future<String?> getToken();

  /// Stream of new tokens emitted when FCM rotates the device token.
  /// Callers should re-register with the backend on each emission.
  Stream<String> get onTokenRefresh;

  /// Foreground messages — emitted while the app is in the foreground.
  Stream<FcmMessage> get onForegroundMessage;

  /// Messages that came in while the app was backgrounded and that the
  /// user then tapped to open. Use this to apply the deeplink.
  Stream<FcmMessage> get onMessageOpenedApp;

  /// The message that opened the app from a terminated state, if any.
  /// Call once at startup, after the router is mounted.
  Future<FcmMessage?> getInitialMessage();
}

/// Cached singleton — lazy-initialized at first access. Sharing one
/// instance matters here because [ApiFcmMessagingService] holds the
/// stream subscriptions to the firebase plugin; re-creating it would
/// fork the streams.
final FcmMessagingService _fcmMessagingService = currentEnvironment.useMocks
    ? const MockFcmMessagingService()
    : ApiFcmMessagingService();

FcmMessagingService createFcmMessagingService() => _fcmMessagingService;

class MockFcmMessagingService implements FcmMessagingService {
  const MockFcmMessagingService();

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> getToken() async => 'mock-fcm-token';

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Stream<FcmMessage> get onForegroundMessage =>
      const Stream<FcmMessage>.empty();

  @override
  Stream<FcmMessage> get onMessageOpenedApp =>
      const Stream<FcmMessage>.empty();

  @override
  Future<FcmMessage?> getInitialMessage() async => null;
}

class ApiFcmMessagingService implements FcmMessagingService {
  ApiFcmMessagingService();

  @override
  Future<bool> requestPermission() async {
    final NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  @override
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<FcmMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(FcmMessage.fromRemoteMessage);

  @override
  Stream<FcmMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(FcmMessage.fromRemoteMessage);

  @override
  Future<FcmMessage?> getInitialMessage() async {
    final RemoteMessage? msg =
        await FirebaseMessaging.instance.getInitialMessage();
    if (msg == null) return null;
    return FcmMessage.fromRemoteMessage(msg);
  }
}
