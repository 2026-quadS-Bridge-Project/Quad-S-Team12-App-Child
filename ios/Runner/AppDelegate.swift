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
}
