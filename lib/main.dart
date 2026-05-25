import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/config/environment.dart';
import 'core/services/fcm_bootstrap.dart';

/// Background message handler. Must be a top-level function annotated with
/// `@pragma('vm:entry-point')` because FCM spawns a separate isolate for
/// background delivery — class methods and closures are not reachable.
///
/// We keep this minimal: the OS auto-renders the [RemoteMessage.notification]
/// payload to the tray, and the deeplink is applied when the user taps
/// (handled by `FcmBootstrap` via `onMessageOpenedApp`). All we do here is
/// log; expanding to e.g. background DB writes would require initializing
/// Firebase + storage inside this isolate.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[fcm:bg] type=${message.data['type']} '
    'deeplink=${message.data['deeplink']}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initializes Firebase using the platform-resolved configuration files
  // (android/app/google-services.json and ios/Runner/GoogleService-Info.plist).
  // FCM and other Firebase services rely on this being awaited before any
  // feature code touches them.
  await Firebase.initializeApp();

  // In the mock environment we still want the UI to boot, but skip touching
  // FirebaseMessaging — the Android emulator without Google Play Services
  // and the iOS simulator without APNs both fail otherwise.
  if (!currentEnvironment.useMocks) {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }
  // Bootstraps permission, token registration, and the foreground +
  // tap-from-background streams. Mock impl is a no-op so tests stay green.
  await FcmBootstrap.initialize();

  runApp(const BridgeKApp());
}
