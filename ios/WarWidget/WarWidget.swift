import AppIntents
import Darwin
import Security
import SwiftUI
import UIKit
import WidgetKit

private let appGroupIdentifier = "group.com.clashking.apps"
private let keychainAccessGroup = "MZYXD43RX5.group.com.clashking.apps"
private let sharedAuthSessionKey = "shared_auth_session_v1"
private let sharedAuthKeychainService = "flutter_secure_storage_service"

struct WarWidgetEntry: TimelineEntry {
  let date: Date
  let data: WarWidgetData
  let clanBadgeData: Data?
  let opponentBadgeData: Data?
}

struct WarWidgetData: Codable {
  struct Side: Codable {
    let name: String?
    let badgeUrlMedium: String?
    let percent: String?
    let attacks: String?
    let stars: Int?
    let maxStars: Int?
  }

  let state: String?
  let mode: String?
  let updatedAt: String?
  let timeState: String?
  let score: String?
  let statusIcon: String?
  let primaryText: String?
  let secondaryText: String?
  let colorTheme: String?
  let clan: Side?
  let opponent: Side?
  let cwlRank: Int?
  let cwlLeague: String?

  static let placeholder = WarWidgetData(
    state: "inWar",
    mode: "war",
    updatedAt: "Preview",
    timeState: "2h 14m left",
    score: "31 - 28",
    statusIcon: "shield",
    primaryText: "2h 14m left",
    secondaryText: "War score",
    colorTheme: "winning",
    clan: Side(name: "ClashKing", badgeUrlMedium: "https://assets.clashk.ing/clashkinglogo.png", percent: "91.40%", attacks: "24/30", stars: 31, maxStars: 45),
    opponent: Side(name: "Enemy Clan", badgeUrlMedium: "https://assets.clashk.ing/clashkinglogo.png", percent: "88.20%", attacks: "23/30", stars: 28, maxStars: 45),
    cwlRank: nil,
    cwlLeague: nil
  )

  static let empty = WarWidgetData(
    state: "notInWar",
    mode: "war",
    updatedAt: "Open app",
    timeState: "",
    score: "-",
    statusIcon: "shield",
    primaryText: "No active war",
    secondaryText: "Open ClashKing to refresh",
    colorTheme: "neutral",
    clan: Side(name: "ClashKing", badgeUrlMedium: nil, percent: "0%", attacks: "0/0", stars: 0, maxStars: 0),
    opponent: nil,
    cwlRank: nil,
    cwlLeague: nil
  )

  static func current(clanTag: String? = nil) -> WarWidgetData {
    guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
      return .empty
    }

    let selectedClanTag = clanTag ?? defaults.string(forKey: "warWidgetSelectedClan")
    let clanSpecificKey = selectedClanTag.map { "warInfo_\(Self.normalizedClanTag($0))" }
    let raw = clanSpecificKey.flatMap { defaults.string(forKey: $0) } ?? defaults.string(forKey: "warInfo")

    guard
      let raw,
      let data = raw.data(using: .utf8),
      let decoded = try? JSONDecoder().decode(WarWidgetData.self, from: data)
    else {
      return .empty
    }
    return decoded
  }

  private static func normalizedClanTag(_ clanTag: String) -> String {
    clanTag.replacingOccurrences(of: "#", with: "").uppercased()
  }
}

private struct CachedWarWidgetClan: Decodable {
  let tag: String
  let name: String
  let badgeUrl: String?
}

struct WarWidgetClanEntity: AppEntity, Identifiable {
  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Clan")
  static var defaultQuery = WarWidgetClanQuery()

  let id: String
  let name: String
  let badgeUrl: String?

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)", subtitle: "\(id)")
  }
}

struct WarWidgetClanQuery: EntityStringQuery {
  func entities(for identifiers: [WarWidgetClanEntity.ID]) async throws -> [WarWidgetClanEntity] {
    allEntities().filter { identifiers.contains($0.id) }
  }

  func entities(matching string: String) async throws -> [WarWidgetClanEntity] {
    guard !string.isEmpty else { return allEntities() }
    return allEntities().filter {
      $0.name.localizedCaseInsensitiveContains(string) ||
      $0.id.localizedCaseInsensitiveContains(string)
    }
  }

  func suggestedEntities() async throws -> [WarWidgetClanEntity] {
    allEntities()
  }

  func defaultResult() async -> WarWidgetClanEntity? {
    allEntities().first
  }

  private func allEntities() -> [WarWidgetClanEntity] {
    let defaults = UserDefaults(suiteName: appGroupIdentifier)
    defaults?.synchronize()
    guard
      let raw = defaults?.string(forKey: "warWidgetClans"),
      let data = raw.data(using: .utf8),
      let decoded = try? JSONDecoder().decode([CachedWarWidgetClan].self, from: data)
    else {
      return []
    }

    return decoded
      .filter { !$0.tag.isEmpty && !$0.name.isEmpty }
      .map { WarWidgetClanEntity(id: $0.tag, name: $0.name, badgeUrl: $0.badgeUrl) }
  }
}

struct SelectWarClanIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "War Widget"
  static var description = IntentDescription("Choose the clan this widget tracks.")

  @Parameter(title: "Clan")
  var clan: WarWidgetClanEntity?
}

struct WarTimelineProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> WarWidgetEntry {
    makeEntry(data: .placeholder)
  }

  func snapshot(for configuration: SelectWarClanIntent, in context: Context) async -> WarWidgetEntry {
    makeEntry(data: context.isPreview ? .placeholder : .current(clanTag: configuration.clan?.id))
  }

  func timeline(for configuration: SelectWarClanIntent, in context: Context) async -> Timeline<WarWidgetEntry> {
    let clanTag = configuration.clan?.id ?? UserDefaults(suiteName: appGroupIdentifier)?.string(forKey: "warWidgetSelectedClan")
    let data = await WarWidgetFreshFetcher().fetch(clanTag: clanTag) ?? .current(clanTag: clanTag)
    let entry = makeEntry(data: data)
    let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
    return Timeline(entries: [entry], policy: .after(next))
  }

  private func makeEntry(data: WarWidgetData) -> WarWidgetEntry {
    WarWidgetEntry(
      date: Date(),
      data: data,
      clanBadgeData: fetchBadgeData(data.clan?.badgeUrlMedium),
      opponentBadgeData: fetchBadgeData(data.opponent?.badgeUrlMedium)
    )
  }

  private func fetchBadgeData(_ urlString: String?) -> Data? {
    guard
      let urlString,
      let url = URL(string: urlString),
      url.scheme == "https"
    else {
      return nil
    }

    let semaphore = DispatchSemaphore(value: 0)
    var result: Data?
    let task = URLSession.shared.dataTask(with: url) { data, response, _ in
      if
        let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200,
        let data
      {
        result = data
      }
      semaphore.signal()
    }
    task.resume()
    _ = semaphore.wait(timeout: .now() + 3)
    task.cancel()
    return result
  }
}

private struct SharedAuthSession: Codable {
  let accessToken: String
  let refreshToken: String
  let deviceId: String

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case deviceId = "device_id"
  }
}

private enum SharedAuthKeychain {
  static func read() throws -> SharedAuthSession? {
    var query = baseQuery()
    query[kSecReturnData] = true
    query[kSecMatchLimit] = kSecMatchLimitOne

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess, let data = item as? Data else {
      throw SharedAuthError.keychain(status)
    }
    return try JSONDecoder().decode(SharedAuthSession.self, from: data)
  }

