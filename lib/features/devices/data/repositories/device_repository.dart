import '../../../../core/config/environment.dart';
import '../../../../core/models/result.dart';
import 'api_device_repository.dart';
import 'mock_device_repository.dart';

/// Registers the device's FCM token with the backend so it can receive
/// push notifications. Mirrors the patterns used by [MissionRepository] —
/// abstract interface, Mock/Api impls, factory keyed on
/// `currentEnvironment.useMocks`.
///
/// Contract: docs/api-contract.md `Push Notification (FCM)` section.
abstract interface class DeviceRepository {
  /// Upserts the device for the current user. Returns the server-issued
  /// device id which the client should remember and pass to
  /// [unregisterDevice] at logout / account delete time.
  Future<Result<String>> registerDevice({
    required String fcmToken,
    required String platform, // 'ios' or 'android'
  });

  /// Best-effort removal. Failure paths are fine to swallow at the call
  /// site — the device token will eventually be invalidated by FCM anyway.
  Future<Result<void>> unregisterDevice(String deviceId);
}

/// Cached singleton — lazy-initialized at first access.
final DeviceRepository _deviceRepository = currentEnvironment.useMocks
    ? const MockDeviceRepository()
    : ApiDeviceRepository();

DeviceRepository createDeviceRepository() => _deviceRepository;
