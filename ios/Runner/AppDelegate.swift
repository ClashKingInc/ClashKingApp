import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LiveActivityDebugPlugin") {
      LiveActivityDebugPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NotificationDebugPlugin") {
      NotificationDebugPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppIconChannel") {
      registerAppIconChannel(with: registrar.messenger())
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