  static func write(_ session: SharedAuthSession) throws {
    let data = try JSONEncoder().encode(session)
    let query = baseQuery()
    let updates: [CFString: Any] = [
      kSecValueData: data,
      kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    let updateStatus = SecItemUpdate(query as CFDictionary, updates as CFDictionary)
    if updateStatus == errSecSuccess { return }
    guard updateStatus == errSecItemNotFound else {
      throw SharedAuthError.keychain(updateStatus)
    }

    var attributes = query
    attributes[kSecValueData] = data
    attributes[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let addStatus = SecItemAdd(attributes as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      throw SharedAuthError.keychain(addStatus)
    }
  }

  private static func baseQuery() -> [CFString: Any] {
    [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccount: sharedAuthSessionKey,
      kSecAttrService: sharedAuthKeychainService,
      kSecAttrAccessGroup: keychainAccessGroup,
    ]
  }
}

private struct SharedAuthRefreshLock {
  let descriptor: Int32

  static func acquire(timeout: TimeInterval = 12) async throws -> SharedAuthRefreshLock {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        guard let container = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
          continuation.resume(throwing: SharedAuthError.appGroupUnavailable)
          return
        }

        let path = container.appendingPathComponent("auth-refresh.lock").path
        let descriptor = open(path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else {
          continuation.resume(throwing: SharedAuthError.lock(errno))
          return
        }

        let deadline = Date().addingTimeInterval(timeout)
        while Darwin.flock(descriptor, LOCK_EX | LOCK_NB) != 0 {
          let lockError = errno
          if lockError != EWOULDBLOCK && lockError != EAGAIN {
            close(descriptor)
            continuation.resume(throwing: SharedAuthError.lock(lockError))
            return
          }
          if Date() >= deadline {
            close(descriptor)
            continuation.resume(throwing: SharedAuthError.lockTimeout)
            return
          }
          usleep(50_000)
        }

        continuation.resume(returning: SharedAuthRefreshLock(descriptor: descriptor))
      }
    }
  }

  func release() {
    Darwin.flock(descriptor, LOCK_UN)
    close(descriptor)
  }
}

private enum SharedAuthError: Error {
  case appGroupUnavailable
  case keychain(OSStatus)
  case lock(Int32)
  case lockTimeout
  case invalidRefreshResponse
}

private struct WidgetAuthSessionProvider {
  private let expirySkew: TimeInterval = 60

  func validAccessToken(defaults: UserDefaults) async -> String? {
    do {
      guard let initialSession = try SharedAuthKeychain.read() else {
        return validLegacyAccessToken(defaults: defaults)
      }
      if !isExpired(initialSession.accessToken) {
        return initialSession.accessToken
      }

      let lock = try await SharedAuthRefreshLock.acquire()
      defer { lock.release() }

      // Runner may have completed a rotation while this extension waited.
      guard let session = try SharedAuthKeychain.read() else {
        return validLegacyAccessToken(defaults: defaults)
      }
      if !isExpired(session.accessToken) { return session.accessToken }

      return try await refresh(session, defaults: defaults)
    } catch {
      return validLegacyAccessToken(defaults: defaults)
    }
  }

  private func validLegacyAccessToken(defaults: UserDefaults) -> String? {
    guard
      let token = defaults.string(forKey: "warWidgetAuthToken"),
      !token.isEmpty,
      !isExpired(token)
    else {
      return nil
    }
    return token
  }

  private func refresh(_ session: SharedAuthSession, defaults: UserDefaults) async throws -> String {
    let baseUrl = defaults.string(forKey: "warWidgetApiV2Url") ?? "https://v2.api.clashk.ing/v2"
    guard let url = URL(string: "\(baseUrl)/auth/refresh") else {
      throw SharedAuthError.invalidRefreshResponse
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 8
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: [
      "refresh_token": session.refreshToken,
      "device_id": session.deviceId,
    ])

    let (data, response) = try await URLSession.shared.data(for: request)
    guard
      let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200,
      let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let accessToken = payload["access_token"] as? String,
      !accessToken.isEmpty,
      let refreshToken = payload["refresh_token"] as? String,
      !refreshToken.isEmpty
    else {
      throw SharedAuthError.invalidRefreshResponse
    }

    try SharedAuthKeychain.write(
      SharedAuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        deviceId: session.deviceId
      )
    )
    return accessToken
  }

  private func isExpired(_ token: String) -> Bool {
    let parts = token.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count == 3 else { return true }

    var payload = String(parts[1])
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    let remainder = payload.count % 4
    if remainder != 0 {
      payload.append(String(repeating: "=", count: 4 - remainder))
    }

    guard
      let data = Data(base64Encoded: payload),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let expiration = (json["exp"] as? NSNumber)?.doubleValue
    else {
      return true
    }

    return Date().timeIntervalSince1970 >= expiration - expirySkew
  }
}

