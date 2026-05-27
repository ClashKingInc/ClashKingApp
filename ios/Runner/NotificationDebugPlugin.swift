import Flutter
import UIKit
import UserNotifications

final class NotificationDebugPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "clashking/notification_debug",
      binaryMessenger: registrar.messenger()
    )
    let instance = NotificationDebugPlugin()
    UNUserNotificationCenter.current().delegate = instance
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "showSample":
      guard let payload = call.arguments as? [String: Any] else {
        result(FlutterError(code: "invalid_args", message: "Missing notification payload.", details: nil))
        return
      }
      showSample(payload: payload, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func showSample(payload: [String: Any], result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()

    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error {
        DispatchQueue.main.async {
          result(FlutterError(code: "permission_failed", message: error.localizedDescription, details: nil))
        }
        return
      }

      guard granted else {
        DispatchQueue.main.async {
          result(FlutterError(code: "permission_denied", message: "Notifications are disabled for ClashKing.", details: nil))
        }
        return
      }

      Task {
        let title = payload["title"] as? String ?? "ClashKing"
        let body = payload["body"] as? String ?? "Test notification"
        let threadIdentifier = payload["threadIdentifier"] as? String ?? "debug"
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.threadIdentifier = threadIdentifier
        content.sound = .default
        content.attachments = await self.attachments(from: payload)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
          identifier: "clashking-debug-\(UUID().uuidString)",
          content: content,
          trigger: trigger
        )

        do {
          try await center.add(request)
          DispatchQueue.main.async {
            result([
              "scheduled": true,
              "title": title,
              "attachmentCount": content.attachments.count,
            ])
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "schedule_failed", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
  }

  private func attachments(from payload: [String: Any]) async -> [UNNotificationAttachment] {
    let urls: [String]
    if let assetUrls = payload["assetUrls"] as? [String] {
      urls = assetUrls
    } else if let assetUrl = payload["assetUrl"] as? String {
      urls = [assetUrl]
    } else {
      urls = []
    }

    var attachments: [UNNotificationAttachment] = []
    for (index, urlString) in urls.prefix(2).enumerated() {
      if let attachment = await attachment(urlString: urlString, index: index) {
        attachments.append(attachment)
      }
    }
    return attachments
  }

  private func attachment(urlString: String, index: Int) async -> UNNotificationAttachment? {
    guard let url = URL(string: urlString) else {
      return nil
    }

    do {
      let (data, response) = try await URLSession.shared.data(from: url)
      if let httpResponse = response as? HTTPURLResponse,
         !(200...299).contains(httpResponse.statusCode) {
        return nil
      }

      let extensionFromURL = url.pathExtension.isEmpty ? "png" : url.pathExtension
      let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("clashking-notification-\(UUID().uuidString)-\(index).\(extensionFromURL)")
      try data.write(to: fileURL, options: .atomic)
      return try UNNotificationAttachment(identifier: "image-\(index)", url: fileURL)
    } catch {
      return nil
    }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list, .sound])
  }
}
