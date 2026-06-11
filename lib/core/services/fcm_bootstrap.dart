import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../app/router/app_router.dart';
import '../../features/devices/data/repositories/device_repository.dart';
import '../auth/auth_session.dart';
import '../models/result.dart';
import 'fcm_messaging_service.dart';

/// Wires the FCM permission request, token registration, foreground +
/// tapped-message handlers, and the cold-start deeplink check. Called once
/// from `main()` after `Firebase.initializeApp()`. Safe to call again — it
/// re-uses the existing service / repo instances but cancels previous
/// subscriptions before re-subscribing.
///
/// Streams stay live for the app lifetime. The handlers delegate routing
/// to the global [appRouter] (path is taken verbatim from the push
/// payload's `data.deeplink`).
class FcmBootstrap {
  FcmBootstrap._();

  static StreamSubscription<FcmMessage>? _foregroundSub;
  static StreamSubscription<FcmMessage>? _openedAppSub;
  static StreamSubscription<String>? _tokenRefreshSub;
  static final StreamController<FcmMessage> _notificationRefreshController =
      StreamController<FcmMessage>.broadcast();

  /// Emits whenever an FCM event should make in-app notification surfaces
  /// refresh their unread state.
  static Stream<FcmMessage> get notificationRefreshes =>
      _notificationRefreshController.stream;

  static Future<void> initialize({
    FcmMessagingService? messagingService,
    DeviceRepository? deviceRepository,
  }) async {
    final FcmMessagingService messaging =
        messagingService ?? createFcmMessagingService();
    final DeviceRepository devices =
        deviceRepository ?? createDeviceRepository();

    // 1. Permission first — Android 13+ requires it before any handler
    //    fires, iOS prompts the system sheet here.
    final bool granted = await messaging.requestPermission();
    if (!granted) {
      debugPrint('[fcm] permission denied — skipping registration.');
      return;
    }

    // 2. Register the current device token if the user is already signed
    //    in. Pre-login the registration is skipped; LoginPage / SignupPage
    //    re-trigger it through [registerForCurrentSession] after saveTokens.
    if (await AuthSession.isLoggedIn()) {
      await _registerCurrentToken(messaging, devices);
    }

    // 3. Token rotation — re-register on every refresh while signed in.
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen((String _) async {
      if (await AuthSession.isLoggedIn()) {
        await _registerCurrentToken(messaging, devices);
      }
    });

    // 4. Foreground messages — leave OS tray rendering to FCM defaults;
    //    we just log and let the in-app notification list refresh next
    //    time the user opens it. Could be expanded with an in-app toast.
    await _foregroundSub?.cancel();
    _foregroundSub = messaging.onForegroundMessage.listen((FcmMessage msg) {
      debugPrint('[fcm] foreground: type=${msg.type} deeplink=${msg.deeplink}');
      _notificationRefreshController.add(msg);
    });

    // 5. Tap-from-background → deeplink. Router is already mounted by
    //    this point so we can go() directly.
    await _openedAppSub?.cancel();
    _openedAppSub = messaging.onMessageOpenedApp.listen((FcmMessage msg) {
      _notificationRefreshController.add(msg);
      _navigate(msg.deeplink);
    });

    // 6. Cold start from terminated — defer the navigation until after
    //    the first frame so the router has finished mounting.
    final FcmMessage? initial = await messaging.getInitialMessage();
    if (initial != null) {
      _notificationRefreshController.add(initial);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigate(initial.deeplink);
      });
    }
  }

  /// Registers the current device's FCM token against the backend. Call
  /// from login / signup success paths so the just-authenticated session
  /// can receive pushes without waiting for the next cold start. No-op in
  /// the mock environment (the mock service returns success without any
  /// network call).
  static Future<void> registerForCurrentSession({
    FcmMessagingService? messagingService,
    DeviceRepository? deviceRepository,
  }) async {
    final FcmMessagingService messaging =
        messagingService ?? createFcmMessagingService();
    final DeviceRepository devices =
        deviceRepository ?? createDeviceRepository();
    await _registerCurrentToken(messaging, devices);
  }

  /// Tears down subscriptions — used by tests; production keeps them for
  /// the app lifetime.
  static Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
    await _tokenRefreshSub?.cancel();
    _foregroundSub = null;
    _openedAppSub = null;
    _tokenRefreshSub = null;
  }

  static Future<void> _registerCurrentToken(
    FcmMessagingService messaging,
    DeviceRepository devices,
  ) async {
    final String? token = await messaging.getToken();
    if (token == null || token.isEmpty) return;
    final Result<String> result = await devices.registerDevice(
      fcmToken: token,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    );
    switch (result) {
      case Success<String>(:final String data):
        debugPrint('[fcm] device registered id=$data');
      case Failure<String>(:final String message):
        debugPrint('[fcm] device registration failed: $message');
    }
  }

  static void _navigate(String deeplink) {
    if (!deeplink.startsWith('/')) {
      return;
    }
    try {
      appRouter.go(deeplink);
    } catch (e) {
      debugPrint('[fcm] navigate failed for "$deeplink": $e');
    }
  }
}