private struct WarWidgetFreshFetcher {
  func fetch(clanTag: String?) async -> WarWidgetData? {
    guard
      let clanTag,
      !clanTag.isEmpty,
      let defaults = UserDefaults(suiteName: appGroupIdentifier)
    else {
      return nil
    }

    let baseUrl = defaults.string(forKey: "warWidgetProxyUrl") ?? "https://v2.api.clashk.ing/proxy/v1"
    let allowed = CharacterSet.alphanumerics
    guard
      let encodedTag = clanTag.addingPercentEncoding(withAllowedCharacters: allowed),
      let url = URL(string: "\(baseUrl)/clans/\(encodedTag)/currentwar")
    else {
      return nil
    }

    var request = URLRequest(url: url)
    request.timeoutInterval = 10
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    guard let token = await WidgetAuthSessionProvider().validAccessToken(defaults: defaults) else {
      return nil
    }
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard
        let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200,
        let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any]
      else {
        return nil
      }
      let widgetData = buildProxyCurrentWarData(from: raw, clanTag: clanTag, defaults: defaults)
      cache(widgetData, clanTag: clanTag, defaults: defaults)
      return widgetData
    } catch {
      return nil
    }
  }

  private func cache(_ data: WarWidgetData, clanTag: String, defaults: UserDefaults) {
    guard let encoded = try? JSONEncoder().encode(data), let raw = String(data: encoded, encoding: .utf8) else {
      return
    }
    defaults.set(raw, forKey: "warInfo_\(normalizedClanTag(clanTag))")
    defaults.set(raw, forKey: "warInfo")
    defaults.set(clanTag, forKey: "warWidgetSelectedClan")
  }

  private func buildProxyCurrentWarData(from currentWar: [String: Any], clanTag: String, defaults: UserDefaults) -> WarWidgetData {
    let state = string(currentWar["state"]) ?? "notInWar"
    guard ["preparation", "inWar", "warEnded"].contains(state) else {
      let selectedClan = cachedClanSide(clanTag: clanTag, defaults: defaults)
      return WarWidgetData(
        state: state,
        mode: "war",
        updatedAt: updatedAt(),
        timeState: "",
        score: "",
        statusIcon: "shield",
        primaryText: "Not in War",
        secondaryText: "",
        colorTheme: "neutral",
        clan: selectedClan,
        opponent: nil,
        cwlRank: nil,
        cwlLeague: nil
      )
    }
    return buildRegularWarData(currentWar: currentWar, state: state)
  }

  private func buildRegularWarData(currentWar: [String: Any], state: String) -> WarWidgetData {
    let clan = dictionary(currentWar["clan"])
    let opponent = dictionary(currentWar["opponent"])
    let clanStars = int(clan["stars"])
    let opponentStars = int(opponent["stars"])
    let teamSize = int(currentWar["teamSize"])
    var timeState = ""
    var score = ""
    var statusIcon = "sword"
    var primaryText = ""
    var secondaryText = ""
    var colorTheme = "active"

    if state == "preparation" {
      statusIcon = "shield"
      primaryText = "War Preparation"
      colorTheme = "preparation"
      if let startTime = date(string(currentWar["startTime"])) {
        let delta = startTime.timeIntervalSince(Date())
        if delta > 3600 {
          let minutes = max(0, Int(delta / 60))
          timeState = "Starts in \(minutes / 60)h \(minutes % 60)m"
        } else {
          timeState = "Starts at \(clockTime(startTime))"
        }
        primaryText = timeState
      }
    } else if state == "inWar" {
      statusIcon = "sword"
      secondaryText = "\(clanStars) - \(opponentStars)"
      colorTheme = clanStars > opponentStars ? "winning" : (clanStars < opponentStars ? "losing" : "tied")
      if let endTime = date(string(currentWar["endTime"])) {
        let delta = endTime.timeIntervalSince(Date())
        if delta > 3600 {
          let minutes = max(0, Int(delta / 60))
          timeState = "\(minutes / 60)h \(minutes % 60)m left"
        } else {
          timeState = "Ends at \(clockTime(endTime))"
        }
        primaryText = timeState
      }
      score = "\(clanStars) - \(opponentStars)"
    } else if state == "warEnded" {
      let isWin = clanStars > opponentStars
      statusIcon = isWin ? "trophy" : "heart.slash"
      primaryText = isWin ? "Victory!" : "Defeat"
      secondaryText = "\(clanStars) - \(opponentStars)"
      colorTheme = isWin ? "victory" : "defeat"
      timeState = "War Ended"
      score = "\(clanStars) - \(opponentStars)"
    }

    return WarWidgetData(
      state: state,
      mode: "war",
      updatedAt: updatedAt(),
      timeState: timeState,
      score: score,
      statusIcon: statusIcon,
      primaryText: primaryText,
      secondaryText: secondaryText,
      colorTheme: colorTheme,
      clan: side(from: clan, stars: clanStars, teamSize: teamSize),
      opponent: side(from: opponent, stars: opponentStars, teamSize: teamSize),
      cwlRank: nil,
      cwlLeague: nil
    )
  }

  private func side(from raw: [String: Any], stars: Int, teamSize: Int) -> WarWidgetData.Side {
    let destruction = double(raw["destructionPercentage"])
    return WarWidgetData.Side(
      name: string(raw["name"]) ?? "Unknown",
      badgeUrlMedium: string(dictionary(raw["badgeUrls"])["medium"]) ?? "https://assets.clashk.ing/clashkinglogo.png",
      percent: String(format: "%.2f%%", destruction),
      attacks: "\(int(raw["attacks"]))/\(teamSize * 2)",
      stars: stars,
      maxStars: teamSize * 3
    )
  }

  private func cachedClanSide(clanTag: String, defaults: UserDefaults) -> WarWidgetData.Side? {
    guard
      let raw = defaults.string(forKey: "warWidgetClans"),
      let data = raw.data(using: .utf8),
      let decoded = try? JSONDecoder().decode([CachedWarWidgetClan].self, from: data)
    else {
      return nil
    }

    let normalized = normalizedClanTag(clanTag)
    guard let clan = decoded.first(where: { normalizedClanTag($0.tag) == normalized }) else {
      return nil
    }

    return WarWidgetData.Side(
      name: clan.name,
      badgeUrlMedium: clan.badgeUrl,
      percent: nil,
      attacks: nil,
      stars: nil,
      maxStars: nil
    )
  }

  private func updatedAt() -> String {
    "Updated at \(clockTime(Date()))"
  }

  private func clockTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
  }

  private func date(_ value: String?) -> Date? {
    guard let value else { return nil }
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let parsed = fractional.date(from: value) {
      return parsed
    }
    if let parsed = ISO8601DateFormatter().date(from: value) {
      return parsed
    }

    let clashFormatter = DateFormatter()
    clashFormatter.locale = Locale(identifier: "en_US_POSIX")
    clashFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    clashFormatter.dateFormat = "yyyyMMdd'T'HHmmss.SSS'Z'"
    if let parsed = clashFormatter.date(from: value) {
      return parsed
    }

    clashFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
    return clashFormatter.date(from: value)
  }

  private func normalizedClanTag(_ clanTag: String) -> String {
    clanTag.replacingOccurrences(of: "#", with: "").uppercased()
  }

  private func dictionary(_ value: Any?) -> [String: Any] {
    value as? [String: Any] ?? [:]
  }

  private func string(_ value: Any?) -> String? {
    value as? String
  }

  private func int(_ value: Any?) -> Int {
    if let value = value as? Int { return value }
    if let value = value as? Double { return Int(value) }
    if let value = value as? String { return Int(value) ?? 0 }
    return 0
  }

  private func double(_ value: Any?) -> Double {
    if let value = value as? Double { return value }
    if let value = value as? Int { return Double(value) }
    if let value = value as? String { return Double(value) ?? 0 }
    return 0
  }

}

