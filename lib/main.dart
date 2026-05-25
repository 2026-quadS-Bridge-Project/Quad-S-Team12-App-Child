import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/config/environment.dart';
import 'core/services/fcm_bootstrap.dart';
import 'firebase_options.dart';

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

  // Firebase wiring is skipped in the mock environment so the dev simulator
  // boots even when the iOS Xcode project hasn't been opened to register
  // GoogleService-Info.plist as a build resource (and so the Android
  // emulator without Google Play Services doesn't crash on background
  // handler registration). FcmBootstrap is still called below — its mock
  // implementation is a no-op.
  if (!currentEnvironment.useMocks) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    } catch (e, stack) {
      // Don't crash the app if Firebase init fails (e.g. simulator without
      // APNs entitlements); FcmBootstrap will then no-op too.
      debugPrint('[firebase] init failed — continuing without push: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  // Bootstraps permission, token registration, and the foreground +
  // tap-from-background streams. Mock impl is a no-op so tests stay green.
  await FcmBootstrap.initialize();

  runApp(const BridgeKApp());
}
