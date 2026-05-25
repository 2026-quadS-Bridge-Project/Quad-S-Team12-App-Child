import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initializes Firebase using the platform-resolved configuration files
  // (android/app/google-services.json and ios/Runner/GoogleService-Info.plist).
  // FCM, Crashlytics, and other Firebase services rely on this being awaited
  // before any feature code touches them.
  await Firebase.initializeApp();
  runApp(const BridgeKApp());
}