struct WarWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: WarWidgetEntry

  var body: some View {
    switch family {
    case .systemSmall:
      compactWarView
    case .accessoryRectangular:
      accessoryView
    default:
      mediumWarView
    }
  }

  private var compactWarView: some View {
    VStack(spacing: 6) {
      if entry.data.opponent == nil {
        emptyStateView
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        Text(entry.data.primaryText ?? entry.data.timeState ?? "")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
        HStack(alignment: .top, spacing: 10) {
          badgeView(entry.data.clan, badgeData: entry.clanBadgeData, size: 42)
            .frame(maxWidth: .infinity)
          badgeView(entry.data.opponent, badgeData: entry.opponentBadgeData, size: 42)
            .frame(maxWidth: .infinity)
        }
        compactSplitScoreRow
        compactNameRow
        compactPercentRow
      }
    }
    .padding(10)
    .widgetBackground
  }

  private var mediumWarView: some View {
    VStack(spacing: 8) {
      if entry.data.opponent == nil {
        emptyStateView
      } else {
        HStack(alignment: .center, spacing: 8) {
          sideView(entry.data.clan, badgeData: entry.clanBadgeData, badgeSize: 52)
            .layoutPriority(1)
          VStack(spacing: 4) {
            scoreLabel(size: scoreText == "-" ? 22 : 29, minScale: 0.72)
            Text(entry.data.primaryText ?? entry.data.timeState ?? "")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .minimumScaleFactor(0.75)
          }
          .frame(minWidth: 112, idealWidth: 124, maxWidth: 136)
          .layoutPriority(4)
          sideView(entry.data.opponent, badgeData: entry.opponentBadgeData, badgeSize: 52)
            .layoutPriority(1)
        }
      }
    }
    .padding()
    .widgetBackground
  }

  private var largeWarView: some View {
    VStack(alignment: .leading, spacing: 14) {
      if entry.data.opponent == nil {
        emptyStateView
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        HStack(spacing: 16) {
          sideView(entry.data.clan, badgeData: entry.clanBadgeData)
          VStack(spacing: 6) {
            Text(scoreText)
              .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
            Text(entry.data.primaryText ?? entry.data.timeState ?? "")
              .font(.headline)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          .frame(minWidth: 88)
          sideView(entry.data.opponent, badgeData: entry.opponentBadgeData)
        }
        Divider()
        HStack {
          stat(label: "Attacks", value: "\(entry.data.clan?.attacks ?? "-") / \(entry.data.opponent?.attacks ?? "-")")
          Spacer()
          stat(label: "Destruction", value: "\(entry.data.clan?.percent ?? "-") / \(entry.data.opponent?.percent ?? "-")")
        }
        if let rank = entry.data.cwlRank {
          stat(label: "CWL", value: "#\(rank) \(entry.data.cwlLeague ?? "")")
        }
      }
      Spacer(minLength: 0)
      footer
    }
    .padding()
    .widgetBackground
  }

  private var accessoryView: some View {
    HStack(spacing: 6) {
      badgeView(entry.data.clan, badgeData: entry.clanBadgeData, size: 18)
      VStack(alignment: .leading, spacing: 1) {
        scoreLabel(size: 17, minScale: 0.72)
        Text(entry.data.primaryText ?? entry.data.timeState ?? "War")
          .font(.caption2)
          .lineLimit(1)
      }
    }
  }

  private var header: some View {
    HStack(spacing: 6) {
      Text(entry.data.mode == "cwl" ? "CWL" : "War")
        .font(.caption.weight(.bold))
        .lineLimit(1)
      Spacer(minLength: 4)
      Text(entry.data.updatedAt ?? "")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
  }

  private var footer: some View {
    Text(entry.data.secondaryText ?? entry.data.timeState ?? "")
      .font(.caption2)
      .foregroundStyle(.secondary)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
  }

  private var compactPercentRow: some View {
    HStack(spacing: 6) {
      Text(entry.data.clan?.percent ?? "")
      Spacer(minLength: 4)
      Text(entry.data.opponent?.percent ?? "")
    }
    .font(.caption2.monospacedDigit())
    .foregroundStyle(.secondary)
    .lineLimit(1)
    .minimumScaleFactor(0.72)
  }

  private var compactNameRow: some View {
    HStack(spacing: 6) {
      Text(entry.data.clan?.name ?? "Unknown")
        .multilineTextAlignment(.leading)
      Spacer(minLength: 4)
      Text(entry.data.opponent?.name ?? "Unknown")
        .multilineTextAlignment(.trailing)
    }
    .font(.caption2.weight(.semibold))
    .lineLimit(1)
    .minimumScaleFactor(0.58)
  }

  private var emptyStateView: some View {
    VStack(spacing: 7) {
      badgeView(entry.data.clan, badgeData: entry.clanBadgeData, size: family == .systemSmall ? 48 : 56)
      Text(entry.data.clan?.name ?? "Clan War")
        .font((family == .systemSmall ? Font.caption : Font.callout).weight(.semibold))
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
      Text(entry.data.primaryText ?? "Not in War")
        .font((family == .systemSmall ? Font.caption2 : Font.caption).weight(.bold))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
    .frame(maxWidth: .infinity)
  }

  private var scoreText: String {
    if let score = entry.data.score, !score.isEmpty {
      return score
    }
    if let secondary = entry.data.secondaryText, !secondary.isEmpty {
      return secondary
    }
    return "-"
  }

  private var compactScoreText: String {
    scoreText
      .replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "–", with: "-")
      .replacingOccurrences(of: " - ", with: "-")
      .replacingOccurrences(of: " – ", with: "-")
  }

  private func scoreLabel(size: CGFloat, minScale: CGFloat) -> some View {
    Text(compactScoreText)
      .font(.system(size: size, weight: .bold, design: .rounded).monospacedDigit())
      .lineLimit(1)
      .minimumScaleFactor(minScale)
      .allowsTightening(true)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
  }

  private var compactScoreParts: (String, String) {
    if let clanStars = entry.data.clan?.stars, let opponentStars = entry.data.opponent?.stars {
      return ("\(clanStars)", "\(opponentStars)")
    }

    let parts = compactScoreText.split(separator: "-", maxSplits: 1).map(String.init)
    guard parts.count == 2 else {
      return (compactScoreText, "")
    }
    return (parts[0], parts[1])
  }

  private var compactSplitScoreRow: some View {
    let parts = compactScoreParts
    return HStack(spacing: 6) {
      Text(parts.0)
        .frame(maxWidth: .infinity, alignment: .center)
      Text("-")
        .frame(width: 16, alignment: .center)
      Text(parts.1)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    .font(.system(size: 25, weight: .bold, design: .rounded).monospacedDigit())
    .lineLimit(1)
    .minimumScaleFactor(0.7)
    .allowsTightening(true)
  }

  private func sideView(_ side: WarWidgetData.Side?, badgeData: Data?, badgeSize: CGFloat = 54) -> some View {
    VStack(spacing: 5) {
      badgeView(side, badgeData: badgeData, size: badgeSize)
      Text(side?.name ?? "Unknown")
        .font(.caption.weight(.semibold))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
      Text(side?.percent ?? "")
        .font(.caption2.monospacedDigit())
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity)
  }

  private func badgeView(_ side: WarWidgetData.Side?, badgeData: Data?, size: CGFloat) -> some View {
    Group {
      if let badgeData, let image = UIImage(data: badgeData) {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
      } else {
        fallbackBadge(side, size: size)
      }
    }
    .frame(width: size, height: size)
  }

  private func fallbackBadge(_ side: WarWidgetData.Side?, size: CGFloat) -> some View {
    ZStack {
      Circle().fill(.red.opacity(0.14))
      Text(String((side?.name ?? "?").prefix(1)))
        .font(.system(size: max(11, size * 0.38), weight: .bold, design: .rounded))
        .foregroundStyle(.red)
    }
  }

  private func stat(label: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label).font(.caption2).foregroundStyle(.secondary)
      Text(value).font(.caption.weight(.semibold)).monospacedDigit().lineLimit(1)
    }
  }
}

private extension View {
  @ViewBuilder var widgetBackground: some View {
    if #available(iOSApplicationExtension 26.0, *) {
      self.modifier(LiquidGlassWidgetBackground())
    } else if #available(iOSApplicationExtension 17.0, *) {
      self.modifier(StandardWidgetBackground())
    } else {
      self.background(Color(.secondarySystemBackground))
    }
  }
}

@available(iOSApplicationExtension 26.0, *)
private struct LiquidGlassWidgetBackground: ViewModifier {
  func body(content: Content) -> some View {
    content
      .containerBackground(for: .widget) {
        ZStack {
          Color(red: 0.025, green: 0.025, blue: 0.028)
          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.regularMaterial)
          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
      }
  }
}

@available(iOSApplicationExtension 17.0, *)
private struct StandardWidgetBackground: ViewModifier {
  func body(content: Content) -> some View {
    content.containerBackground(.fill.tertiary, for: .widget)
  }
}

