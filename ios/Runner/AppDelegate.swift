import Flutter
import UIKit

#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let deviceBlockChannelName = "com.gdg.bridge_k/device_block"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerDeviceBlockChannel(engineBridge)
  }

  /// Wires the `com.gdg.bridge_k/device_block` MethodChannel to the Screen Time
  /// based [AppBlocker]. On iOS < 16 (no FamilyControls) calls degrade to no-ops.
  private func registerDeviceBlockChannel(_ engineBridge: FlutterImplicitEngineBridge) {
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeviceBlock") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: deviceBlockChannelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "hasPermission":
        if #available(iOS 16.0, *) {
          result(AppBlocker.hasPermission())
        } else {
          result(false)
        }
      case "requestPermission":
        if #available(iOS 16.0, *) {
          AppBlocker.requestPermission()
        }
        result(nil)
      case "setBlocked":
        if #available(iOS 16.0, *) {
          let args = call.arguments as? [String: Any]
          let blocked = (args?["blocked"] as? Bool) ?? false
          AppBlocker.setBlocked(blocked)
          result(true)
        } else {
          result(false)
        }
      case "configureScreenTime":
        if #available(iOS 16.0, *) {
          let args = call.arguments as? [String: Any]
          let key = (args?["key"] as? String) ?? ""
          let allocatedSeconds = (args?["allocatedSeconds"] as? Int) ?? 0
          result(AppBlocker.configureScreenTime(key: key, allocatedSeconds: allocatedSeconds))
        } else {
          result(false)
        }
      case "remainingScreenTimeSeconds":
        if #available(iOS 16.0, *) {
          result(AppBlocker.remainingScreenTimeSeconds())
        } else {
          result(nil)
        }
      case "clearScreenTime":
        if #available(iOS 16.0, *) {
          result(AppBlocker.clearScreenTime())
        } else {
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// iOS device blocker backed by Screen Time (FamilyControls + ManagedSettings).
///
/// Requires iOS 16+, the **Family Controls** capability on the Runner target,
/// and a one-time user authorization. When active it shields every app/web
/// category; system essentials such as Phone and Messages are not shieldable
/// and stay usable — matching the "only phone/SMS when time's up" behaviour.
///
/// When FamilyControls is unavailable at compile time the calls become no-ops.
@available(iOS 16.0, *)
enum AppBlocker {

  #if canImport(FamilyControls)
  private static let store = ManagedSettingsStore()
  #endif
  private static let trackerKey = "bridge_k_screen_time_tracker_key"
  private static let allocatedSecondsKey = "bridge_k_screen_time_allocated_seconds"
  private static let usedSecondsKey = "bridge_k_screen_time_used_seconds"
  private static let lastTickKey = "bridge_k_screen_time_last_tick"

  /// Whether the user has approved Family Controls authorization.
  static func hasPermission() -> Bool {
    #if canImport(FamilyControls)
    return AuthorizationCenter.shared.authorizationStatus == .approved
    #else
    return false
    #endif
  }

  /// Triggers the system authorization prompt (async; result observed via
  /// `hasPermission` on a later check).
  static func requestPermission() {
    #if canImport(FamilyControls)
    Task {
      try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }
    #endif
  }

  /// Shields ([blocked] true) or unshields ([blocked] false) all categories.
  static func setBlocked(_ blocked: Bool) {
    #if canImport(FamilyControls)
    if blocked {
      store.shield.applicationCategories = .all()
      store.shield.webDomainCategories = .all()
    } else {
      store.shield.applicationCategories = nil
      store.shield.webDomainCategories = nil
    }
    #endif
  }

  static func configureScreenTime(key: String, allocatedSeconds: Int) -> Bool {
    guard !key.isEmpty, allocatedSeconds >= 0 else {
      return false
    }

    let defaults = UserDefaults.standard
    let previousKey = defaults.string(forKey: trackerKey)
    let previousUsed = defaults.integer(forKey: usedSecondsKey)
    let nextUsed = previousKey == key ? min(previousUsed, allocatedSeconds) : 0

    defaults.set(key, forKey: trackerKey)
    defaults.set(allocatedSeconds, forKey: allocatedSecondsKey)
    defaults.set(nextUsed, forKey: usedSecondsKey)
    if nextUsed < allocatedSeconds {
      defaults.set(Date().timeIntervalSince1970, forKey: lastTickKey)
    } else {
      defaults.removeObject(forKey: lastTickKey)
    }
    maybeActivateBlockingIfExpired()
    return true
  }

  static func remainingScreenTimeSeconds() -> Int? {
    guard UserDefaults.standard.string(forKey: trackerKey) != nil else {
      return nil
    }
    refreshScreenTime()
    let defaults = UserDefaults.standard
    let allocatedSeconds = defaults.integer(forKey: allocatedSecondsKey)
    let usedSeconds = defaults.integer(forKey: usedSecondsKey)
    return max(0, allocatedSeconds - usedSeconds)
  }

  static func clearScreenTime() -> Bool {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: trackerKey)
    defaults.removeObject(forKey: allocatedSecondsKey)
    defaults.removeObject(forKey: usedSecondsKey)
    defaults.removeObject(forKey: lastTickKey)
    setBlocked(false)
    return true
  }

  private static func refreshScreenTime() {
    let defaults = UserDefaults.standard
    guard defaults.string(forKey: trackerKey) != nil else {
      return
    }

    let now = Date().timeIntervalSince1970
    let lastTick = defaults.double(forKey: lastTickKey)
    if lastTick <= 0 {
      defaults.set(now, forKey: lastTickKey)
      return
    }

    let elapsedSeconds = max(0, Int(now - lastTick))
    if elapsedSeconds <= 0 {
      return
    }

    let allocatedSeconds = defaults.integer(forKey: allocatedSecondsKey)
    let usedSeconds = min(
      allocatedSeconds,
      defaults.integer(forKey: usedSecondsKey) + elapsedSeconds
    )
    defaults.set(usedSeconds, forKey: usedSecondsKey)
    defaults.set(now, forKey: lastTickKey)
    maybeActivateBlockingIfExpired()
  }

  private static func maybeActivateBlockingIfExpired() {
    let defaults = UserDefaults.standard
    guard defaults.string(forKey: trackerKey) != nil else {
      return
    }
    let allocatedSeconds = defaults.integer(forKey: allocatedSecondsKey)
    let usedSeconds = defaults.integer(forKey: usedSecondsKey)
    if allocatedSeconds - usedSeconds <= 0 {
      setBlocked(true)
    }
  }
}
