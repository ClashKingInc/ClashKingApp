import Darwin
import AVFoundation
import CryptoKit
import ExpoModulesCore
import Security
import UIKit
import UserNotifications
import WidgetKit

private let appGroupIdentifier = "group.com.clashking.apps"
private let keychainAccessGroup = "MZYXD43RX5.group.com.clashking.apps"
private let defaultKeychainAccessGroup = "MZYXD43RX5.com.clashking.apps"
private let flutterSecureStorageService = "flutter_secure_storage_service"
private let allowedAlternateIcons = Set([
  "AppIconChristmas",
  "AppIconBlackWhite",
  "AppIconDarkLogo",
])
private let legacyWidgetKeys = Set([
  "warWidgetClans",
  "warWidgetSelectedClan",
  "warInfo",
  "warWidgetProxyUrl",
  "warWidgetApiV2Url",
  "upgradeWidgetAccounts",
  "upgradeWidgetData",
  "upgradeWidgetSelectedTag",
])

public final class ClashKingNativeModule: Module {
  private let refreshLock = SharedAuthRefreshLock()
  private var fileSaveContext: FileSaveContext?
  private var sceneryAudio: IOSSceneryAudioBridge?

  @MainActor
  private func sceneryAudioBridge() -> IOSSceneryAudioBridge {
    if let sceneryAudio { return sceneryAudio }
    let sceneryAudio = IOSSceneryAudioBridge { [weak self] status in
      self?.sendEvent("onSceneryAudioStatus", status)
    }
    self.sceneryAudio = sceneryAudio
    return sceneryAudio
  }