struct WarWidget: Widget {
  let kind = "WarWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: SelectWarClanIntent.self, provider: WarTimelineProvider()) { entry in
      WarWidgetView(entry: entry)
    }
    .configurationDisplayName("Clan War")
    .description("Track selected-clan war and CWL score.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}

private struct UpgradeWidgetAccount: Codable {
  let tag: String
  let name: String
  let townHallLevel: Int
  let builderHallLevel: Int
}

struct UpgradeWidgetAccountEntity: AppEntity, Identifiable {
  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Account")
  static var defaultQuery = UpgradeWidgetAccountQuery()

  let id: String
  let name: String
  let townHallLevel: Int
  let builderHallLevel: Int

  var displayRepresentation: DisplayRepresentation {
    let hall = townHallLevel > 0 ? "TH\(townHallLevel)" : "BH\(builderHallLevel)"
    return DisplayRepresentation(title: "\(name)", subtitle: "\(id) · \(hall)")
  }
}

struct UpgradeWidgetAccountQuery: EntityStringQuery {
  func entities(for identifiers: [UpgradeWidgetAccountEntity.ID]) async throws -> [UpgradeWidgetAccountEntity] {
    let requestedTags = Set(identifiers.map(Self.normalizedTag))
    return allEntities().filter { requestedTags.contains(Self.normalizedTag($0.id)) }
  }

  func entities(matching string: String) async throws -> [UpgradeWidgetAccountEntity] {
    guard !string.isEmpty else { return allEntities() }
    return allEntities().filter {
      $0.name.localizedCaseInsensitiveContains(string) ||
      $0.id.localizedCaseInsensitiveContains(string)
    }
  }

  func suggestedEntities() async throws -> [UpgradeWidgetAccountEntity] { allEntities() }
  func defaultResult() async -> UpgradeWidgetAccountEntity? { allEntities().first }

  private func allEntities() -> [UpgradeWidgetAccountEntity] {
    let defaults = UserDefaults(suiteName: appGroupIdentifier)
    defaults?.synchronize()
    guard
      let raw = defaults?.string(forKey: "upgradeWidgetAccounts"),
      let data = raw.data(using: .utf8),
      let accounts = try? JSONDecoder().decode([UpgradeWidgetAccount].self, from: data)
    else { return [] }
    var seen = Set<String>()
    return accounts.compactMap { account in
      let tag = Self.normalizedTag(account.tag)
      guard !tag.isEmpty, seen.insert(tag).inserted else { return nil }
      return UpgradeWidgetAccountEntity(
        id: Self.canonicalTag(tag),
        name: account.name.trimmingCharacters(in: .whitespacesAndNewlines),
        townHallLevel: account.townHallLevel,
        builderHallLevel: account.builderHallLevel
      )
    }
  }

  fileprivate static func normalizedTag(_ tag: String) -> String {
    tag.replacingOccurrences(of: "#", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .uppercased()
  }

  fileprivate static func canonicalTag(_ tag: String) -> String {
    let normalized = normalizedTag(tag)
    return normalized.isEmpty ? "" : "#\(normalized)"
  }
}

struct SelectUpgradeAccountIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Upgrade Progress"
  static var description = IntentDescription("Choose a linked account to track.")

  @Parameter(title: "Account")
  var account: UpgradeWidgetAccountEntity?
}

private struct UpgradeWidgetTask: Codable, Identifiable {
  let name: String
  let imageUrl: String
  let fromLevel: Int
  let toLevel: Int
  let finishesAt: Date
  let helperName: String?
  let helperFinishesAt: Date?
  let count: Int?

  init(name: String, imageUrl: String, fromLevel: Int, toLevel: Int, finishesAt: Date, helperName: String?, helperFinishesAt: Date?, count: Int? = nil) {
    self.name = name
    self.imageUrl = imageUrl
    self.fromLevel = fromLevel
    self.toLevel = toLevel
    self.finishesAt = finishesAt
    self.helperName = helperName
    self.helperFinishesAt = helperFinishesAt
    self.count = count
  }

  var displayCount: Int { max(count ?? 1, 1) }
  var displayName: String { displayCount > 1 ? "\(displayCount)x \(name)" : name }
  var id: String { "\(name)-\(finishesAt.timeIntervalSince1970)-\(displayCount)" }
}

private struct UpgradeWidgetTaskChoice: Identifiable {
  let title: String
  let task: UpgradeWidgetTask

  var id: String { "\(title)-\(task.id)" }
}

private struct UpgradeWidgetBoost: Codable, Identifiable {
  let kind: String
  let label: String
  let shortLabel: String?
  let imageUrl: String?
  let expiresAt: Date?

  init(kind: String, label: String, shortLabel: String? = nil, imageUrl: String?, expiresAt: Date?) {
    self.kind = kind
    self.label = label
    self.shortLabel = shortLabel
    self.imageUrl = imageUrl
    self.expiresAt = expiresAt
  }

  var id: String { "\(kind)-\(label)" }
}

private struct UpgradeWidgetHelper: Codable, Identifiable {
  let name: String
  let shortName: String?
  let imageUrl: String
  let status: String
  let statusUntil: Date?

  init(name: String, shortName: String? = nil, imageUrl: String, status: String, statusUntil: Date?) {
    self.name = name
    self.shortName = shortName
    self.imageUrl = imageUrl
    self.status = status
    self.statusUntil = statusUntil
  }

  var id: String { name }
}

private struct UpgradeWidgetSectionData: Codable {
  let available: Bool
  let capacity: Int
  let activeCount: Int?
  let hiddenFinishesAt: Date?
  let remainingCount: Int
  let tasks: [UpgradeWidgetTask]
}

private struct UpgradeWidgetLabels: Codable {
  let title: String
  let homeVillage: String
  let village: String
  let laboratory: String
  let pets: String
  let builderBase: String
  let research: String
  let active: String
  let idle: String
  let locked: String
  let maxed: String
  let notUnlocked: String
  let fullyUpgraded: String
  let noActiveUpgrades: String
  let noActiveResearch: String
  let staleData: String?
  let level: String
  let ready: String

  static let fallback = UpgradeWidgetLabels(
    title: "Upgrade Progress",
    homeVillage: "HOME VILLAGE",
    village: "VILLAGE",
    laboratory: "LAB",
    pets: "PETS",
    builderBase: "BUILDER BASE",
    research: "RESEARCH",
    active: "ACTIVE",
    idle: "IDLE",
    locked: "LOCKED",
    maxed: "MAXED",
    notUnlocked: "Not unlocked",
    fullyUpgraded: "Fully upgraded",
    noActiveUpgrades: "No active upgrades",
    noActiveResearch: "No active research",
    staleData: "Update needed",
    level: "Lv",
    ready: "Ready"
  )
}

private struct UpgradeWidgetData: Codable {
  let tag: String
  let name: String
  let townHallLevel: Int
  let builderHallLevel: Int
  let hallImageUrl: String
  let updatedAt: Date
  let hasStaleData: Bool?
  let boosts: [UpgradeWidgetBoost]
  let helpers: [UpgradeWidgetHelper]
  let labels: UpgradeWidgetLabels?
  let homeBuilders: UpgradeWidgetSectionData
  let laboratory: UpgradeWidgetSectionData
  let pets: UpgradeWidgetSectionData
  let builderBase: UpgradeWidgetSectionData

  static let placeholder = UpgradeWidgetData(
    tag: "#PLAYER",
    name: "Chief",
    townHallLevel: 18,
    builderHallLevel: 10,
    hallImageUrl: "https://assets.clashk.ing/buildings/home-village/town_hall/level_18.webp",
    updatedAt: Date(),
    hasStaleData: false,
    boosts: [UpgradeWidgetBoost(kind: "builderPotion", label: "Builder Potion", imageUrl: "https://assets.clashk.ing/magic_items/builder_potion.webp", expiresAt: Date().addingTimeInterval(1800))],
    helpers: [UpgradeWidgetHelper(name: "Builder Apprentice", imageUrl: "https://assets.clashk.ing/helpers/builder's_apprentice.webp", status: "Helping Archer Tower", statusUntil: Date().addingTimeInterval(1200))],
    labels: .fallback,
    homeBuilders: UpgradeWidgetSectionData(
      available: true,
      capacity: 6,
      activeCount: 2,
      hiddenFinishesAt: nil,
      remainingCount: 2,
      tasks: [
        UpgradeWidgetTask(name: "Archer Tower", imageUrl: "https://assets.clashk.ing/buildings/home-village/archer_tower/level_18.webp", fromLevel: 17, toLevel: 18, finishesAt: Date().addingTimeInterval(7200), helperName: "Builder Apprentice", helperFinishesAt: Date().addingTimeInterval(1800)),
        UpgradeWidgetTask(name: "Cannon", imageUrl: "https://assets.clashk.ing/buildings/home-village/cannon/level_19.webp", fromLevel: 18, toLevel: 19, finishesAt: Date().addingTimeInterval(14400), helperName: nil, helperFinishesAt: nil),
      ]
    ),
    laboratory: UpgradeWidgetSectionData(
      available: true,
      capacity: 1,
      activeCount: 1,
      hiddenFinishesAt: nil,
      remainingCount: 1,
      tasks: [UpgradeWidgetTask(name: "Dragon", imageUrl: "https://assets.clashk.ing/troops/dragon/icon.webp", fromLevel: 12, toLevel: 13, finishesAt: Date().addingTimeInterval(21600), helperName: nil, helperFinishesAt: nil)]
    ),
    pets: UpgradeWidgetSectionData(available: true, capacity: 1, activeCount: 0, hiddenFinishesAt: nil, remainingCount: 0, tasks: []),
    builderBase: UpgradeWidgetSectionData(available: true, capacity: 2, activeCount: 0, hiddenFinishesAt: nil, remainingCount: 1, tasks: [])
  )

  static let empty = UpgradeWidgetData(
    tag: "",
    name: "ClashKing",
    townHallLevel: 0,
    builderHallLevel: 0,
    hallImageUrl: "",
    updatedAt: Date(),
    hasStaleData: false,
    boosts: [],
    helpers: [],
    labels: .fallback,
    homeBuilders: UpgradeWidgetSectionData(available: false, capacity: 0, activeCount: 0, hiddenFinishesAt: nil, remainingCount: 0, tasks: []),
    laboratory: UpgradeWidgetSectionData(available: false, capacity: 0, activeCount: 0, hiddenFinishesAt: nil, remainingCount: 0, tasks: []),
    pets: UpgradeWidgetSectionData(available: false, capacity: 0, activeCount: 0, hiddenFinishesAt: nil, remainingCount: 0, tasks: []),
    builderBase: UpgradeWidgetSectionData(available: false, capacity: 0, activeCount: 0, hiddenFinishesAt: nil, remainingCount: 0, tasks: [])
  )

  static func current(accountTag: String?) -> UpgradeWidgetData? {
    guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    defaults.synchronize()
    let linkedTags = UpgradeWidgetAccountQuery.linkedTags(defaults: defaults)
    guard !linkedTags.isEmpty else { return nil }
    let selected = accountTag.map(UpgradeWidgetAccountQuery.normalizedTag)
    let candidateTags: [String]
    if let selected, !selected.isEmpty {
      candidateTags = [selected]
    } else if let firstLinkedTag = linkedTags.first {
      candidateTags = [firstLinkedTag]
    } else {
      candidateTags = []
    }
    var seen = Set<String>()
    for tag in candidateTags where seen.insert(tag).inserted {
      guard linkedTags.contains(tag) else { continue }
      let key = "upgradeWidget_\(tag)"
      guard
        let raw = defaults.string(forKey: key),
        let data = raw.data(using: .utf8),
        let decoded = try? decoder.decode(UpgradeWidgetData.self, from: data)
      else { continue }
      guard UpgradeWidgetAccountQuery.normalizedTag(decoded.tag) == tag else {
        continue
      }
      return decoded
    }
    return nil
  }
}

fileprivate extension UpgradeWidgetAccountQuery {
  static func linkedTags(defaults: UserDefaults) -> [String] {
    guard
      let raw = defaults.string(forKey: "upgradeWidgetAccounts"),
      let data = raw.data(using: .utf8),
      let accounts = try? JSONDecoder().decode([UpgradeWidgetAccount].self, from: data)
    else { return [] }
    var seen = Set<String>()
    return accounts.compactMap { account in
      let tag = normalizedTag(account.tag)
      guard !tag.isEmpty, seen.insert(tag).inserted else { return nil }
      return tag
    }
  }
}

private struct UpgradeWidgetEntry: TimelineEntry {
  let date: Date
  let data: UpgradeWidgetData
  let images: [String: Data]
  let mediumTaskIndex: Int
}

private struct UpgradeTimelineProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> UpgradeWidgetEntry {
    UpgradeWidgetEntry(date: Date(), data: .placeholder, images: [:], mediumTaskIndex: 0)
  }

  func snapshot(for configuration: SelectUpgradeAccountIntent, in context: Context) async -> UpgradeWidgetEntry {
    let data: UpgradeWidgetData = context.isPreview
      ? .placeholder
      : (.current(accountTag: configuration.account?.id) ?? .empty)
    return UpgradeWidgetEntry(
      date: Date(),
      data: data,
      images: await images(for: data),
      mediumTaskIndex: 0
    )
  }

  func timeline(for configuration: SelectUpgradeAccountIntent, in context: Context) async -> Timeline<UpgradeWidgetEntry> {
    let data = UpgradeWidgetData.current(accountTag: configuration.account?.id) ?? .empty
    let now = Date()
    let imageData = await images(for: data)
    let rotationCount = data.mediumTaskChoices.count
    let baseEntry = UpgradeWidgetEntry(
      date: now,
      data: data,
      images: imageData,
      mediumTaskIndex: 0
    )
    let entries: [UpgradeWidgetEntry]
    if context.family == .systemMedium && rotationCount > 1 {
      let rotationInterval: TimeInterval = 15 * 60
      entries = (0..<rotationCount).map { index in
        UpgradeWidgetEntry(
          date: now.addingTimeInterval(TimeInterval(index) * rotationInterval),
          data: data,
          images: imageData,
          mediumTaskIndex: index
        )
      }
    } else {
      entries = [baseEntry]
    }
    let next = data.timelineDates.filter { $0 > now }.min() ?? now.addingTimeInterval(3600)
    let refreshDate: Date
    if context.family == .systemMedium && rotationCount > 1 {
      let rotationCycleEnd = now.addingTimeInterval(TimeInterval(rotationCount) * 15 * 60)
      refreshDate = min(next, rotationCycleEnd)
    } else {
      refreshDate = next
    }
    return Timeline(entries: entries, policy: .after(refreshDate))
  }

  private func images(for data: UpgradeWidgetData) async -> [String: Data] {
    var result: [String: Data] = [:]
    let urls = [data.hallImageUrl] + data.allTasks.map(\.imageUrl) + data.helpers.map(\.imageUrl) + data.boosts.compactMap(\.imageUrl)
    for imageUrl in urls where result[imageUrl] == nil && !imageUrl.isEmpty {
      guard let url = URL(string: imageUrl), url.scheme == "https" else { continue }
      if let (bytes, response) = try? await URLSession.shared.data(from: url),
         (response as? HTTPURLResponse)?.statusCode == 200 {
        result[imageUrl] = bytes
      }
    }
    return result
  }
}

