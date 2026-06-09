import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges to the platform-native app-blocking engines that restrict the
/// child's device to essential apps (phone / SMS) once screen time is spent.
///
/// - **Android**: an [AccessibilityService] (`AppBlockerService`) watches the
///   foreground app and bounces any non-allowlisted app back to the home
///   screen while blocking is active.
/// - **iOS 16+**: FamilyControls / ManagedSettings shields all app categories
///   (system apps such as Phone/Messages stay usable).
///
/// Both require a one-time OS-level grant (Android: Accessibility access;
/// iOS: Screen Time / Family Controls authorization). On unsupported platforms,
/// or when the channel is absent (tests / mock env), every call degrades to a
/// safe no-op so callers never need to platform-check.
class DeviceBlockController {
  DeviceBlockController._();

  /// Shared instance — the native side keeps a single blocking state.
  static final DeviceBlockController instance = DeviceBlockController._();

  static const MethodChannel _channel = MethodChannel(
    'com.gdg.bridge_k/device_block',
  );

  bool get _isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Whether this runtime can use the native blocker/screen-time channel.
  ///
  /// Desktop tests and web builds intentionally return false, so UI can avoid
  /// showing mobile-only permission prompts in unsupported environments.
  bool get isSupported => _isSupportedPlatform;

  /// Whether the user has granted the OS-level permission the blocker needs
  /// (Android: Accessibility service enabled; iOS: Family Controls approved).
  Future<bool> hasPermission() async {
    if (!_isSupportedPlatform) return false;
    try {
      final bool? granted = await _channel.invokeMethod<bool>('hasPermission');
      return granted ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens the relevant OS settings / authorization prompt. The grant itself
  /// happens out-of-app, so callers should re-check [hasPermission] afterwards.
  Future<void> requestPermission() async {
    if (!_isSupportedPlatform) return;
    try {
      await _channel.invokeMethod<void>('requestPermission');
    } on PlatformException {
      // Ignored — caller re-checks hasPermission().
    } on MissingPluginException {
      // Ignored — no native side in this environment.
    }
  }

  /// Activates ([blocked] true) or lifts ([blocked] false) device-wide
  /// blocking. Returns whether the platform accepted the request.
  Future<bool> setBlocked(bool blocked) async {
    if (!_isSupportedPlatform) return false;
    try {
      final bool? ok = await _channel.invokeMethod<bool>(
        'setBlocked',
        <String, dynamic>{'blocked': blocked},
      );
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> configureScreenTime({
    required String key,
    required int allocatedSeconds,
  }) async {
    if (!_isSupportedPlatform) return false;
    try {
      final bool? ok = await _channel.invokeMethod<bool>(
        'configureScreenTime',
        <String, dynamic>{'key': key, 'allocatedSeconds': allocatedSeconds},
      );
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<int?> remainingScreenTimeSeconds() async {
    if (!_isSupportedPlatform) return null;
    try {
      return await _channel.invokeMethod<int>('remainingScreenTimeSeconds');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Drives blocking from the child's remaining screen time: blocks when
  /// [remainingMinutes] is at or below zero, lifts it otherwise.
  ///
  /// The first time blocking is needed without permission, it opens the grant
  /// prompt and returns early — the actual block applies on a later sync once
  /// the user has granted access.
  Future<void> applyForRemainingMinutes(int remainingMinutes) async {
    if (!_isSupportedPlatform) return;
    final bool shouldBlock = remainingMinutes <= 0;
    if (shouldBlock && !await hasPermission()) {
      await requestPermission();
      return;
    }
    await setBlocked(shouldBlock);
  }
}