  public func definition() -> ModuleDefinition {
    Name("ClashKingNative")
    Events("onSceneryAudioStatus")

    AsyncFunction("prepareSceneryAudio") { (source: String) async throws in
      try await self.sceneryAudioBridge().prepare(source: source)
    }

    AsyncFunction("playSceneryAudio") {
      await self.sceneryAudioBridge().play()
    }

    AsyncFunction("pauseSceneryAudio") {
      await self.sceneryAudioBridge().pause()
    }

    AsyncFunction("seekSceneryAudio") { (positionMilliseconds: Double) async in
      await self.sceneryAudioBridge().seek(milliseconds: positionMilliseconds)
    }

    AsyncFunction("releaseSceneryAudio") {
      await self.sceneryAudioBridge().release()
    }

    OnAppEntersForeground {
      WidgetCenter.shared.reloadAllTimelines()
    }

    OnAppEntersBackground {
      WidgetCenter.shared.reloadAllTimelines()
    }

    AsyncFunction("acquireSharedAuthRefreshLock") {
      (timeoutSeconds: Double?) async throws -> Bool in
      let timeout = min(max(timeoutSeconds ?? 12, 0.1), 60)
      return try await Task.detached(priority: .userInitiated) { [refreshLock] in
        try refreshLock.acquire(timeout: timeout)
        return true
      }.value
    }

    AsyncFunction("releaseSharedAuthRefreshLock") { [refreshLock] in
      refreshLock.release()
    }

    AsyncFunction("supportsAlternateIcons") {
      await MainActor.run { UIApplication.shared.supportsAlternateIcons }
    }

    AsyncFunction("getAlternateIconName") {
      await MainActor.run { UIApplication.shared.alternateIconName }
    }

    AsyncFunction("setAlternateIconName") { (iconName: String?) async throws in
      if let iconName, !allowedAlternateIcons.contains(iconName) {
        throw NativeParityError.invalidAlternateIcon(iconName)
      }
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Void, Error>) in
        DispatchQueue.main.async {
          guard UIApplication.shared.supportsAlternateIcons else {
            continuation.resume(throwing: NativeParityError.alternateIconsUnavailable)
            return
          }
          UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error {
              continuation.resume(throwing: error)
            } else {
              continuation.resume(returning: ())
            }
          }
        }
      }
    }

    AsyncFunction("showDebugNotification") {
      (payload: [String: Any]) async throws -> [String: Any] in
      try await NotificationDebugBridge.showSample(payload: payload)
    }

    AsyncFunction("saveFile") { (options: [String: String], promise: Promise) in
      guard self.fileSaveContext == nil else {
        throw NativeParityError.fileSaveInProgress
      }
      guard let fileURI = options["fileUri"], let sourceURL = URL(string: fileURI),
        sourceURL.isFileURL, FileManager.default.fileExists(atPath: sourceURL.path)
      else {
        throw NativeParityError.invalidSaveSource
      }
      guard let currentViewController = self.appContext?.utilities?.currentViewController() else {
        throw NativeParityError.missingViewController
      }

      let delegate = FileSaveDelegate { [weak self] destination in
        guard let self, let context = self.fileSaveContext else { return }
        self.fileSaveContext = nil
        if let destination {
          context.promise.resolve(destination.absoluteString)
        } else {
          context.promise.reject(NativeParityError.fileSaveCancelled)
        }
      }
      self.fileSaveContext = FileSaveContext(promise: promise, delegate: delegate)

      let picker = UIDocumentPickerViewController(forExporting: [sourceURL], asCopy: true)
      picker.delegate = delegate
      picker.presentationController?.delegate = delegate
      if UIDevice.current.userInterfaceIdiom == .pad {
        let frame = currentViewController.view.frame
        picker.popoverPresentationController?.sourceRect = CGRect(
          x: frame.midX,
          y: frame.maxY,
          width: 0,
          height: 0
        )
        picker.popoverPresentationController?.sourceView = currentViewController.view
        picker.modalPresentationStyle = .pageSheet
      }
      currentViewController.present(picker, animated: true)
    }.runOnQueue(.main)

    AsyncFunction("setWidgetValue") { (key: String, value: String?) in
      guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
        throw NativeParityError.appGroupUnavailable
      }
      if let value {
        defaults.set(value, forKey: key)
      } else {
        defaults.removeObject(forKey: key)
      }
    }

    AsyncFunction("reloadWidgets") {
      WidgetCenter.shared.reloadAllTimelines()
    }

    AsyncFunction("readSharedAuthSession") {
      try LegacyFlutterStorage.readSecureValue(
        key: "shared_auth_session_v1",
        sharedAccessGroup: true
      )
    }

    AsyncFunction("writeSharedAuthSession") { (encodedSession: String) throws in
      try LegacyFlutterStorage.writeSecureValue(
        key: "shared_auth_session_v1",
        value: encodedSession,
        sharedAccessGroup: true
      )
    }

    AsyncFunction("clearSharedAuthSession") {
      try LegacyFlutterStorage.deleteSecureValue(
        key: "shared_auth_session_v1",
        sharedAccessGroup: true
      )
    }

    AsyncFunction("consumePendingWidgetAction") { nil as String? }

    AsyncFunction("readLegacyWidgetValues") { () throws -> [String: String] in
      guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
        throw NativeParityError.appGroupUnavailable
      }
      return defaults.dictionaryRepresentation().reduce(into: [:]) { result, entry in
        guard legacyWidgetKeyIsAllowed(entry.key), let value = entry.value as? String else {
          return
        }
        result[entry.key] = value
      }
    }

    AsyncFunction("requestPinWarWidget") {
      ["supported": false, "requested": false]
    }

    Function("getLegacyMigrationCapabilities") {
      [
        "platform": "ios",
        "secureStorageReadable": true,
        "sharedPreferencesReadable": true,
        "destructiveReads": false,
        "note": "Reads the existing Flutter Keychain service and flutter.-prefixed UserDefaults without deleting values.",
      ] as [String: Any]
    }

    AsyncFunction("readLegacyFlutterSecureValue") {
      (key: String, sharedAccessGroup: Bool?) throws -> String? in
      try LegacyFlutterStorage.readSecureValue(
        key: key,
        sharedAccessGroup: sharedAccessGroup ?? false
      )
    }

    AsyncFunction("readAllLegacyFlutterSecureValues") {
      (sharedAccessGroup: Bool?) throws -> [String: String] in
      try LegacyFlutterStorage.readAllSecureValues(
        sharedAccessGroup: sharedAccessGroup ?? false
      )
    }

    AsyncFunction("readLegacyFlutterPreferences") { (keys: [String]) in
      LegacyFlutterStorage.readPreferences(keys: keys)
    }

    AsyncFunction("readAllLegacyFlutterPreferences") {
      LegacyFlutterStorage.readAllPreferences()
    }
  }
}

@MainActor
private final class IOSSceneryAudioBridge {
  private let emit: ([String: Any]) -> Void
  private var player: AVPlayer?
  private var timeObserver: Any?
  private var completionObserver: NSObjectProtocol?
  private var interruptionObserver: NSObjectProtocol?

  init(emit: @escaping ([String: Any]) -> Void) {
    self.emit = emit
  }