private extension UpgradeWidgetData {
  var localizedLabels: UpgradeWidgetLabels { labels ?? .fallback }

  var allTasks: [UpgradeWidgetTask] {
    homeBuilders.tasks + laboratory.tasks + pets.tasks + builderBase.tasks
  }

  var allSections: [UpgradeWidgetSectionData] {
    [homeBuilders, laboratory, pets, builderBase]
  }

  func activeBoosts(at date: Date) -> [UpgradeWidgetBoost] {
    boosts.filter { boost in
      guard let expiresAt = boost.expiresAt else { return true }
      return expiresAt > date
    }
  }

  var mediumTaskChoices: [UpgradeWidgetTaskChoice] {
    let labels = localizedLabels
    let groups: [(String, [UpgradeWidgetTask])] = [
      (labels.village, homeBuilders.tasks),
      (labels.laboratory, laboratory.tasks),
      (labels.pets, pets.tasks),
      (labels.builderBase, builderBase.tasks),
    ]
    return groups.flatMap { title, tasks in
      tasks.map { UpgradeWidgetTaskChoice(title: title, task: $0) }
    }
  }

  var timelineDates: [Date] {
    let taskDates = allTasks.flatMap { task in
      [task.finishesAt, task.helperFinishesAt].compactMap { $0 }
    }
    return taskDates + activeBoosts(at: Date()).compactMap(\.expiresAt) + helpers.compactMap(\.statusUntil)
  }

