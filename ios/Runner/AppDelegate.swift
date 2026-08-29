import UIKit
import Flutter
import Darwin

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let sharedAuthRefreshLock = SharedAuthRefreshLock()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NotificationDebugPlugin") {
      NotificationDebugPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppIconChannel") {
      registerAppIconChannel(with: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SharedAuthRefreshLock") {
      registerSharedAuthRefreshLockChannel(with: registrar.messenger())
    }
  }

  private func registerSharedAuthRefreshLockChannel(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "clashking/shared_auth_lock",
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: "Refresh lock is unavailable.", details: nil))
        return
      }

      switch call.method {
      case "acquire":
        DispatchQueue.global(qos: .userInitiated).async {
          do {
            try self.sharedAuthRefreshLock.acquire(timeout: 12)
            DispatchQueue.main.async { result(nil) }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(
                code: "lock_failed",
                message: error.localizedDescription,
                details: nil
              ))
            }
          }
        }
      case "release":
        self.sharedAuthRefreshLock.release()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerAppIconChannel(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "clashking/app_icon",
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { call, result in
      DispatchQueue.main.async {
        switch call.method {
        case "supportsAlternateIcons":
          if #available(iOS 10.3, *) {
            result(UIApplication.shared.supportsAlternateIcons)
          } else {
            result(false)
          }

        case "getAlternateIconName":
          if #available(iOS 10.3, *) {
            result(UIApplication.shared.alternateIconName)
          } else {
            result(nil)
          }

        case "setAlternateIconName":
          guard #available(iOS 10.3, *) else {
            result(FlutterError(
              code: "unsupported",
              message: "Alternate app icons require iOS 10.3 or newer.",
              details: nil
            ))
            return
          }

          guard UIApplication.shared.supportsAlternateIcons else {
            result(FlutterError(
              code: "unsupported",
              message: "Alternate app icons are not supported on this device.",
              details: nil
            ))
            return
          }

          let iconName: String?
          if call.arguments == nil || call.arguments is NSNull {
            iconName = nil
          } else if let value = call.arguments as? String {
            iconName = value
          } else {
            result(FlutterError(
              code: "invalid_arguments",
              message: "Expected an alternate icon name or null.",
              details: nil
            ))
            return
          }

          let allowedIcons = Set(["AppIconChristmas", "AppIconBlackWhite", "AppIconDarkLogo"])
          if let iconName, !allowedIcons.contains(iconName) {
            result(FlutterError(
              code: "invalid_icon",
              message: "Unknown alternate icon: \(iconName)",
              details: nil
            ))
            return
          }

          UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error {
              result(FlutterError(
                code: "set_failed",
                message: error.localizedDescription,
                details: nil
              ))
            } else {
              result(nil)
            }
          }

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}

private final class SharedAuthRefreshLock {
  private let stateLock = NSLock()
  private var descriptor: Int32?

  func acquire(timeout: TimeInterval) throws {
    let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.clashking.apps"
    )
    guard let container else {
      throw SharedAuthRefreshLockError.appGroupUnavailable
    }

    let path = container.appendingPathComponent("auth-refresh.lock").path
    let fileDescriptor = open(path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
    guard fileDescriptor >= 0 else {
      throw SharedAuthRefreshLockError.openFailed(errno)
    }

    let deadline = Date().addingTimeInterval(timeout)
    while Darwin.lockf(fileDescriptor, F_TLOCK, 0) != 0 {
      let lockError = errno
      if lockError != EACCES && lockError != EAGAIN {
        close(fileDescriptor)
        throw SharedAuthRefreshLockError.acquireFailed(lockError)
      }
      if Date() >= deadline {
        close(fileDescriptor)
        throw SharedAuthRefreshLockError.timedOut
      }
      usleep(50_000)
    }

    stateLock.lock()
    defer { stateLock.unlock() }
    guard descriptor == nil else {
      Darwin.lockf(fileDescriptor, F_ULOCK, 0)
      close(fileDescriptor)
      throw SharedAuthRefreshLockError.alreadyHeld
    }
    descriptor = fileDescriptor
  }

  func release() {
    stateLock.lock()
    let fileDescriptor = descriptor
    descriptor = nil
    stateLock.unlock()

    guard let fileDescriptor else { return }
    Darwin.lockf(fileDescriptor, F_ULOCK, 0)
    close(fileDescriptor)
  }

  deinit {
    release()
  }
}

private enum SharedAuthRefreshLockError: LocalizedError {
  case appGroupUnavailable
  case openFailed(Int32)
  case acquireFailed(Int32)
  case timedOut
  case alreadyHeld

  var errorDescription: String? {
    switch self {
    case .appGroupUnavailable:
      return "The shared App Group container is unavailable."
    case .openFailed(let code):
      return "Could not open the refresh lock file (errno \(code))."
    case .acquireFailed(let code):
      return "Could not acquire the refresh lock (errno \(code))."
    case .timedOut:
      return "Timed out waiting for another token refresh to finish."
    case .alreadyHeld:
      return "This process already holds the token refresh lock."
    }
  }
}