  func prepare(source: String) async throws {
    release()
    guard let sourceURL = URL(string: source), sourceURL.scheme == "https" || sourceURL.scheme == "http"
    else {
      throw NativeParityError.invalidSceneryAudioSource
    }
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .default, options: [])
    try session.setActive(true)
    let localURL = try await cachedAudioURL(for: sourceURL)
    let item = AVPlayerItem(url: localURL)
    let player = AVPlayer(playerItem: item)
    player.volume = 1
    player.actionAtItemEnd = .pause
    self.player = player
    timeObserver = player.addPeriodicTimeObserver(
      forInterval: CMTime(value: 1, timescale: 4),
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor [weak self] in self?.sendStatus() }
    }
    completionObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.player?.seek(to: .zero)
        self.sendStatus(didJustFinish: true)
      }
    }
    interruptionObserver = NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification,
      object: session,
      queue: .main
    ) { [weak self] notification in
      guard
        let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
        let type = AVAudioSession.InterruptionType(rawValue: raw)
      else { return }
      Task { @MainActor [weak self] in
        if type == .began { self?.pause() }
      }
    }
    sendStatus()
  }

  func play() {
    player?.play()
    sendStatus()
  }

  func pause() {
    player?.pause()
    sendStatus()
  }

  func seek(milliseconds: Double) {
    let seconds = max(0, milliseconds) / 1000
    player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000))
    sendStatus()
  }

  func release() {
    if let timeObserver, let player { player.removeTimeObserver(timeObserver) }
    if let completionObserver { NotificationCenter.default.removeObserver(completionObserver) }
    if let interruptionObserver { NotificationCenter.default.removeObserver(interruptionObserver) }
    player?.pause()
    player = nil
    timeObserver = nil
    completionObserver = nil
    interruptionObserver = nil
  }

  private func cachedAudioURL(for source: URL) async throws -> URL {
    let digest = SHA256.hash(data: Data(source.absoluteString.utf8))
      .map { String(format: "%02x", $0) }
      .joined()
    let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("scenery-audio", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let extensionName = source.pathExtension.isEmpty ? "audio" : source.pathExtension
    let destination = directory.appendingPathComponent("\(digest).\(extensionName)")
    if FileManager.default.fileExists(atPath: destination.path) { return destination }
    let (download, response) = try await URLSession.shared.download(from: source)
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
      throw NativeParityError.sceneryAudioDownloadFailed
    }
    do {
      try FileManager.default.moveItem(at: download, to: destination)
    } catch let error as CocoaError where error.code == .fileWriteFileExists {
      // A concurrent preparation completed the same cache entry first.
    }
    return destination
  }

  private func sendStatus(didJustFinish: Bool = false) {
    guard let player else {
      emit([
        "positionMilliseconds": 0,
        "durationMilliseconds": 0,
        "playing": false,
        "loaded": false,
        "buffering": false,
        "didJustFinish": didJustFinish,
      ])
      return
    }
    let duration = player.currentItem?.duration.seconds ?? 0
    let position = player.currentTime().seconds
    emit([
      "positionMilliseconds": position.isFinite ? max(0, position * 1000) : 0,
      "durationMilliseconds": duration.isFinite ? max(0, duration * 1000) : 0,
      "playing": player.timeControlStatus == .playing,
      "loaded": player.currentItem?.status == .readyToPlay,
      "buffering": player.timeControlStatus == .waitingToPlayAtSpecifiedRate,
      "didJustFinish": didJustFinish,
    ])
  }
}

private struct FileSaveContext {
  let promise: Promise
  let delegate: FileSaveDelegate
}

private final class FileSaveDelegate: NSObject, UIDocumentPickerDelegate,
  UIAdaptivePresentationControllerDelegate
{
  private var completion: ((URL?) -> Void)?

  init(completion: @escaping (URL?) -> Void) {
    self.completion = completion
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    finish(with: urls.first)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finish(with: nil)
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    finish(with: nil)
  }

  private func finish(with url: URL?) {
    let callback = completion
    completion = nil
    callback?(url)
  }
}