  func hasFinishedTask(now: Date) -> Bool {
    (hasStaleData ?? false) ||
      allSections.contains { ($0.hiddenFinishesAt ?? .distantFuture) <= now } ||
      allTasks.contains { $0.finishesAt <= now }
  }
}

private struct UpgradeWidgetView: View {
  let entry: UpgradeWidgetEntry
  @Environment(\.widgetFamily) private var family
  private var labels: UpgradeWidgetLabels { entry.data.localizedLabels }

  var body: some View {
    Group {
      if family == .systemMedium {
        mediumBody
      } else {
        largeBody
      }
    }
    .containerBackground(for: .widget) { Color(.systemBackground) }
  }

  private var largeBody: some View {
    let activeBoosts = entry.data.activeBoosts(at: entry.date)
    return VStack(alignment: .leading, spacing: 7) {
      accountHeader
      if entry.data.hasFinishedTask(now: entry.date) {
        staleChip
      }

      if !activeBoosts.isEmpty {
        LazyVGrid(
          columns: [
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible())
          ],
          alignment: .leading,
          spacing: 4
        ) {
          ForEach(Array(activeBoosts.prefix(3))) { boost in
            boostPill(boost)
          }
        }
      }

      if !entry.data.helpers.isEmpty {
        helperStrip
      }

      HStack(alignment: .top, spacing: 7) {
        sectionCard(title: labels.homeVillage, section: entry.data.homeBuilders, columns: 1)
        VStack(alignment: .leading, spacing: 7) {
          sectionCard(title: labels.laboratory, section: entry.data.laboratory, columns: 1)
          sectionCard(title: labels.pets, section: entry.data.pets, columns: 1)
          sectionCard(title: labels.builderBase, section: entry.data.builderBase, columns: 1)
        }
      }
    }
  }

  private var mediumBody: some View {
    VStack(alignment: .leading, spacing: 6) {
      accountHeader
      if entry.data.hasFinishedTask(now: entry.date) {
        staleChip
      }
      if let choice = mediumTaskChoice {
        mediumTaskCard(choice)
      } else {
        HStack(alignment: .top, spacing: 7) {
          compactSection(title: labels.village, section: entry.data.homeBuilders)
          compactResearchSection
        }
      }
      HStack(spacing: 5) {
        ForEach(Array(entry.data.activeBoosts(at: entry.date).prefix(2))) { boost in
          mediumBoostSlot(boost)
        }
        if let helper = entry.data.helpers.first {
          mediumHelperSlot(helper)
        }
      }
    }
  }

  private var mediumTaskChoice: UpgradeWidgetTaskChoice? {
    let choices = entry.data.mediumTaskChoices
    guard !choices.isEmpty else { return nil }
    return choices[entry.mediumTaskIndex % choices.count]
  }

  private func mediumTaskCard(_ choice: UpgradeWidgetTaskChoice) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(choice.title)
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.secondary)
      taskRow(choice.task)
    }
    .padding(6)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 9))
  }

  private var accountHeader: some View {
    HStack(spacing: 8) {
      hallImage
      Text(entry.data.name)
        .font(.headline)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
      Spacer(minLength: 4)
      Text(entry.data.tag)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
    }
  }

  private var staleChip: some View {
    Text(labels.staleData ?? "Update needed")
      .font(.system(size: 8.5, weight: .bold))
      .foregroundStyle(.orange)
      .lineLimit(1)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(.orange.opacity(0.16), in: Capsule())
  }

  private func boostPill(_ boost: UpgradeWidgetBoost) -> some View {
    TimelineView(.periodic(from: .now, by: 60)) { context in
      Group {
        if boost.expiresAt == nil || boost.expiresAt! > context.date {
          HStack(spacing: 4) {
            boostImage(boost)
            VStack(alignment: .leading, spacing: 0) {
              Text(boost.label)
                .fontWeight(.semibold)
                .lineLimit(1)
              if let expiresAt = boost.expiresAt {
                Text(humanDuration(until: expiresAt, now: context.date))
                  .monospacedDigit()
                  .foregroundStyle(.secondary)
              }
            }
            Spacer(minLength: 0)
          }
          .font(.system(size: 8.5))
          .padding(.horizontal, 6)
          .padding(.vertical, 4)
          .foregroundStyle(boostColor(boost.kind))
          .background(boostColor(boost.kind).opacity(0.14), in: Capsule())
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }

  private func mediumBoostSlot(_ boost: UpgradeWidgetBoost) -> some View {
    TimelineView(.periodic(from: .now, by: 60)) { context in
      HStack(spacing: 3) {
        boostImage(boost)
        VStack(alignment: .leading, spacing: 0) {
          Text(boost.shortLabel ?? shortBoostName(boost.label))
            .fontWeight(.semibold)
          if let expiresAt = boost.expiresAt, expiresAt > context.date {
            Text(humanDuration(until: expiresAt, now: context.date))
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }
        }
        .font(.system(size: 7.5))
        .lineLimit(1)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 5)
      .padding(.vertical, 3)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(boostColor(boost.kind).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
  }

  private func mediumHelperSlot(_ helper: UpgradeWidgetHelper) -> some View {
    HStack(spacing: 3) {
      helperImage(helper)
      TimelineView(.periodic(from: .now, by: 60)) { context in
        VStack(alignment: .leading, spacing: 0) {
          Text(helper.shortName ?? shortHelperName(helper.name)).fontWeight(.semibold)
          Text(helper.statusUntil != nil && helper.statusUntil! <= context.date ? labels.ready : helper.status)
            .foregroundStyle(.secondary)
        }
        .font(.system(size: 7.5))
        .lineLimit(1)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 5)
    .padding(.vertical, 3)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
  }

  private var helperStrip: some View {
    HStack(alignment: .center, spacing: 8) {
      ForEach(Array(entry.data.helpers.prefix(3))) { helper in
        compactHelper(helper)
          .frame(maxWidth: 112, alignment: .leading)
      }
    }
    .frame(maxWidth: .infinity, alignment: .center)
  }

  private func compactHelper(_ helper: UpgradeWidgetHelper) -> some View {
    HStack(spacing: 4) {
      helperImage(helper)
      TimelineView(.periodic(from: .now, by: 60)) { context in
        VStack(alignment: .leading, spacing: 0) {
          Text(helper.shortName ?? shortHelperName(helper.name))
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
          HStack(spacing: 2) {
            Text(helper.statusUntil != nil && helper.statusUntil! <= context.date ? labels.ready : helper.status)
          if let until = helper.statusUntil, until > context.date {
            Text(humanDuration(until: until, now: context.date))
              .monospacedDigit()
          }
          }
        }
      }
      .font(.system(size: 8))
      .foregroundStyle(.secondary)
      .lineLimit(1)
      .minimumScaleFactor(0.75)
      Spacer(minLength: 0)
    }
  }

  private func compactSection(
    title: String,
    section: UpgradeWidgetSectionData
  ) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(title)
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.secondary)
      if let task = section.tasks.first {
        taskRow(task)
      } else {
        Text(emptySectionLabel(section))
          .font(.system(size: 8, weight: .medium))
          .foregroundStyle(.tertiary)
      }
    }
    .padding(6)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 9))
  }

  private var compactResearchSection: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(labels.research)
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.secondary)
      if let task = entry.data.laboratory.tasks.first ?? entry.data.pets.tasks.first ?? entry.data.builderBase.tasks.first {
        taskRow(task)
      } else {
        Text(labels.noActiveResearch)
          .font(.system(size: 8, weight: .medium))
          .foregroundStyle(.tertiary)
      }
    }
    .padding(6)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 9))
  }

  private func boostIcon(_ kind: String) -> String {
    switch kind {
    case "builderPotion", "townHallBuilder", "builderPerk": return "hammer.fill"
    case "researchPotion", "townHallLab", "labPerk": return "flask.fill"
    case "petPotion": return "pawprint.fill"
    case "clockTower": return "clock.fill"
    default: return "bolt.fill"
    }
  }

  private func boostColor(_ kind: String) -> Color {
    switch kind {
    case "builderPotion", "townHallBuilder", "builderPerk": return .orange
    case "researchPotion", "townHallLab", "labPerk": return .purple
    case "petPotion": return .pink
    case "clockTower": return .cyan
    default: return .secondary
    }
  }

  private func boostImage(_ boost: UpgradeWidgetBoost) -> some View {
    Group {
      if let imageUrl = boost.imageUrl,
         let data = entry.images[imageUrl],
         let image = UIImage(data: data) {
        Image(uiImage: image).resizable().scaledToFit()
      } else {
        Image(systemName: boostIcon(boost.kind))
      }
    }
    .frame(width: 19, height: 19)
  }

  private func shortHelperName(_ name: String) -> String {
    if name.localizedCaseInsensitiveContains("apprentice") { return "Apprentice" }
    if name.localizedCaseInsensitiveContains("assistant") { return "Assistant" }
    if name.localizedCaseInsensitiveContains("alchemist") { return "Alchemist" }
    return name
  }

  private func shortBoostName(_ name: String) -> String {
    if name.localizedCaseInsensitiveContains("builder") { return "Builder" }
    if name.localizedCaseInsensitiveContains("research") || name.localizedCaseInsensitiveContains("lab") { return "Research" }
    if name.localizedCaseInsensitiveContains("pet") { return "Pet" }
    if name.localizedCaseInsensitiveContains("clock") { return "Clock" }
    return name
  }

  private var hallImage: some View {
    Group {
      if let data = entry.images[entry.data.hallImageUrl], let image = UIImage(data: data) {
        Image(uiImage: image).resizable().scaledToFit()
      } else {
        RoundedRectangle(cornerRadius: 7).fill(.quaternary)
      }
    }
    .frame(width: 32, height: 32)
  }

  private func sectionCard(
    title: String,
    section: UpgradeWidgetSectionData,
    columns: Int
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 5) {
        Text(title)
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(.secondary)
          .lineLimit(1)
        Spacer(minLength: 3)
        let status = sectionStatus(section)
        if !status.isEmpty {
          Text(status)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(sectionStatusColor(section))
            .lineLimit(1)
        }
      }
      if !section.tasks.isEmpty {
        LazyVGrid(
          columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: columns),
          alignment: .leading,
          spacing: 3
        ) {
          ForEach(section.tasks) { task in
            taskRow(task)
          }
        }
      } else {
        Text(emptySectionLabel(section))
          .font(.system(size: 9, weight: .medium))
          .foregroundStyle(.tertiary)
          .frame(height: 21)
      }
    }
    .padding(.horizontal, 7)
    .padding(.vertical, 6)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
  }

  private func taskRow(_ task: UpgradeWidgetTask) -> some View {
    HStack(spacing: 5) {
      taskImage(task)
      VStack(alignment: .leading, spacing: 0) {
        Text(task.displayName)
          .font(.system(size: 10, weight: .semibold))
          .lineLimit(1)
        TimelineView(.periodic(from: .now, by: 1)) { context in
          HStack(spacing: 3) {
            Text("\(labels.level) \(task.fromLevel) → \(task.toLevel) ·")
            Text(humanDuration(until: task.finishesAt, now: context.date))
              .monospacedDigit()
          }
          .font(.system(size: 8, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Spacer(minLength: 0)
    }
    .frame(minHeight: 24)
  }

  private func sectionStatus(_ section: UpgradeWidgetSectionData) -> String {
    guard section.available else { return labels.locked }
    let taskCount = section.activeCount ?? section.tasks.reduce(0) { $0 + $1.displayCount }
    if taskCount == 0 && section.remainingCount == 0 { return labels.maxed }
    let idle = max(0, section.capacity - taskCount)
    if idle > 0 { return "\(idle) \(labels.idle)" }
    if taskCount > 0 { return "\(taskCount) \(labels.active)" }
    return ""
  }

  private func sectionStatusColor(_ section: UpgradeWidgetSectionData) -> Color {
    guard section.available else { return .secondary }
    let taskCount = section.activeCount ?? section.tasks.reduce(0) { $0 + $1.displayCount }
    if taskCount == 0 && section.remainingCount == 0 { return .green }
    if section.capacity > taskCount { return .orange }
    return .secondary
  }

  private func emptySectionLabel(_ section: UpgradeWidgetSectionData) -> String {
    guard section.available else { return labels.notUnlocked }
    return section.remainingCount == 0 ? labels.fullyUpgraded : labels.noActiveUpgrades
  }

  private func humanDuration(until end: Date, now: Date) -> String {
    let seconds = max(0, Int(end.timeIntervalSince(now)))
    let days = seconds / 86_400
    let hours = (seconds % 86_400) / 3_600
    let minutes = (seconds % 3_600) / 60
    let remainder = seconds % 60
    if days > 0 { return "\(days)d \(hours)h" }
    if hours > 0 { return "\(hours)h \(minutes)m" }
    return "\(minutes)m \(remainder)s"
  }

  private func taskImage(_ task: UpgradeWidgetTask) -> some View {
    Group {
      if let data = entry.images[task.imageUrl], let image = UIImage(data: data) {
        Image(uiImage: image).resizable().scaledToFit()
      } else {
        RoundedRectangle(cornerRadius: 6).fill(.quaternary)
      }
    }
    .frame(width: 27, height: 27)
  }

  private func helperImage(_ helper: UpgradeWidgetHelper) -> some View {
    Group {
      if let data = entry.images[helper.imageUrl], let image = UIImage(data: data) {
        Image(uiImage: image).resizable().scaledToFit()
      } else {
        Image(systemName: "person.crop.circle.badge.clock")
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 18, height: 18)
  }
}

private struct UpgradeWidget: Widget {
  let kind = "UpgradeWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: SelectUpgradeAccountIntent.self,
      provider: UpgradeTimelineProvider()
    ) { entry in
      UpgradeWidgetView(entry: entry)
    }
    .configurationDisplayName("Upgrade Progress")
    .description("Track active upgrades for a linked account.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

@main
struct ClashKingWidgetBundle: WidgetBundle {
  var body: some Widget {
    WarWidget()
    UpgradeWidget()
  }
}
