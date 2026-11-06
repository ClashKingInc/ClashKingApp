import UserNotifications
import CoreGraphics
import UIKit

/// Downloads a small remote thumbnail before iOS presents the push.
final class NotificationService: UNNotificationServiceExtension {
    private let lock = NSLock()
    private var handler: ((UNNotificationContent) -> Void)?
    private var content: UNMutableNotificationContent?
    private var task: URLSessionDownloadTask?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        guard let copy = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }
        handler = contentHandler
        content = copy
        let options = copy.userInfo["fcm_options"] as? [String: Any]
        guard let raw = (copy.userInfo["image_url"] as? String) ?? (options?["image"] as? String),
              let url = URL(string: raw), url.scheme == "https" else {
            finish()
            return
        }
        var download = URLRequest(url: url)
        download.timeoutInterval = 15
        task = URLSession.shared.downloadTask(with: download) { [weak self] temporary, response, _ in
            guard let self else { return }
            var attachment: UNNotificationAttachment?
            if let temporary, let response = response as? HTTPURLResponse,
               response.statusCode == 200, response.url?.scheme == "https",
               let size = try? temporary.resourceValues(forKeys: [.fileSizeKey]).fileSize,
               size > 0, size <= 5 * 1024 * 1024 {
                let suffix: String?
                switch response.mimeType {
                case "image/png": suffix = "png"
                case "image/jpeg": suffix = "jpg"
                default: suffix = nil
                }
                if let suffix {
                    let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
                    do {
                        try FileManager.default.moveItem(at: temporary, to: file)
                        try Self.padThumbnail(at: file)
                        attachment = try UNNotificationAttachment(identifier: "thumbnail", url: file, options: [
                            UNNotificationAttachmentOptionsThumbnailClippingRectKey:
                                CGRect(x: 0, y: 0, width: 1, height: 1).dictionaryRepresentation
                        ])
                    } catch { /* Deliver the original notification when an image is unavailable. */ }
                }
            }
            self.finish(attachment)
        }
        task?.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        task?.cancel()
        finish()
    }

    private static func padThumbnail(at file: URL) throws {
        guard let image = UIImage(contentsOfFile: file.path), image.size.width > 0, image.size.height > 0 else { return }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let scale = 224 / max(image.size.width, image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let data = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).pngData { _ in
            image.draw(in: CGRect(x: (256 - size.width) / 2, y: (256 - size.height) / 2, width: size.width, height: size.height))
        }
        try data.write(to: file, options: .atomic)
    }

    private func finish(_ attachment: UNNotificationAttachment? = nil) {
        lock.lock()
        let completion = handler
        handler = nil
        let output = content
        if let attachment, completion != nil { output?.attachments = [attachment] }
        lock.unlock()
        if let completion, let output { completion(output) }
    }
}