private enum NotificationDebugBridge {
  static func showSample(payload: [String: Any]) async throws -> [String: Any] {
    let center = UNUserNotificationCenter.current()
    let granted: Bool
    do {
      granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
    } catch {
      throw Exception(
        name: "NotificationDebugPermissionFailed",
        description: error.localizedDescription,
        code: "permission_failed"
      )
    }
    guard granted else {
      throw Exception(
        name: "NotificationDebugPermissionDenied",
        description: "Notifications are disabled for ClashKing.",
        code: "permission_denied"
      )
    }

    let title = payload["title"] as? String ?? "ClashKing"
    let body = payload["body"] as? String ?? "Test notification"
    let threadIdentifier = payload["threadIdentifier"] as? String ?? "debug"
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.threadIdentifier = threadIdentifier
    content.sound = .default
    content.attachments = await attachments(from: payload)

    let request = UNNotificationRequest(
      identifier: "clashking-debug-\(UUID().uuidString)",
      content: content,
      trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    )
    do {
      try await center.add(request)
    } catch {
      throw Exception(
        name: "NotificationDebugScheduleFailed",
        description: error.localizedDescription,
        code: "schedule_failed"
      )
    }
    return [
      "scheduled": true,
      "title": title,
      "attachmentCount": content.attachments.count,
    ]
  }

  private static func attachments(from payload: [String: Any]) async -> [UNNotificationAttachment] {
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

  private static func attachment(urlString: String, index: Int) async -> UNNotificationAttachment? {
    guard let url = URL(string: urlString) else { return nil }
    do {
      let (data, response) = try await URLSession.shared.data(from: url)
      if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
        return nil
      }
      let pathExtension = url.pathExtension.isEmpty ? "png" : url.pathExtension
      let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("clashking-notification-\(UUID().uuidString)-\(index).\(pathExtension)")
      try data.write(to: fileURL, options: .atomic)
      return try UNNotificationAttachment(identifier: "image-\(index)", url: fileURL)
    } catch {
      return nil
    }
  }
}

private func legacyWidgetKeyIsAllowed(_ key: String) -> Bool {
  legacyWidgetKeys.contains(key)
    || key.hasPrefix("warInfo_")
    || key.hasPrefix("upgradeWidget_")
}

private final class SharedAuthRefreshLock: @unchecked Sendable {
  private let stateLock = NSLock()
  private var descriptor: Int32?

  func acquire(timeout: TimeInterval) throws {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupIdentifier
    ) else {
      throw NativeParityError.appGroupUnavailable
    }

    let path = container.appendingPathComponent("auth-refresh.lock").path
    let fileDescriptor = open(path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
    guard fileDescriptor >= 0 else {
      throw NativeParityError.lockOpenFailed(errno)
    }

    let deadline = Date().addingTimeInterval(timeout)
    while Darwin.lockf(fileDescriptor, F_TLOCK, 0) != 0 {
      let lockError = errno
      if lockError != EACCES && lockError != EAGAIN {
        close(fileDescriptor)
        throw NativeParityError.lockAcquireFailed(lockError)
      }
      if Date() >= deadline {
        close(fileDescriptor)
        throw NativeParityError.lockTimedOut
      }
      usleep(50_000)
    }

    stateLock.lock()
    defer { stateLock.unlock() }
    guard descriptor == nil else {
      Darwin.lockf(fileDescriptor, F_ULOCK, 0)
      close(fileDescriptor)
      throw NativeParityError.lockAlreadyHeld
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

  deinit { release() }
}

private enum LegacyFlutterStorage {
  private static func secureQuery(key: String, sharedAccessGroup: Bool) -> [CFString: Any] {
    var query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccount: key,
      kSecAttrService: flutterSecureStorageService,
    ]
    query[kSecAttrAccessGroup] = sharedAccessGroup
      ? keychainAccessGroup
      : defaultKeychainAccessGroup
    return query
  }

  static func readSecureValue(key: String, sharedAccessGroup: Bool) throws -> String? {
    var query = secureQuery(key: key, sharedAccessGroup: sharedAccessGroup)
    query[kSecReturnData] = true
    query[kSecMatchLimit] = kSecMatchLimitOne

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess, let data = item as? Data else {
      throw NativeParityError.keychainReadFailed(status)
    }
    guard let value = String(data: data, encoding: .utf8) else {
      throw NativeParityError.keychainValueNotUTF8
    }
    return value
  }

  static func readAllSecureValues(sharedAccessGroup: Bool) throws -> [String: String] {
    var query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: flutterSecureStorageService,
      kSecReturnAttributes: true,
      kSecReturnData: true,
      kSecMatchLimit: kSecMatchLimitAll,
    ]
    query[kSecAttrAccessGroup] = sharedAccessGroup
      ? keychainAccessGroup
      : defaultKeychainAccessGroup

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound { return [:] }
    guard status == errSecSuccess, let entries = item as? [[CFString: Any]] else {
      throw NativeParityError.keychainReadFailed(status)
    }

    var values: [String: String] = [:]
    for entry in entries {
      guard
        let key = entry[kSecAttrAccount] as? String,
        let data = entry[kSecValueData] as? Data,
        let value = String(data: data, encoding: .utf8)
      else { continue }
      values[key] = value
    }
    return values
  }

  static func writeSecureValue(key: String, value: String, sharedAccessGroup: Bool) throws {
    let data = Data(value.utf8)
    let query = secureQuery(key: key, sharedAccessGroup: sharedAccessGroup)
    let updateStatus = SecItemUpdate(
      query as CFDictionary,
      [kSecValueData: data] as CFDictionary
    )
    if updateStatus == errSecSuccess { return }
    guard updateStatus == errSecItemNotFound else {
      throw NativeParityError.keychainWriteFailed(updateStatus)
    }

    var addQuery = query
    addQuery[kSecValueData] = data
    addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      throw NativeParityError.keychainWriteFailed(addStatus)
    }
  }

  static func deleteSecureValue(key: String, sharedAccessGroup: Bool) throws {
    let status = SecItemDelete(
      secureQuery(key: key, sharedAccessGroup: sharedAccessGroup) as CFDictionary
    )
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw NativeParityError.keychainDeleteFailed(status)
    }
  }

  static func readPreferences(keys: [String]) -> [String: Any] {
    var result: [String: Any] = [:]
    let defaults = UserDefaults.standard
    for key in Set(keys) {
      let value = defaults.object(forKey: "flutter.\(key)") ?? defaults.object(forKey: key)
      if let value, value is String || value is NSNumber || value is NSNull {
        result[key] = value
      }
    }
    return result
  }

  static func readAllPreferences() -> [String: Any] {
    var result: [String: Any] = [:]
    for (storedKey, value) in UserDefaults.standard.dictionaryRepresentation() {
      let key = storedKey.hasPrefix("flutter.")
        ? String(storedKey.dropFirst("flutter.".count))
        : storedKey
      if value is String || value is NSNumber || value is NSNull {
        result[key] = value
      }
    }
    return result
  }
}

private enum NativeParityError: Error, LocalizedError {
  case alternateIconsUnavailable
  case invalidAlternateIcon(String)
  case fileSaveInProgress
  case fileSaveCancelled
  case invalidSaveSource
  case missingViewController
  case appGroupUnavailable
  case lockOpenFailed(Int32)
  case lockAcquireFailed(Int32)
  case lockTimedOut
  case lockAlreadyHeld
  case keychainReadFailed(OSStatus)
  case keychainWriteFailed(OSStatus)
  case keychainDeleteFailed(OSStatus)
  case keychainValueNotUTF8
  case invalidSceneryAudioSource
  case sceneryAudioDownloadFailed

  var errorDescription: String? {
    switch self {
    case .alternateIconsUnavailable:
      return "Alternate app icons are unavailable on this device."
    case .invalidAlternateIcon(let iconName):
      return "Unknown alternate app icon: \(iconName)."
    case .fileSaveInProgress:
      return "Another file save picker is already open."
    case .fileSaveCancelled:
      return "The file save picker was cancelled."
    case .invalidSaveSource:
      return "The file save source is missing or invalid."
    case .missingViewController:
      return "There is no active view controller for the file save picker."
    case .appGroupUnavailable:
      return "The ClashKing App Group container is unavailable."
    case .lockOpenFailed(let code):
      return "Could not open the shared refresh lock (errno \(code))."
    case .lockAcquireFailed(let code):
      return "Could not acquire the shared refresh lock (errno \(code))."
    case .lockTimedOut:
      return "Timed out waiting for the shared refresh lock."
    case .lockAlreadyHeld:
      return "The shared refresh lock is already held by this process."
    case .keychainReadFailed(let status):
      return "Could not read the legacy Flutter Keychain item (OSStatus \(status))."
    case .keychainWriteFailed(let status):
      return "Could not write the shared Flutter Keychain item (OSStatus \(status))."
    case .keychainDeleteFailed(let status):
      return "Could not delete the shared Flutter Keychain item (OSStatus \(status))."
    case .keychainValueNotUTF8:
      return "The legacy Flutter Keychain value is not UTF-8 text."
    case .invalidSceneryAudioSource:
      return "Scenery audio requires an HTTP or HTTPS source."
    case .sceneryAudioDownloadFailed:
      return "The scenery audio file could not be downloaded."
    }
  }
}
