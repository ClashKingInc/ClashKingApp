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
// Keep positive scores and the completion ring on the same ClashKing accent.
private let widgetPositiveColor = Color(red: 0.078, green: 0.639, blue: 0.498)

private func widgetBadgeURL(_ url: URL) -> URL? {
  guard url.host == "badges.clashk.ing" else { return url }
  var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
  components?.path = url.deletingPathExtension().path + ".png"
  components?.queryItems = [URLQueryItem(name: "size", value: "256")]
  components?.fragment = nil
  return components?.url
}

private func widgetClanBadge(_ tag: String?) -> String? {
  let normalized = (tag ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    .replacingOccurrences(of: "#", with: "").uppercased()
  guard !normalized.isEmpty,
        normalized.range(of: "^[A-Z0-9]+$", options: .regularExpression) != nil else { return nil }
  return "https://badges.clashk.ing/\(normalized).png?size=256"
}

private func widgetDestination(tag: String?, upgrade: Bool) -> URL? {
  let normalized = (tag ?? "").replacingOccurrences(of: "#", with: "").uppercased()
  guard !normalized.isEmpty,
        normalized.range(of: "^[A-Z0-9]+$", options: .regularExpression) != nil else {
    return URL(string: upgrade ? "clashking://upgrade-tracker" : "clashking://war")
  }
  return URL(string: upgrade
    ? "clashking://upgrade-tracker?player=\(normalized)"
    : "clashking://clan/\(normalized)/war")
}

private func legendsWidgetDestination(tag: String?) -> URL? {
  let normalized = (tag ?? "").replacingOccurrences(of: "#", with: "").uppercased()
  guard !normalized.isEmpty,
        normalized.range(of: "^[A-Z0-9]+$", options: .regularExpression) != nil else {
    return URL(string: "clashking://legends")
  }
  var components = URLComponents()
  components.scheme = "clashking"
  components.host = "player"
  components.path = "/\(normalized)"
  components.queryItems = [URLQueryItem(name: "tab", value: "legends")]
  return components.url
}

struct WarWidgetEntry: TimelineEntry {
  let date: Date
  let data: WarWidgetData
  let clanBadgeData: Data?
  let opponentBadgeData: Data?
  var selectedClanTag: String? = nil
  var selectedClanName: String? = nil
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

  // No cached payload is not evidence that the clan has no war.
  static let empty = status("unconfigured")

  static func status(_ state: String, clan: Side? = nil) -> WarWidgetData {
    WarWidgetData(
      state: state, mode: "war", updatedAt: nil, timeState: nil,
      score: nil, statusIcon: nil, primaryText: nil, secondaryText: nil,
      colorTheme: "neutral", clan: clan, opponent: nil, cwlRank: nil, cwlLeague: nil
    )
  }

  static func current(clanTag: String? = nil) -> WarWidgetData {
    guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
      return .empty
    }

    guard let clanTag, !clanTag.isEmpty else { return .empty }
    let raw = defaults.string(forKey: "warInfo_\(Self.normalizedClanTag(clanTag))")

    guard
      let raw,
      let data = raw.data(using: .utf8),
      let decoded = try? JSONDecoder().decode(WarWidgetData.self, from: data)
    else {
      return .status("unavailable")
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
    makeEntry(data: context.isPreview ? .placeholder : .current(clanTag: configuration.clan?.id), clanTag: configuration.clan?.id, clanName: configuration.clan?.name)
  }

  func timeline(for configuration: SelectWarClanIntent, in context: Context) async -> Timeline<WarWidgetEntry> {
    let clanTag = configuration.clan?.id
    let data = await WarWidgetFreshFetcher().fetch(clanTag: clanTag) ?? .current(clanTag: clanTag)
    let entry = makeEntry(data: data, clanTag: clanTag, clanName: configuration.clan?.name)
    let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
    return Timeline(entries: [entry], policy: .after(next))
  }

  private func makeEntry(data: WarWidgetData, clanTag: String? = nil, clanName: String? = nil) -> WarWidgetEntry {
    WarWidgetEntry(
      date: Date(),
      data: data,
      clanBadgeData: fetchBadgeData(widgetClanBadge(clanTag) ?? data.clan?.badgeUrlMedium),
      opponentBadgeData: fetchBadgeData(data.opponent?.badgeUrlMedium),
      selectedClanTag: clanTag,
      selectedClanName: clanName
    )
  }

  private func fetchBadgeData(_ urlString: String?) -> Data? {
    guard
      let urlString,
      let originalURL = URL(string: urlString),
      let url = widgetBadgeURL(originalURL),
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
        while Darwin.lockf(descriptor, F_TLOCK, 0) != 0 {
          let lockError = errno
          if lockError != EACCES && lockError != EAGAIN {
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
    Darwin.lockf(descriptor, F_ULOCK, 0)
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
    let baseUrl = defaults.string(forKey: "warWidgetApiV2Url") ?? "https://api.clashk.ing/v2"
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

    let baseUrl = defaults.string(forKey: "warWidgetProxyUrl") ?? "https://api.clashk.ing/proxy/v1"
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
      guard let httpResponse = response as? HTTPURLResponse else { return nil }
      let raw: [String: Any]
      if httpResponse.statusCode == 403 {
        // Private regular logs can still have a readable CWL group. Keep that
        // lookup below, then represent privacy rather than an empty/no-war state.
        raw = ["state": "accessDenied"]
      } else if httpResponse.statusCode == 200,
                let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
        raw = decoded
      } else {
        return nil
      }
      // currentwar can be tomorrow's CWL preparation while today's round is still live.
      // Resolve the league rounds before replacing the cached widget snapshot.
      var resolvedWar = raw
      var isCwl = false
      if let group = try await fetchJSON(path: "/clans/\(encodedTag)/currentwar/leaguegroup", baseUrl: baseUrl, token: token),
         let rounds = group["rounds"] as? [[String: Any]] {
        var fallback: [String: Any]?
        for round in rounds.reversed() {
          let tags = (round["warTags"] as? [String] ?? []).filter { $0 != "#0" }
          var ourWar: [String: Any]?
          for tag in tags {
            guard let encoded = tag.addingPercentEncoding(withAllowedCharacters: allowed),
                  let war = try await fetchJSON(path: "/clanwarleagues/wars/\(encoded)", baseUrl: baseUrl, token: token) else { continue }
            if normalizedClanTag(string(dictionary(war["clan"])["tag"]) ?? "") == normalizedClanTag(clanTag) ||
               normalizedClanTag(string(dictionary(war["opponent"])["tag"]) ?? "") == normalizedClanTag(clanTag) {
              ourWar = war
              break
            }
          }
          guard let war = ourWar else { continue }
          if string(war["state"]) == "inWar" {
            fallback = war
            break
          }
          if fallback == nil { fallback = war }
          if string(war["state"]) == "warEnded" { break }
        }
        if let war = fallback {
          resolvedWar = war
          isCwl = true
        }
      }
      if normalizedClanTag(string(dictionary(resolvedWar["opponent"])["tag"]) ?? "") == normalizedClanTag(clanTag) {
        let originalClan = resolvedWar["clan"]
        resolvedWar["clan"] = resolvedWar["opponent"]
        resolvedWar["opponent"] = originalClan
      }
      let widgetData = buildProxyCurrentWarData(from: resolvedWar, clanTag: clanTag, defaults: defaults, isCwl: isCwl)
      cache(widgetData, clanTag: clanTag, defaults: defaults)
      return widgetData
    } catch {
      return nil
    }
  }

  private func fetchJSON(path: String, baseUrl: String, token: String) async throws -> [String: Any]? {
    guard let url = URL(string: baseUrl + path) else { return nil }
    var request = URLRequest(url: url)
    request.timeoutInterval = 10
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let response = response as? HTTPURLResponse else { return nil }
    if response.statusCode == 403 || response.statusCode == 404 { return nil }
    guard response.statusCode == 200 else { throw URLError(.badServerResponse) }
    return try JSONSerialization.jsonObject(with: data) as? [String: Any]
  }

  private func cache(_ data: WarWidgetData, clanTag: String, defaults: UserDefaults) {
    guard let encoded = try? JSONEncoder().encode(data), let raw = String(data: encoded, encoding: .utf8) else {
      return
    }
    defaults.set(raw, forKey: "warInfo_\(normalizedClanTag(clanTag))")
  }

  private func buildProxyCurrentWarData(from currentWar: [String: Any], clanTag: String, defaults: UserDefaults, isCwl: Bool = false) -> WarWidgetData {
    let state = string(currentWar["state"]) ?? "notInWar"
    guard ["preparation", "inWar", "warEnded"].contains(state) else {
      let selectedClan = cachedClanSide(clanTag: clanTag, defaults: defaults)
      let status = state == "notInWar" || state == "accessDenied" ? state : "unavailable"
      return .status(status, clan: selectedClan)
    }
    return buildRegularWarData(currentWar: currentWar, state: state, isCwl: isCwl)
  }

  private func buildRegularWarData(currentWar: [String: Any], state: String, isCwl: Bool = false) -> WarWidgetData {
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
      mode: isCwl ? "cwl" : "war",
      updatedAt: updatedAt(),
      timeState: timeState,
      score: score,
      statusIcon: statusIcon,
      primaryText: primaryText,
      secondaryText: secondaryText,
      colorTheme: colorTheme,
      clan: side(from: clan, stars: clanStars, teamSize: teamSize, attacksPerMember: isCwl ? 1 : 2),
      opponent: side(from: opponent, stars: opponentStars, teamSize: teamSize, attacksPerMember: isCwl ? 1 : 2),
      cwlRank: nil,
      cwlLeague: nil
    )
  }

  private func side(from raw: [String: Any], stars: Int, teamSize: Int, attacksPerMember: Int) -> WarWidgetData.Side {
    let destruction = double(raw["destructionPercentage"])
    return WarWidgetData.Side(
      name: string(raw["name"]) ?? "Unknown",
      badgeUrlMedium: widgetClanBadge(string(raw["tag"])) ?? "https://assets.clashk.ing/clashkinglogo.png",
      percent: String(format: "%.2f%%", destruction),
      attacks: "\(int(raw["attacks"]))/\(teamSize * attacksPerMember)",
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
    Group {
      switch family {
      case .systemSmall:
        compactWarView
      case .accessoryRectangular:
        accessoryView
      default:
        mediumWarView
      }
    }
    .widgetURL(widgetDestination(tag: entry.selectedClanTag, upgrade: false))
  }

  private var compactWarView: some View {
    VStack(spacing: 6) {
      if entry.data.opponent == nil {
        emptyStateView
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        Text(entry.data.primaryText ?? entry.data.timeState ?? "")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.primary)
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
        // Keep the small War widget focused on identity, score and timing.
        // Attack counts remain available in the medium layout and app.
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
        GeometryReader { geometry in
          let centerWidth = min(120, max(100, geometry.size.width * 0.34))
          let sideWidth = max(0, (geometry.size.width - centerWidth - 16) / 2)
          let baseNameSize = UIFont.preferredFont(forTextStyle: .caption1).pointSize
          let measuringFont = UIFont.systemFont(ofSize: baseNameSize, weight: .semibold)
          let longestNameWidth = [entry.data.clan?.name ?? "Unknown", entry.data.opponent?.name ?? "Unknown"]
            .map { ($0 as NSString).size(withAttributes: [.font: measuringFont]).width }
            .max() ?? 1
          let sharedNameSize = max(8, baseNameSize * min(1, sideWidth / max(1, longestNameWidth)))
          HStack(alignment: .center, spacing: 8) {
          sideView(entry.data.clan, badgeData: entry.clanBadgeData, badgeSize: 52, uniformText: true, nameFontSize: sharedNameSize)
            .frame(width: sideWidth)
            .layoutPriority(1)
          VStack(spacing: 4) {
            Text(entry.data.primaryText ?? entry.data.timeState ?? "")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.primary)
              .lineLimit(1)
              .minimumScaleFactor(0.75)
            scoreLabel(size: scoreText == "-" ? 22 : 29, minScale: 0.72)
          }
          .frame(width: centerWidth)
          .layoutPriority(4)
          sideView(entry.data.opponent, badgeData: entry.opponentBadgeData, badgeSize: 52, uniformText: true, nameFontSize: sharedNameSize)
            .frame(width: sideWidth)
            .layoutPriority(1)
          }
          .frame(height: geometry.size.height)
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
              .foregroundStyle(.primary)
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
        Text(entry.data.clan?.name ?? entry.selectedClanName ?? "ClashKing")
          .font(.system(size: 10, weight: .semibold))
          .lineLimit(1)
          .truncationMode(.tail)
        if entry.data.opponent == nil {
          Text(emptyStateTitle).font(.caption2).lineLimit(2)
        } else {
          scoreLabel(size: 17, minScale: 0.72, leading: true)
          Text(entry.data.primaryText ?? entry.data.timeState ?? "War")
            .font(.caption2)
            .lineLimit(1)
        }
      }
    }
    .widgetBackground
  }

  private var header: some View {
    HStack(spacing: 6) {
      Text(entry.data.mode == "cwl" ? "CWL" : "War")
        .font(.caption.weight(.bold))
        .lineLimit(1)
      Spacer(minLength: 4)
      Text(entry.data.updatedAt ?? "")
        .font(.caption2)
        .foregroundStyle(.primary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
  }

  private var footer: some View {
    Text(entry.data.secondaryText ?? entry.data.timeState ?? "")
      .font(.caption2)
      .foregroundStyle(.primary)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
  }

  private func attacksMetric(_ side: WarWidgetData.Side?, uniformText: Bool = false) -> some View {
    HStack(spacing: 3) {
      Group {
        if let sword = UIImage(named: "Icon_HV_Sword") {
          Image(uiImage: sword).resizable().widgetArtwork.scaledToFit()
        } else {
          Image(systemName: "sword").resizable().scaledToFit()
        }
      }
      .frame(width: 14, height: 14)
      // The shared payload already uses two attacks/member for regular wars
      // and one for CWL. Do not infer a denominator from stars or destruction.
      Text(side?.attacks ?? "—")
        .font(.caption2.weight(.semibold).monospacedDigit())
        .foregroundStyle(.primary)
        .lineLimit(1)
        .minimumScaleFactor(uniformText ? 1 : 0.72)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(String(localized: "legends_widget_attacks", table: "LegendsWidget"))
    .accessibilityValue(side?.attacks ?? "—")
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

  private var emptyStateTitle: String {
    let key: String
    switch entry.data.state {
    case "notInWar": key = "war_state_idle"
    case "accessDenied": key = "war_state_private"
    case "unconfigured", "notInClan": key = "war_state_choose"
    case "cwl": key = "war_state_idle"
    default: key = "war_state_unavailable"
    }
    return NSLocalizedString(key, tableName: "LegendsWidget", comment: "War widget status")
  }

  private var emptyClanName: String {
    entry.selectedClanName ?? entry.data.clan?.name ?? "ClashKing"
  }

  private var emptyStateMessage: String {
    let key: String
    switch entry.data.state {
    case "notInWar", "cwl": key = "war_state_idle_message"
    case "accessDenied": key = "war_state_private_message"
    default:
      return entry.selectedClanName == nil ? emptyStateTitle : "\(emptyClanName)\n\(emptyStateTitle)"
    }
    return String(format: NSLocalizedString(key, tableName: "LegendsWidget", comment: "Clan war status"), emptyClanName)
  }

  private var emptyStateBadge: some View {
    Group {
      if let data = entry.clanBadgeData, let image = UIImage(data: data) {
        Image(uiImage: image).resizable().widgetArtwork.scaledToFit()
      } else {
        Image("Icon_HV_Sword").resizable().widgetArtwork.scaledToFit()
      }
    }
    .frame(width: family == .systemSmall ? 42 : 54, height: family == .systemSmall ? 42 : 54)
    .accessibilityHidden(true)
  }

  private var emptyStateView: some View {
    Group {
      if family == .systemSmall {
        VStack(spacing: 12) {
          emptyStateBadge
          Text(emptyStateMessage)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(4)
            .minimumScaleFactor(0.8)
        }
      } else {
        HStack(spacing: 16) {
          emptyStateBadge
          Text(emptyStateMessage)
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(3)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement(children: .combine)
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

  private func scoreLabel(size: CGFloat, minScale: CGFloat, leading: Bool = false) -> some View {
    Text(compactScoreText)
      .font(.system(size: size, weight: .bold, design: .rounded).monospacedDigit())
      .lineLimit(1)
      .minimumScaleFactor(minScale)
      .allowsTightening(true)
      // The accessory score shares the timer's leading edge. Home Screen
      // score layouts retain their centered alignment between clan sides.
      .multilineTextAlignment(leading ? .leading : .center)
      .frame(maxWidth: .infinity, alignment: leading ? .leading : .center)
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

  private func sideView(_ side: WarWidgetData.Side?, badgeData: Data?, badgeSize: CGFloat = 54, uniformText: Bool = false, nameFontSize: CGFloat? = nil) -> some View {
    VStack(spacing: 5) {
      badgeView(side, badgeData: badgeData, size: badgeSize)
      Text(side?.name ?? "Unknown")
        .font(nameFontSize.map { Font.system(size: $0, weight: .semibold) } ?? .caption.weight(.semibold))
        .multilineTextAlignment(.center)
        .lineLimit(1)
        // Measure both medium names together so even the shorter name uses the
        // same font size. Only unusually long names truncate at the shared floor.
        .minimumScaleFactor(uniformText ? 1 : 0.7)
      attacksMetric(side, uniformText: uniformText)
    }
    .frame(maxWidth: .infinity)
  }

  private func badgeView(_ side: WarWidgetData.Side?, badgeData: Data?, size: CGFloat) -> some View {
    Group {
      if let badgeData, let image = UIImage(data: badgeData) {
        Image(uiImage: image)
          .renderingMode(.original)
          .resizable()
          .widgetArtwork
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
      Text(label).font(.caption2).foregroundStyle(.primary)
      Text(value).font(.caption.weight(.semibold)).monospacedDigit().lineLimit(1)
    }
  }
}

private extension View {
  @ViewBuilder var widgetBackground: some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.modifier(StandardWidgetBackground())
    } else {
      self.background(Color(.secondarySystemBackground))
    }
  }
}

@available(iOSApplicationExtension 17.0, *)
private struct StandardWidgetBackground: ViewModifier {
  func body(content: Content) -> some View {
    // Keep the entire background removable. In Clear/Tinted appearance iOS
    // replaces this container with its own glass; a custom material or border
    // belongs neither in the foreground nor on top of that system surface.
    content.containerBackground(.fill.tertiary, for: .widget)
  }
}

private extension Image {
  @ViewBuilder var widgetArtwork: some View {
    if #available(iOSApplicationExtension 18.0, *) {
      // Preserve artwork detail instead of turning opaque game images into
      // white silhouettes. Normal appearance retains the original colors;
      // Clear/Tinted follows the system's monochrome treatment.
      self.widgetAccentedRenderingMode(.desaturated)
    } else {
      self
    }
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
    .containerBackgroundRemovable(true)
  }
}

private struct LegendsWidgetPlayer: Codable {
  let tag: String
  let name: String
  let townHallLevel: Int
}

struct LegendsWidgetPlayerEntity: AppEntity, Identifiable {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(
    name: LocalizedStringResource("legends_widget_player_label", table: "LegendsWidget")
  )
  static let defaultQuery = LegendsWidgetPlayerQuery()

  let id: String
  let name: String
  let townHallLevel: Int

  var displayRepresentation: DisplayRepresentation {
    let hall = townHallLevel > 0 ? " · TH\(townHallLevel)" : ""
    return DisplayRepresentation(title: "\(name)", subtitle: "\(id)\(hall)")
  }
}

struct LegendsWidgetPlayerQuery: EntityStringQuery {
  func entities(for identifiers: [LegendsWidgetPlayerEntity.ID]) async throws -> [LegendsWidgetPlayerEntity] {
    let requested = Set(identifiers.map(Self.normalizedTag))
    return allEntities().filter { requested.contains(Self.normalizedTag($0.id)) }
  }

  func entities(matching string: String) async throws -> [LegendsWidgetPlayerEntity] {
    guard !string.isEmpty else { return allEntities() }
    return allEntities().filter {
      $0.name.localizedCaseInsensitiveContains(string) ||
      $0.id.localizedCaseInsensitiveContains(string)
    }
  }

  func suggestedEntities() async throws -> [LegendsWidgetPlayerEntity] { allEntities() }
  func defaultResult() async -> LegendsWidgetPlayerEntity? { allEntities().first }

  fileprivate func allEntities() -> [LegendsWidgetPlayerEntity] {
    let defaults = UserDefaults(suiteName: appGroupIdentifier)
    defaults?.synchronize()
    guard
      let raw = defaults?.string(forKey: "legendsWidgetPlayers"),
      let data = raw.data(using: .utf8),
      let players = try? JSONDecoder().decode([LegendsWidgetPlayer].self, from: data)
    else { return [] }

    var seen = Set<String>()
    return players.compactMap { player in
      let normalized = Self.normalizedTag(player.tag)
      let name = player.name.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !normalized.isEmpty, !name.isEmpty, seen.insert(normalized).inserted else { return nil }
      return LegendsWidgetPlayerEntity(
        id: Self.canonicalTag(normalized),
        name: name,
        townHallLevel: player.townHallLevel
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

struct SelectLegendsPlayerIntent: WidgetConfigurationIntent {
  static let title = LocalizedStringResource("legends_widget_label", table: "LegendsWidget")
  static let description = IntentDescription(
    LocalizedStringResource("legends_widget_player_picker_description", table: "LegendsWidget")
  )

  @Parameter(title: LocalizedStringResource("legends_widget_player_label", table: "LegendsWidget"))
  var player: LegendsWidgetPlayerEntity?
}

private struct LegendsWidgetBattle: Codable {
  let trophies: Int?
  let battleTime: Date?
  let opponentName: String?
  let opponentTownHallLevel: Int?
  let stars: Int?
  let destructionPercentage: Double?
}

private struct LegendsWidgetClan: Codable {
  let tag: String?
  let name: String?
  let badgeUrl: String?
}

private struct LegendsWidgetLeague: Codable {
  let name: String
  let iconUrl: String?
}

private struct LegendsWidgetArtwork: Codable {
  let attackIconUrl: String?
  let defenseIconUrl: String?
  let trophyIconUrl: String?
  let starFilledIconUrl: String?
  let starEmptyIconUrl: String?
}

private struct LegendsWidgetLabels: Codable {
  let title: String
  let day: String?
  let dayFormatted: String?
  let attacks: String
  let defenses: String
  let globalRank: String
  let latestAttack: String
  let latestDefense: String
  let noData: String
  let staleData: String
  let updated: String

  static let fallback = LegendsWidgetLabels(
    title: "Legend League",
    day: "Day",
    dayFormatted: nil,
    attacks: "Attacks",
    defenses: "Defenses",
    globalRank: "Global rank",
    latestAttack: "Latest attack",
    latestDefense: "Latest defense",
    noData: "Open ClashKing to load",
    staleData: "Previous Legend day",
    updated: "Updated"
  )
}

private struct LegendsWidgetData: Codable {
  let schemaVersion: Int
  var mode: String? = nil
  var destinationUrl: String? = nil
  var periodLabel: String? = nil
  var attacksLimit: Int? = nil
  var defensesLimit: Int? = nil
  var league: LegendsWidgetLeague? = nil
  var locale: String? = nil
  let tag: String
  let name: String
  let townHallLevel: Int
  let townHallImageUrl: String?
  let updatedAt: Date
  let legendDay: String?
  let legendDayIndex: Int?
  let dayStartsAt: Date?
  let dayEndsAt: Date?
  let trophies: Int?
  let globalRank: Int?
  let attackTrophies: Int?
  let defenseTrophies: Int?
  let netTrophies: Int?
  let attacksUsed: Int?
  let defensesTaken: Int?
  let latestAttack: LegendsWidgetBattle?
  let latestDefense: LegendsWidgetBattle?
  let clan: LegendsWidgetClan?
  let artwork: LegendsWidgetArtwork?
  let labels: LegendsWidgetLabels?

  var localizedLabels: LegendsWidgetLabels { labels ?? .fallback }
  var hasData: Bool {
    // Preserve a selected player's identity while the battle feed is unavailable;
    // optional counters still show unknown instead of fabricating an empty day.
    (!tag.isEmpty && !name.isEmpty) || trophies != nil || globalRank != nil || netTrophies != nil || attacksUsed != nil ||
      defensesTaken != nil || latestAttack != nil || latestDefense != nil
  }

  static let placeholder = LegendsWidgetData(
    schemaVersion: 1,
    tag: "#PLAYER",
    name: "Chief",
    townHallLevel: 18,
    townHallImageUrl: nil,
    updatedAt: Date(),
    legendDay: "2026-09-22",
    legendDayIndex: 23,
    dayStartsAt: Date().addingTimeInterval(-18_000),
    dayEndsAt: Date().addingTimeInterval(68_400),
    trophies: 5_600,
    globalRank: 42,
    attackTrophies: 120,
    defenseTrophies: -80,
    netTrophies: 40,
    attacksUsed: 3,
    defensesTaken: 2,
    latestAttack: LegendsWidgetBattle(trophies: 40, battleTime: Date().addingTimeInterval(-1_800), opponentName: "Opponent", opponentTownHallLevel: 18, stars: 3, destructionPercentage: 100),
    latestDefense: LegendsWidgetBattle(trophies: -30, battleTime: Date().addingTimeInterval(-900), opponentName: "Attacker", opponentTownHallLevel: 18, stars: 2, destructionPercentage: 86.4),
    clan: LegendsWidgetClan(tag: "#CLAN", name: "ClashKing", badgeUrl: nil),
    artwork: nil,
    labels: .fallback
  )

  static func empty(player: LegendsWidgetPlayerEntity?) -> LegendsWidgetData {
    LegendsWidgetData(
      schemaVersion: 1,
      tag: player?.id ?? "",
      name: player?.name ?? "ClashKing",
      townHallLevel: player?.townHallLevel ?? 0,
      townHallImageUrl: nil,
      updatedAt: Date(),
      legendDay: nil,
      legendDayIndex: nil,
      dayStartsAt: nil,
      dayEndsAt: nil,
      trophies: nil,
      globalRank: nil,
      attackTrophies: nil,
      defenseTrophies: nil,
      netTrophies: nil,
      attacksUsed: nil,
      defensesTaken: nil,
      latestAttack: nil,
      latestDefense: nil,
      clan: nil,
      artwork: nil,
      labels: .fallback
    )
  }

  static func current(player: LegendsWidgetPlayerEntity?) -> LegendsWidgetData? {
    guard
      let player,
      let defaults = UserDefaults(suiteName: appGroupIdentifier)
    else { return nil }
    defaults.synchronize()
    let normalized = LegendsWidgetPlayerQuery.normalizedTag(player.id)
    let linked = LegendsWidgetPlayerQuery().allEntities()
      .contains { LegendsWidgetPlayerQuery.normalizedTag($0.id) == normalized }
    guard linked, !normalized.isEmpty else { return nil }
    guard
      let raw = defaults.string(forKey: "legendsWidget_\(normalized)"),
      let data = raw.data(using: .utf8),
      let decoded = try? makeDecoder().decode(LegendsWidgetData.self, from: data),
      decoded.schemaVersion == 1,
      LegendsWidgetPlayerQuery.normalizedTag(decoded.tag) == normalized
    else { return nil }
    return decoded
  }

  func merging(
    battlelog: LegendsFreshBattlelog?,
    rankLookup: LegendsFreshRankLookup?,
    player: LegendsFreshPlayer?,
    day: LegendsDayWindow,
    refreshedAt: Date
  ) -> LegendsWidgetData {
    let refreshedDay = battlelog != nil
    let refreshedRank = rankLookup != nil
    let latestAttack = battlelog?.attacks
      .filter { $0.battleTime != nil }
      .max { ($0.battleTime ?? .distantPast) < ($1.battleTime ?? .distantPast) }?
      .widgetBattle
    let latestDefense = battlelog?.defenses
      .filter { $0.battleTime != nil }
      .max { ($0.battleTime ?? .distantPast) < ($1.battleTime ?? .distantPast) }?
      .widgetBattle
    return LegendsWidgetData(
      schemaVersion: schemaVersion,
      mode: "legends",
      destinationUrl: destinationUrl,
      attacksLimit: 8,
      defensesLimit: 8,
      tag: tag,
      name: player?.name ?? name,
      townHallLevel: player?.townHallLevel ?? townHallLevel,
      townHallImageUrl: player?.townHallImageUrl ?? townHallImageUrl,
      // This timestamp describes the Legend-day snapshot. A rank-only refresh must not
      // make older daily attack and defense metrics appear fresh.
      updatedAt: refreshedDay ? refreshedAt : updatedAt,
      legendDay: refreshedDay ? day.day : legendDay,
      legendDayIndex: refreshedDay && legendDay != day.day ? nil : legendDayIndex,
      dayStartsAt: refreshedDay ? day.start : dayStartsAt,
      dayEndsAt: refreshedDay ? day.end : dayEndsAt,
      // A fresh day snapshot must not make a retained rank look fresh when the
      // independent rank request failed. Rank-only refreshes can still update
      // rank without changing the daily snapshot timestamp.
      trophies: refreshedRank ? rankLookup?.item?.trophies : (refreshedDay ? nil : trophies),
      globalRank: refreshedRank ? rankLookup?.item?.globalRank : (refreshedDay ? nil : globalRank),
      attackTrophies: battlelog?.attackTrophies ?? attackTrophies,
      defenseTrophies: battlelog?.defenseTrophies ?? defenseTrophies,
      netTrophies: battlelog?.netTrophies ?? netTrophies,
      attacksUsed: battlelog?.attacks.count ?? attacksUsed,
      defensesTaken: battlelog?.defenses.count ?? defensesTaken,
      latestAttack: refreshedDay ? latestAttack : self.latestAttack,
      latestDefense: refreshedDay ? latestDefense : self.latestDefense,
      clan: player == nil ? clan : player?.widgetClan,
      artwork: artwork,
      labels: labels
    )
  }

  fileprivate static func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let value = try container.decode(String.self)
      let fractional = ISO8601DateFormatter()
      fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = fractional.date(from: value) { return date }
      if let date = ISO8601DateFormatter().date(from: value) { return date }
      let clash = DateFormatter()
      clash.locale = Locale(identifier: "en_US_POSIX")
      clash.timeZone = TimeZone(secondsFromGMT: 0)
      clash.dateFormat = "yyyyMMdd'T'HHmmss.SSS'Z'"
      if let date = clash.date(from: value) { return date }
      clash.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
      if let date = clash.date(from: value) { return date }
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO-8601 date")
    }
    return decoder
  }
}

private struct LegendsDayWindow {
  let day: String
  let start: Date
  let end: Date

  static func current(at date: Date) -> LegendsDayWindow {
    let shifted = date.addingTimeInterval(-(5 * 60) * 60)
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: shifted)
    let year = components.year ?? 1970
    let month = components.month ?? 1
    let dayOfMonth = components.day ?? 1
    let label = String(format: "%04d-%02d-%02d", year, month, dayOfMonth)
    let start = ISO8601DateFormatter().date(from: "\(label)T05:00:00Z") ?? date
    return LegendsDayWindow(day: label, start: start, end: start.addingTimeInterval(86_400))
  }
}

private struct LegendsFreshBattle: Decodable {
  struct Opponent: Decodable {
    let name: String
    let townHallLevel: Int
  }

  let trophies: Int
  let time: Date?
  let opponent: Opponent?
  let stars: Int?
  let destructionPercentage: Double?

  var battleTime: Date? { time }
  var widgetBattle: LegendsWidgetBattle {
    LegendsWidgetBattle(
      trophies: trophies,
      battleTime: time,
      opponentName: opponent?.name,
      opponentTownHallLevel: opponent?.townHallLevel,
      stars: stars,
      destructionPercentage: destructionPercentage
    )
  }
}

private struct LegendsFreshBattlelog: Decodable {
  let tag: String
  let day: String
  let attackTrophies: Int
  let defenseTrophies: Int
  let trophies: Int
  let attacks: [LegendsFreshBattle]
  let defenses: [LegendsFreshBattle]

  var netTrophies: Int { trophies }
}

private struct LegendsFreshRank: Decodable {
  let tag: String
  let trophies: Int
  let globalRank: Int
}

private struct LegendsFreshRankResponse: Decodable {
  let items: [LegendsFreshRank]
}

private struct LegendsFreshRankLookup {
  let item: LegendsFreshRank?
}

private struct LegendsFreshPlayer: Decodable {
  struct Clan: Decodable {
    let tag: String
    let name: String
  }

  let tag: String
  let name: String
  let townHallLevel: Int
  let clan: Clan?
  let currentLeagueGroupTag: String?
  let currentLeagueSeasonId: Int?
  let leagueTier: RankedFreshTier?
  let league: RankedFreshTier?

  var townHallImageUrl: String? {
    guard townHallLevel > 0 else { return nil }
    return "https://assets.clashk.ing/buildings/home-village/town_hall/level_\(townHallLevel).webp"
  }

  var widgetClan: LegendsWidgetClan? {
    guard let clan, !clan.tag.isEmpty else { return nil }
    return LegendsWidgetClan(tag: clan.tag, name: clan.name, badgeUrl: widgetClanBadge(clan.tag))
  }
}

private struct RankedFreshTier: Decodable {
  struct Icons: Decodable { let small: String?; let large: String? }
  let id: Int
  let name: String
  let iconUrls: Icons?
}

private struct RankedFreshMember: Decodable {
  let playerTag: String
  let leagueTrophies: Int
  let attackWinCount: Int
  let attackLoseCount: Int
  let defenseWinCount: Int
  let defenseLoseCount: Int
}

private struct RankedOfficialBattle: Decodable {
  let trophies: Int
  let creationTime: Date
  let opponentName: String
  let stars: Int
  let destructionPercentage: Double
  var widget: LegendsWidgetBattle {
    LegendsWidgetBattle(trophies: trophies, battleTime: creationTime, opponentName: opponentName, opponentTownHallLevel: nil, stars: stars, destructionPercentage: destructionPercentage)
  }
}

private struct RankedFreshGroup: Decodable {
  let members: [RankedFreshMember]?
  let attackLogs: [RankedOfficialBattle]?
  let defenseLogs: [RankedOfficialBattle]?
}

private struct RankedAnalyticsBattle: Decodable {
  struct Opponent: Decodable { let townHallLevel: Int? }
  let trophies: Int
  let time: Date?
  let automatic: Bool?
  let stars: Int?
  let destructionPercentage: Double?
  let opponent: Opponent?
  var widget: LegendsWidgetBattle {
    LegendsWidgetBattle(trophies: trophies, battleTime: time, opponentName: nil, opponentTownHallLevel: opponent?.townHallLevel, stars: stars, destructionPercentage: destructionPercentage)
  }
}

private struct RankedFreshBattlelog: Decodable {
  let tag: String
  let seasonId: String
  let leagueGroupId: String
  let maxBattles: Int
  let registeredAttacks: Int
  let registeredDefenses: Int
  let attacks: [RankedAnalyticsBattle]
  let defenses: [RankedAnalyticsBattle]
}

private struct RankedFreshHistory: Decodable {
  struct Entry: Decodable { let leagueTierId: Int; let maxBattles: Int }
  let items: [Entry]
}

private struct LegendsWidgetFreshFetcher {
  func fetch(player: LegendsWidgetPlayerEntity, cached: LegendsWidgetData, now: Date) async -> LegendsWidgetData? {
    let normalized = LegendsWidgetPlayerQuery.normalizedTag(player.id)
    let stillBookmarked = LegendsWidgetPlayerQuery().allEntities()
      .contains { LegendsWidgetPlayerQuery.normalizedTag($0.id) == normalized }
    guard
      stillBookmarked,
      let defaults = UserDefaults(suiteName: appGroupIdentifier),
      let baseURL = apiBaseURL(defaults: defaults)
    else { return nil }

    // Weekly Ranked data has its own group, counts and positive defense points.
    // Never send it through the daily Legend request/merge path.
    if cached.mode == "ranked" {
      guard let refreshed = await fetchRanked(player: player, cached: cached, defaults: defaults, baseURL: baseURL, now: now) else { return nil }
      cache(refreshed, player: player, defaults: defaults)
      return refreshed
    }

    let day = LegendsDayWindow.current(at: now)
    async let battlelogRequest = fetchBattlelog(player: player, day: day, baseURL: baseURL)
    async let rankRequest = fetchRank(player: player, baseURL: baseURL)
    async let playerRequest = fetchPlayer(player: player, defaults: defaults)
    let (battlelog, rankLookup, profile) = await (battlelogRequest, rankRequest, playerRequest)
    guard battlelog != nil || rankLookup != nil || profile != nil else { return nil }

    let merged = cached.merging(
      battlelog: battlelog,
      rankLookup: rankLookup,
      player: profile,
      day: day,
      refreshedAt: now
    )
    cache(merged, player: player, defaults: defaults)
    return merged
  }

  private func fetchRanked(player: LegendsWidgetPlayerEntity, cached: LegendsWidgetData, defaults: UserDefaults, baseURL: URL, now: Date) async -> LegendsWidgetData? {
    guard let profile = await fetchPlayer(player: player, defaults: defaults),
          let groupTag = profile.currentLeagueGroupTag, !groupTag.isEmpty,
          let season = profile.currentLeagueSeasonId, season > 0,
          let token = await WidgetAuthSessionProvider().validAccessToken(defaults: defaults),
          let groupURL = proxyURL(defaults: defaults, path: "leaguegroup/\(groupTag)/\(season)", query: [URLQueryItem(name: "playerTag", value: player.id)]),
          let historyURL = proxyURL(defaults: defaults, path: "players/\(player.id)/leaguehistory"),
          let logURL = URL(string: "player/\(LegendsWidgetPlayerQuery.normalizedTag(player.id))/ranked/\(season)/battlelog", relativeTo: baseURL)
    else { return nil }
    let start = Date(timeIntervalSince1970: TimeInterval(season))
    let end = start.addingTimeInterval(7 * 86_400)
    guard start <= now, now < end else { return nil }

    async let groupResult: RankedFreshGroup? = authenticatedGet(groupURL, token: token)
    async let logResult: RankedFreshBattlelog? = get(logURL)
    async let historyResult: RankedFreshHistory? = authenticatedGet(historyURL, token: token)
    let (group, candidateLog, history) = await (groupResult, logResult, historyResult)
    let normalized = LegendsWidgetPlayerQuery.normalizedTag(player.id)
    guard let members = group?.members,
          let member = members.first(where: { LegendsWidgetPlayerQuery.normalizedTag($0.playerTag) == normalized })
    else { return nil }
    let attacksUsed = member.attackWinCount + member.attackLoseCount
    let defensesTaken = member.defenseWinCount + member.defenseLoseCount
    guard attacksUsed >= 0, defensesTaken >= 0 else { return nil }
    // Analytics can lag the live roster. Only merge matching identity, period,
    // and registered counts; otherwise use the official scoped logs, or unknown.
    let log = candidateLog.flatMap { log in
      LegendsWidgetPlayerQuery.normalizedTag(log.tag) == normalized && log.seasonId == String(season) &&
      LegendsWidgetPlayerQuery.normalizedTag(log.leagueGroupId) == LegendsWidgetPlayerQuery.normalizedTag(groupTag) &&
      log.registeredAttacks == attacksUsed && log.registeredDefenses == defensesTaken ? log : nil
    }
    let attacks = log?.attacks.map(\.widget) ?? group?.attackLogs?.map(\.widget)
    let defenses = log?.defenses.map(\.widget) ?? group?.defenseLogs?.map(\.widget)
    let attacksComplete = log.map { $0.attacks.filter { $0.automatic != true }.count == attacksUsed }
      ?? (group?.attackLogs.map { $0.count == attacksUsed } ?? false)
    let defensesComplete = log.map { $0.defenses.filter { $0.automatic != true }.count == defensesTaken }
      ?? (group?.defenseLogs.map { $0.count == defensesTaken } ?? false)
    let attackTotal = attacksComplete ? attacks?.reduce(0, { $0 + ($1.trophies ?? 0) }) : nil
    let defenseTotal = defensesComplete ? defenses?.reduce(0, { $0 + ($1.trophies ?? 0) }) : nil
    let tier = profile.leagueTier ?? profile.league
    let samePeriod = cached.dayStartsAt == start
    let sameTier = tier?.name == cached.league?.name
    let historicalLimit = history?.items.first(where: { $0.leagueTierId == tier?.id && $0.maxBattles > 0 })?.maxBattles
    let limit = (log?.maxBattles ?? 0) > 0 ? log?.maxBattles : historicalLimit ?? (samePeriod && sameTier ? cached.attacksLimit : nil)
    let sorted = members.sorted { $0.leagueTrophies > $1.leagueTrophies }
    let rank = sorted.firstIndex(where: { LegendsWidgetPlayerQuery.normalizedTag($0.playerTag) == normalized }).map { $0 + 1 }
    let periodFormatter = DateFormatter()
    periodFormatter.locale = Locale(identifier: cached.locale ?? Locale.current.identifier)
    periodFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    periodFormatter.setLocalizedDateFormatFromTemplate("MMM d")
    let dayFormatter = DateFormatter()
    dayFormatter.locale = Locale(identifier: "en_US_POSIX")
    dayFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dayFormatter.dateFormat = "yyyy-MM-dd"
    let currentLeague = tier.map { tier in
      LegendsWidgetLeague(name: tier.name, iconUrl: sameTier ? cached.league?.iconUrl : tier.iconUrls?.large ?? tier.iconUrls?.small)
    }
    return LegendsWidgetData(
      schemaVersion: cached.schemaVersion,
      mode: "ranked",
      destinationUrl: "clashking://ranked?player=\(normalized)",
      periodLabel: samePeriod ? cached.periodLabel : "\(periodFormatter.string(from: start)) – \(periodFormatter.string(from: end))",
      attacksLimit: limit,
      defensesLimit: limit,
      league: currentLeague,
      locale: cached.locale,
      tag: player.id,
      name: profile.name,
      townHallLevel: profile.townHallLevel,
      townHallImageUrl: profile.townHallImageUrl,
      updatedAt: now,
      legendDay: dayFormatter.string(from: start),
      legendDayIndex: nil,
      dayStartsAt: start,
      dayEndsAt: end,
      trophies: member.leagueTrophies,
      globalRank: rank,
      attackTrophies: attackTotal,
      defenseTrophies: defenseTotal,
      netTrophies: attackTotal.flatMap { attack in defenseTotal.map { attack + $0 } },
      attacksUsed: attacksUsed,
      defensesTaken: defensesTaken,
      latestAttack: attacks?.filter { $0.battleTime != nil }.max { $0.battleTime! < $1.battleTime! },
      latestDefense: defenses?.filter { $0.battleTime != nil }.max { $0.battleTime! < $1.battleTime! },
      clan: profile.widgetClan,
      artwork: cached.artwork,
      labels: cached.labels
    )
  }

  private func proxyURL(defaults: UserDefaults, path: String, query: [URLQueryItem] = []) -> URL? {
    let raw = defaults.string(forKey: "warWidgetProxyUrl") ?? "https://api.clashk.ing/proxy/v1"
    // Match the analytics URL policy: the simulator's owned loopback API uses
    // HTTP. Rejecting it here silently prevented every automatic Ranked refresh.
    // Remote hosts still require HTTPS; do not allow arbitrary plaintext hosts.
    guard var components = URLComponents(string: raw),
          components.scheme == "https" || (components.scheme == "http" && ["localhost", "127.0.0.1", "::1"].contains(components.host ?? "")),
          components.host != nil,
          components.user == nil, components.password == nil, components.query == nil, components.fragment == nil,
          components.path == "/proxy/v1" || components.path == "/proxy/v1/" else { return nil }
    components.path = "/proxy/v1/\(path)"
    components.queryItems = query.isEmpty ? nil : query
    return components.url
  }

  private func authenticatedGet<T: Decodable>(_ url: URL, token: String) async -> T? {
    var request = URLRequest(url: url)
    request.timeoutInterval = 8
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    return await execute(request)
  }

  private func fetchPlayer(
    player: LegendsWidgetPlayerEntity,
    defaults: UserDefaults
  ) async -> LegendsFreshPlayer? {
    let normalized = LegendsWidgetPlayerQuery.normalizedTag(player.id)
    let rawBase = defaults.string(forKey: "warWidgetProxyUrl") ?? "https://api.clashk.ing/proxy/v1"
    guard
      let token = await WidgetAuthSessionProvider().validAccessToken(defaults: defaults),
      var components = URLComponents(string: rawBase),
      components.scheme == "https" || (components.scheme == "http" && ["localhost", "127.0.0.1", "::1"].contains(components.host ?? "")),
      components.user == nil,
      components.password == nil,
      components.query == nil,
      components.fragment == nil,
      components.path == "/proxy/v1" || components.path == "/proxy/v1/"
    else { return nil }
    // Clash player endpoints require a # prefixed tag; URLComponents encodes it as %23.
    components.path = "/proxy/v1/players/#\(normalized)"
    guard let url = components.url else { return nil }
    var request = URLRequest(url: url)
    request.timeoutInterval = 8
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    guard let profile: LegendsFreshPlayer = await execute(request),
          LegendsWidgetPlayerQuery.normalizedTag(profile.tag) == normalized,
          !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          profile.townHallLevel > 0 else { return nil }
    return profile
  }

  private func fetchBattlelog(
    player: LegendsWidgetPlayerEntity,
    day: LegendsDayWindow,
    baseURL: URL
  ) async -> LegendsFreshBattlelog? {
    let normalized = LegendsWidgetPlayerQuery.normalizedTag(player.id)
    guard
      let encoded = normalized.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
      let url = URL(string: "player/\(encoded)/legend/\(day.day)/battlelog", relativeTo: baseURL)
    else { return nil }
    guard let decoded: LegendsFreshBattlelog = await get(url) else { return nil }
    guard
      LegendsWidgetPlayerQuery.normalizedTag(decoded.tag) == normalized,
      decoded.day == day.day
    else { return nil }
    return decoded
  }

  private func fetchRank(
    player: LegendsWidgetPlayerEntity,
    baseURL: URL
  ) async -> LegendsFreshRankLookup? {
    let normalized = LegendsWidgetPlayerQuery.normalizedTag(player.id)
    guard let url = URL(string: "legends/ranks", relativeTo: baseURL) else { return nil }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 8
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: ["tags": ["#\(normalized)"]])
    guard let response: LegendsFreshRankResponse = await execute(request) else { return nil }
    let matching = response.items.first {
      LegendsWidgetPlayerQuery.normalizedTag($0.tag) == normalized
    }
    guard matching != nil || response.items.isEmpty else { return nil }
    return LegendsFreshRankLookup(item: matching)
  }

  private func get<T: Decodable>(_ url: URL) async -> T? {
    var request = URLRequest(url: url)
    request.timeoutInterval = 8
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    return await execute(request)
  }

  private func execute<T: Decodable>(_ request: URLRequest) async -> T? {
    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let response = response as? HTTPURLResponse, response.statusCode == 200 else { return nil }
      return try LegendsWidgetData.makeDecoder().decode(T.self, from: data)
    } catch {
      return nil
    }
  }

  private func apiBaseURL(defaults: UserDefaults) -> URL? {
    guard
      let raw = defaults.string(forKey: "warWidgetApiV2Url")?.trimmingCharacters(in: .whitespacesAndNewlines),
      !raw.isEmpty,
      var components = URLComponents(string: raw),
      let host = components.host,
      components.user == nil,
      components.password == nil,
      components.query == nil,
      components.fragment == nil,
      components.scheme == "https" || (components.scheme == "http" && ["localhost", "127.0.0.1", "::1"].contains(host)),
      components.path == "/v2" || components.path == "/v2/"
    else { return nil }
    components.path = "/v2/"
    return components.url
  }

  private func cache(
    _ data: LegendsWidgetData,
    player: LegendsWidgetPlayerEntity,
    defaults: UserDefaults
  ) {
    let tag = LegendsWidgetPlayerQuery.normalizedTag(player.id)
    let stillBookmarked = LegendsWidgetPlayerQuery().allEntities()
      .contains { LegendsWidgetPlayerQuery.normalizedTag($0.id) == tag }
    guard stillBookmarked else { return }
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    guard
      let encoded = try? encoder.encode(data),
      let raw = String(data: encoded, encoding: .utf8)
    else { return }
    defaults.set(raw, forKey: "legendsWidget_\(tag)")
  }
}

private struct LegendsWidgetEntry: TimelineEntry {
  let date: Date
  let data: LegendsWidgetData
  let images: [String: Data]
  let selectedPlayerTag: String?
}

private struct LegendsTimelineProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> LegendsWidgetEntry {
    LegendsWidgetEntry(date: Date(), data: .placeholder, images: [:], selectedPlayerTag: nil)
  }

  func snapshot(for configuration: SelectLegendsPlayerIntent, in context: Context) async -> LegendsWidgetEntry {
    let data = context.isPreview
      ? LegendsWidgetData.placeholder
      : (LegendsWidgetData.current(player: configuration.player) ?? .empty(player: configuration.player))
    return LegendsWidgetEntry(
      date: Date(),
      data: data,
      images: await images(for: data),
      selectedPlayerTag: configuration.player?.id
    )
  }

  func timeline(for configuration: SelectLegendsPlayerIntent, in context: Context) async -> Timeline<LegendsWidgetEntry> {
    let now = Date()
    let cached = LegendsWidgetData.current(player: configuration.player) ?? .empty(player: configuration.player)
    let data: LegendsWidgetData
    if let player = configuration.player {
      data = await LegendsWidgetFreshFetcher().fetch(player: player, cached: cached, now: now) ?? cached
    } else {
      data = cached
    }
    let entry = LegendsWidgetEntry(
      date: now,
      data: data,
      images: await images(for: data),
      selectedPlayerTag: configuration.player?.id
    )
    let nextRefresh = now.addingTimeInterval(15 * 60)
    var entries = [entry]
    // Advance compact relative times without another network request.
    let minuteDates = (1...60).map { now.addingTimeInterval(Double($0 * 60)) }
    let staleDates = ([data.updatedAt.addingTimeInterval(60 * 60), data.dayEndsAt]
      .compactMap { $0 }
      + minuteDates)
      .filter { $0 > now }
      .sorted()
    for staleDate in staleDates {
      guard entries.last?.date != staleDate else { continue }
      entries.append(
        LegendsWidgetEntry(
          date: staleDate,
          data: data,
          images: entry.images,
          selectedPlayerTag: configuration.player?.id
        )
      )
    }
    return Timeline(entries: entries, policy: .after(nextRefresh))
  }

  private func images(for data: LegendsWidgetData) async -> [String: Data] {
    let urls = [
      data.townHallImageUrl,
      data.clan?.badgeUrl,
      data.league?.iconUrl,
      data.artwork?.attackIconUrl,
      data.artwork?.defenseIconUrl,
      data.artwork?.trophyIconUrl,
      data.artwork?.starFilledIconUrl,
      data.artwork?.starEmptyIconUrl,
    ].compactMap { $0 }
    return await withTaskGroup(of: (String, Data)?.self) { group in
      for value in Set(urls) where !value.isEmpty {
        guard let url = URL(string: value), url.scheme == "https" else { continue }
        group.addTask {
          let request = URLRequest(
            url: widgetBadgeURL(url) ?? url,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 8
          )
          guard
            let (bytes, response) = try? await URLSession.shared.data(for: request),
            (response as? HTTPURLResponse)?.statusCode == 200,
            UIImage(data: bytes) != nil
          else { return nil }
          return (value, bytes)
        }
      }
      var result: [String: Data] = [:]
      for await image in group {
        if let (url, bytes) = image { result[url] = bytes }
      }
      return result
    }
  }
}

private struct LegendsWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: LegendsWidgetEntry

  private var labels: LegendsWidgetLabels { entry.data.localizedLabels }
  private var stale: Bool {
    let refreshExpired = entry.date.timeIntervalSince(entry.data.updatedAt) >= 60 * 60
    let dayExpired = entry.data.dayEndsAt.map { entry.date >= $0 } ?? false
    return refreshExpired || dayExpired
  }

  var body: some View {
    Group {
      if entry.data.hasData {
        if family == .systemMedium {
          mediumBody
        } else {
          smallBody
        }
      } else {
        emptyBody
      }
    }
    .widgetBackground
    .widgetURL(entry.data.destinationUrl.flatMap(URL.init(string:)) ?? legendsWidgetDestination(tag: entry.selectedPlayerTag))
  }

  private var smallBody: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 4) {
        identityArtwork(size: 22)
        Text(entry.data.name)
          .font(.system(size: 12, weight: .bold))
          .lineLimit(1).minimumScaleFactor(0.8)
          .frame(maxWidth: .infinity, alignment: .leading)
        if entry.data.mode != "ranked" {
          // Keep the Legend day visible without bringing back the crowded
          // clan/date row. Ranked periods use different, weekly semantics.
          Text(dayLabel)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
        }
      }
      HStack(spacing: 6) {
        gameArtwork(entry.data.artwork?.trophyIconUrl, size: 20, fallback: "🏆")
        trophyValue(compact: true)
          .fixedSize(horizontal: true, vertical: false)
      }
      // Small cards have one clear focal point; rank belongs to medium only.
      .frame(maxWidth: .infinity, alignment: .center)
      .font(.system(size: 10, weight: .medium))
      .foregroundStyle(.primary)
      .lineLimit(1).minimumScaleFactor(0.85)
      dailyMetrics(compact: true)
    }
  }

  private var mediumBody: some View {
    VStack(alignment: .leading, spacing: 12) {
      identityHeader(compact: false)
      HStack(alignment: .center, spacing: 12) {
        VStack(spacing: 8) {
          dailyMetrics(compact: false)
          HStack(spacing: 8) {
            Text(dayLabel).foregroundStyle(.primary)
            rankLabel
          }
          .font(.system(size: 11, weight: .medium))
          .lineLimit(1).minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 74)
        recentBattleSlot(compact: false)
          .frame(maxWidth: .infinity)
      }
    }
  }

  private var rankLabel: some View {
    HStack(spacing: 3) {
      Text(String(localized: "legends_widget_rank", table: "LegendsWidget"))
      Text(rank(entry.data.globalRank)).monospacedDigit()
    }
    .lineLimit(1)
    .accessibilityLabel("\(labels.globalRank) \(rank(entry.data.globalRank))")
  }

  private func trophyValue(compact: Bool) -> some View {
    // The header is the current total. Daily/weekly gains belong below their
    // respective attack and defense counters, never in place of the total.
    Text(entry.data.trophies.map { $0.formatted() } ?? "—")
      .font(.system(size: compact ? 24 : 32, weight: .bold, design: .rounded).monospacedDigit())
      .foregroundStyle(.secondary)
      .lineLimit(1).minimumScaleFactor(compact ? 0.65 : 0.85)
      .allowsTightening(true)
      // Keep the whole number readable; small cards now reserve a centered row.
      .fixedSize(horizontal: !compact, vertical: false)
  }

  private func dailyMetrics(compact: Bool) -> some View {
    HStack(spacing: 8) {
      compactCountMetric(artworkURL: entry.data.artwork?.attackIconUrl,
        bundledAsset: "Icon_HV_Sword",
        value: battleCount(entry.data.attacksUsed, limit: entry.data.attacksLimit), label: labels.attacks, symbol: "arrow.up.right",
        total: counterChange(entry.data.attackTrophies, defense: false), totalColor: changeColor(entry.data.attackTrophies))
      compactCountMetric(artworkURL: entry.data.artwork?.defenseIconUrl,
        bundledAsset: "Icon_HV_Shield_Arrow",
        value: battleCount(entry.data.defensesTaken, limit: entry.data.defensesLimit), label: labels.defenses, symbol: "shield.fill",
        total: counterChange(entry.data.defenseTrophies, defense: true), totalColor: changeColor(entry.data.defenseTrophies))
    }
  }

  private var showsRecentBattleSlot: Bool { stale || latestBattle != nil }

  private func recentBattleSlot(compact: Bool) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      if stale {
        staleLabel
      } else {
        Text(String(localized: "legends_widget_recent", table: "LegendsWidget") + ":")
          .font(.system(size: 10, weight: .medium)).foregroundStyle(.primary)
        if let attack = entry.data.latestAttack {
          battleRow(attack, attack: true, compact: true)
        }
        if let defense = entry.data.latestDefense {
          battleRow(defense, attack: false, compact: true)
        }
        if entry.data.latestAttack == nil && entry.data.latestDefense == nil {
          Text(String(localized: entry.data.attacksUsed == 0 && entry.data.defensesTaken == 0
            ? "legends_widget_no_activity" : "legends_widget_history_unavailable", table: "LegendsWidget"))
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(3)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(height: compact ? 42 : 74, alignment: .center)
    .padding(compact ? 6 : 8)
    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
  }

  private var latestBattle: (battle: LegendsWidgetBattle, attack: Bool)? {
    switch (entry.data.latestAttack, entry.data.latestDefense) {
    case let (attack?, defense?):
      switch (attack.battleTime, defense.battleTime) {
      case let (attackTime?, defenseTime?):
        return attackTime >= defenseTime ? (attack, true) : (defense, false)
      case (_?, nil):
        return (attack, true)
      case (nil, _?):
        return (defense, false)
      case (nil, nil):
        return (attack, true)
      }
    case let (attack?, nil):
      return (attack, true)
    case let (nil, defense?):
      return (defense, false)
    case (nil, nil):
      return nil
    }
  }

  private var emptyBody: some View {
    VStack(spacing: 8) {
      identityArtwork(size: 46)
      Text(entry.data.name)
        .font(.headline)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
      secondaryIdentity(compact: true)
      Text(labels.noData)
        .font(.caption)
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func identityHeader(compact: Bool) -> some View {
    HStack(alignment: .top, spacing: compact ? 4 : 8) {
      identityArtwork(size: compact ? 20 : 34)
      VStack(alignment: .leading, spacing: 1) {
        Text(entry.data.name)
          .font(.system(size: compact ? 13 : 18, weight: .bold))
          .lineLimit(1)
          .minimumScaleFactor(0.8)
        secondaryIdentity(compact: compact)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      HStack(spacing: 4) {
        gameArtwork(entry.data.artwork?.trophyIconUrl, size: compact ? 17 : 22, fallback: "🏆")
        trophyValue(compact: compact)
      }
    }
  }

  private func identityArtwork(size: CGFloat) -> some View {
    Group {
      if let url = entry.data.townHallImageUrl,
         let data = entry.images[url],
         let image = UIImage(data: data) {
        Image(uiImage: image).resizable().widgetArtwork.scaledToFit()
      } else if (1...18).contains(entry.data.townHallLevel) {
        Image("town_hall_\(entry.data.townHallLevel)", bundle: .main)
          .resizable().widgetArtwork.scaledToFit()
      } else {
        Text(entry.data.townHallLevel > 0 ? "TH\(entry.data.townHallLevel)" : "TH")
          .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
          .foregroundStyle(.purple)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(.purple.opacity(0.14), in: RoundedRectangle(cornerRadius: size * 0.28))
      }
    }
    .frame(width: size, height: size)
    .accessibilityLabel("Town Hall \(entry.data.townHallLevel)")
  }

  @ViewBuilder
  private func secondaryIdentity(compact: Bool) -> some View {
    if entry.data.mode == "ranked" {
      // Older cached payloads have no league yet. Omit the row until refresh;
      // showing the clan here would mislabel the requested Ranked context.
      if let league = entry.data.league {
        HStack(spacing: 3) {
          gameArtwork(league.iconUrl, size: 14, fallback: "")
          Text(league.name)
            .font(.system(size: compact ? 10 : 11, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    } else if let clan = entry.data.clan, clan.name != nil || clan.badgeUrl != nil {
      clanIdentity(clan, compact: compact)
    }
  }

  private func clanIdentity(_ clan: LegendsWidgetClan, compact: Bool) -> some View {
    HStack(spacing: 3) {
      if let url = clan.badgeUrl,
         let data = entry.images[url],
         let image = UIImage(data: data) {
        Image(uiImage: image).resizable().widgetArtwork.scaledToFit().frame(width: 12, height: 14)
      } else {
        Text(String((clan.name ?? "?").prefix(1)))
          .font(.caption.weight(.bold))
          .foregroundStyle(.purple)
          .frame(width: 12, height: 14)
          .background(.purple.opacity(0.14), in: Circle())
      }
      if let name = clan.name, !name.isEmpty {
        Text(name)
          .font(.system(size: compact ? 10 : 11, weight: .medium))
          .foregroundStyle(.primary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func compactCountMetric(artworkURL: String?, bundledAsset: String, value: String, label: String, symbol: String, total: String? = nil, totalColor: Color = .secondary) -> some View {
    VStack(spacing: 3) {
      HStack(spacing: 4) {
        gameArtwork(artworkURL, size: 18, fallback: "", symbol: symbol, bundledAsset: bundledAsset)
        Text(value)
          .font(.system(size: 15, weight: .bold, design: .rounded))
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.65)
          .allowsTightening(true)
          .layoutPriority(1)
      }
      if let total {
        Text(total)
          .font(.system(size: 11, weight: .medium).monospacedDigit())
          .foregroundStyle(totalColor)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .center)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label)
    .accessibilityValue(total.map { "\(value), \($0)" } ?? value)
  }

  private func labeledMetric(value: String, label: String, artworkURL: String?) -> some View {
    VStack(alignment: .leading, spacing: 1) {
      HStack(spacing: 4) {
        gameArtwork(artworkURL, size: 15, fallback: String(label.prefix(1)))
        Text(value).font(.callout.weight(.bold)).monospacedDigit().lineLimit(1)
      }
      Text(label).font(.caption).foregroundStyle(.primary).lineLimit(1)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label)
    .accessibilityValue(value)
  }

  private func battleRow(_ battle: LegendsWidgetBattle, attack: Bool, compact: Bool) -> some View {
    VStack(alignment: .leading, spacing: compact ? 2 : 5) {
      HStack(spacing: 3) {
        Text(opponentName(battle))
          .font(.system(size: compact ? 11 : 13, weight: .semibold))
          .lineLimit(1)
          .frame(maxWidth: .infinity, alignment: .leading)
        gameArtwork(
          attack ? entry.data.artwork?.attackIconUrl : entry.data.artwork?.defenseIconUrl,
          size: compact ? 12 : 16,
          fallback: "",
          symbol: attack ? "arrow.up.right" : "shield.fill",
          bundledAsset: attack ? "Icon_HV_Sword" : "Icon_HV_Shield_Arrow"
        )
        Text(signed(battle.trophies))
          .font(.system(size: compact ? 11 : 13, weight: .semibold).monospacedDigit())
          .fixedSize()
      }
      HStack(spacing: 3) {
        battleDetails(battle, compact: compact)
          .fixedSize(horizontal: true, vertical: false)
          .layoutPriority(1)
        Spacer(minLength: 0)
        if let time = battle.battleTime {
          Text(relativeTime(time))
            .font(.system(size: compact ? 10 : 11, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var staleLabel: some View {
    Text(labels.staleData)
      .font(.caption.weight(.semibold))
      .foregroundStyle(.orange)
      .lineLimit(1)
  }

  private var dayLabel: String {
    if let period = entry.data.periodLabel, !period.isEmpty { return period }
    if let index = entry.data.legendDayIndex, index > 0 {
      if let formatted = labels.dayFormatted, !formatted.isEmpty {
        return formatted
      }
      return "\(labels.day ?? "Day") \(index)"
    }
    guard let day = entry.data.legendDay else { return labels.title }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    guard let date = formatter.date(from: day) else { return day }
    // legendDay is a calendar label, not an instant. Local-time formatting of
    // midnight UTC turns Oct 22 into Oct 21 west of UTC, despite fresh data.
    formatter.locale = .current
    formatter.setLocalizedDateFormatFromTemplate("MMMd")
    return formatter.string(from: date)
  }

  private func gameArtwork(_ url: String?, size: CGFloat, fallback: String, symbol: String? = nil, bundledAsset: String? = nil) -> some View {
    Group {
      // Static battle icons must also work for native-only refreshes with no app payload.
      if let bundledAsset, let image = UIImage(named: bundledAsset) {
        Image(uiImage: image).renderingMode(.original).resizable().widgetArtwork.scaledToFit()
      } else if let url,
         let data = entry.images[url],
         let image = UIImage(data: data) {
        Image(uiImage: image).resizable().widgetArtwork.scaledToFit()
      } else if let symbol {
        Image(systemName: symbol)
          .resizable().scaledToFit().foregroundStyle(.primary)
      } else {
        Text(fallback)
          .font(.system(size: max(12, size * 0.62), weight: .bold, design: .rounded))
          .foregroundStyle(.primary)
      }
    }
    .frame(width: size, height: size)
  }

  private func opponentName(_ battle: LegendsWidgetBattle) -> String {
    guard let name = battle.opponentName, !name.isEmpty else { return "—" }
    return name
  }

  private func battleDetails(_ battle: LegendsWidgetBattle, compact: Bool) -> some View {
    HStack(spacing: 4) {
      if let stars = battle.stars {
        HStack(spacing: 1) {
          ForEach(0..<3, id: \.self) { index in
            let earned = index < stars
            gameArtwork(
              earned ? entry.data.artwork?.starFilledIconUrl : entry.data.artwork?.starEmptyIconUrl,
              size: 9,
              fallback: earned ? "★" : "☆"
            )
          }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stars) / 3")
      }
      if let destruction = battle.destructionPercentage {
        Text("\(destruction.formatted(.number.precision(.fractionLength(0...1))))%")
      }
    }
    .font(.system(size: 10, weight: .medium))
    .foregroundStyle(.primary)
    .lineLimit(1)
  }

  private func optionalNumber(_ value: Int?) -> String { value.map(String.init) ?? "—" }
  private func relativeTime(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    let elapsed = max(60, entry.date.timeIntervalSince(date))
    let components: DateComponents
    if elapsed >= 86400 { components = DateComponents(day: -Int(elapsed / 86400)) }
    else if elapsed >= 3600 { components = DateComponents(hour: -Int(elapsed / 3600)) }
    else { components = DateComponents(minute: -Int(elapsed / 60)) }
    return formatter.localizedString(from: components)
  }
  private func battleCount(_ value: Int?, limit: Int?) -> String {
    guard let value else { return "—" }
    let effectiveLimit = limit ?? (entry.data.mode == "ranked" ? nil : 8)
    return effectiveLimit.map { "\(value)/\($0)" } ?? "\(value)/—"
  }
  private func rank(_ value: Int?) -> String { value.map { "#\($0.formatted())" } ?? "—" }
  private func counterChange(_ value: Int?, defense: Bool) -> String {
    guard let value else { return "—" }
    // Explicit signs identify the two subtotals even before the first battle.
    // Ranked defenses can earn points: preserve their real sign, including +0.
    if value == 0 { return defense && entry.data.mode != "ranked" ? "−0" : "+0" }
    return signed(value)
  }
  private func signed(_ value: Int?) -> String {
    guard let value else { return "—" }
    return value > 0 ? "+\(value.formatted())" : value.formatted()
  }
  private func changeColor(_ value: Int?) -> Color {
    guard let value else { return .primary }
    if value > 0 { return widgetPositiveColor }
    if value < 0 { return .red }
    return .primary
  }
}

private struct LegendsWidget: Widget {
  let kind = "LegendsWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: SelectLegendsPlayerIntent.self,
      provider: LegendsTimelineProvider()
    ) { entry in
      LegendsWidgetView(entry: entry)
    }
    .configurationDisplayName(LocalizedStringResource("legends_widget_label", table: "LegendsWidget"))
    .description(LocalizedStringResource("legends_widget_configure_description", table: "LegendsWidget"))
    .supportedFamilies([.systemSmall, .systemMedium])
    .containerBackgroundRemovable(true)
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

  @Parameter(title: "Show Builder Base", default: true)
  var showBuilderBase: Bool
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

private struct OngoingWidgetQueue: Codable, Identifiable {
  let id: String
  let title: String
  let imageUrl: String
  let capacity: Int
  let finishesAt: [Date]
  let extra: Int
  let nextTask: UpgradeWidgetTask?
}

private struct OngoingWidgetSummary: Codable {
  let queues: [OngoingWidgetQueue]
  let boosts: [UpgradeWidgetBoost]
  var builderBase: OngoingWidgetQueue? = nil
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
  var ongoingTitle: String? = nil
  var builderBaseTitle: String? = nil
  var freeSlots: String? = nil
  var freeIn: String? = nil
  var notBuilt: String? = nil
  var toLevel: String? = nil

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
  let completion: Double?
  let boosts: [UpgradeWidgetBoost]
  let helpers: [UpgradeWidgetHelper]
  let labels: UpgradeWidgetLabels?
  let homeBuilders: UpgradeWidgetSectionData
  let laboratory: UpgradeWidgetSectionData
  let pets: UpgradeWidgetSectionData
  let builderBase: UpgradeWidgetSectionData
  var ongoing: OngoingWidgetSummary? = nil

  static let placeholder = UpgradeWidgetData(
    tag: "#PLAYER",
    name: "Chief",
    townHallLevel: 18,
    builderHallLevel: 10,
    hallImageUrl: "https://assets.clashk.ing/buildings/home-village/town_hall/level_18.webp",
    updatedAt: Date(),
    hasStaleData: false,
    completion: 0.72,
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
    completion: nil,
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
  let showBuilderBase: Bool
  var selectedAccountTag: String? = nil
}

private struct UpgradeTimelineProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> UpgradeWidgetEntry {
    UpgradeWidgetEntry(
      date: Date(),
      data: .placeholder,
      images: [:],
      mediumTaskIndex: 0,
      showBuilderBase: true
    )
  }

  func snapshot(for configuration: SelectUpgradeAccountIntent, in context: Context) async -> UpgradeWidgetEntry {
    let data: UpgradeWidgetData = context.isPreview
      ? .placeholder
      : (.current(accountTag: configuration.account?.id) ?? .empty)
    return UpgradeWidgetEntry(
      date: Date(),
      data: data,
      images: await images(for: data, showBuilderBase: configuration.showBuilderBase),
      mediumTaskIndex: 0,
      showBuilderBase: configuration.showBuilderBase,
      selectedAccountTag: configuration.account?.id
    )
  }

  func timeline(for configuration: SelectUpgradeAccountIntent, in context: Context) async -> Timeline<UpgradeWidgetEntry> {
    let data = UpgradeWidgetData.current(accountTag: configuration.account?.id) ?? .empty
    let now = Date()
    let showBuilderBase = configuration.showBuilderBase
    let imageData = await images(for: data, showBuilderBase: showBuilderBase)
    let baseEntry = UpgradeWidgetEntry(
      date: now,
      data: data,
      images: imageData,
      mediumTaskIndex: 0,
      showBuilderBase: showBuilderBase,
      selectedAccountTag: configuration.account?.id
    )
    let next = data.timelineDates(showBuilderBase: showBuilderBase)
      .filter { $0 > now }
      .min() ?? now.addingTimeInterval(3600)
    // The medium summary shows all queues together instead of rotating jobs.
    return Timeline(entries: [baseEntry], policy: .after(next))
  }

  private func images(for data: UpgradeWidgetData, showBuilderBase: Bool) async -> [String: Data] {
    var result: [String: Data] = [:]
    let summaryQueues = (data.ongoing?.queues ?? []) + (showBuilderBase ? [data.ongoing?.builderBase].compactMap { $0 } : [])
    let summaryImages = summaryQueues.flatMap { [$0.imageUrl, $0.nextTask?.imageUrl].compactMap { $0 } } + (data.ongoing?.boosts ?? []).compactMap(\.imageUrl)
    let urls = [data.hallImageUrl] + data.allTasks(showBuilderBase: showBuilderBase).map(\.imageUrl) + data.helpers.map(\.imageUrl) + data.boosts.compactMap(\.imageUrl) + summaryImages
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

  func allTasks(showBuilderBase: Bool) -> [UpgradeWidgetTask] {
    homeBuilders.tasks + laboratory.tasks + pets.tasks + (showBuilderBase ? builderBase.tasks : [])
  }

  func allSections(showBuilderBase: Bool) -> [UpgradeWidgetSectionData] {
    [homeBuilders, laboratory, pets] + (showBuilderBase ? [builderBase] : [])
  }

  func activeBoosts(at date: Date) -> [UpgradeWidgetBoost] {
    boosts.filter { boost in
      guard let expiresAt = boost.expiresAt else { return true }
      return expiresAt > date
    }
  }

  func mediumTaskChoices(showBuilderBase: Bool) -> [UpgradeWidgetTaskChoice] {
    let labels = localizedLabels
    let groups: [(String, [UpgradeWidgetTask])] = [
      (labels.village, homeBuilders.tasks),
      (labels.laboratory, laboratory.tasks),
      (labels.pets, pets.tasks),
    ] + (showBuilderBase ? [(labels.builderBase, builderBase.tasks)] : [])
    return groups.flatMap { title, tasks in
      tasks.map { UpgradeWidgetTaskChoice(title: title, task: $0) }
    }
  }

  func timelineDates(showBuilderBase: Bool) -> [Date] {
    let taskDates = allTasks(showBuilderBase: showBuilderBase).flatMap { task in
      [task.finishesAt, task.helperFinishesAt].compactMap { $0 }
    }
    let summaryDates = (ongoing?.queues ?? []).flatMap(\.finishesAt) + (showBuilderBase ? ongoing?.builderBase?.finishesAt ?? [] : []) + (ongoing?.boosts ?? []).compactMap(\.expiresAt)
    return taskDates + activeBoosts(at: Date()).compactMap(\.expiresAt) + helpers.compactMap(\.statusUntil) + summaryDates
  }

  func hasFinishedTask(now: Date, showBuilderBase: Bool) -> Bool {
    (hasStaleData ?? false) ||
      allSections(showBuilderBase: showBuilderBase).contains { ($0.hiddenFinishesAt ?? .distantFuture) <= now } ||
      allTasks(showBuilderBase: showBuilderBase).contains { $0.finishesAt <= now }
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
    .widgetBackground
    .widgetURL(widgetDestination(tag: entry.selectedAccountTag, upgrade: true))
  }

  private var largeBody: some View {
    let activeBoosts = entry.data.activeBoosts(at: entry.date)
    return VStack(alignment: .leading, spacing: 7) {
      accountHeader
      if entry.data.hasFinishedTask(now: entry.date, showBuilderBase: entry.showBuilderBase) {
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
          if entry.showBuilderBase {
            sectionCard(title: labels.builderBase, section: entry.data.builderBase, columns: 1)
          }
        }
      }
    }
  }

  private var mediumBody: some View {
    Group {
      if let summary = entry.data.ongoing {
        ongoingMediumBody(summary)
      } else {
        legacyMediumBody
      }
    }
  }

  private func ongoingMediumBody(_ summary: OngoingWidgetSummary) -> some View {
    TimelineView(.periodic(from: .now, by: 60)) { context in
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 6) {
          hallImage.frame(width: 28, height: 28)
          Text(entry.data.name).font(.system(size: 14, weight: .semibold)).lineLimit(1)
          if entry.data.hasFinishedTask(now: context.date, showBuilderBase: entry.showBuilderBase) {
            Image(systemName: "arrow.clockwise")
              .font(.system(size: 9))
              .accessibilityLabel(labels.staleData ?? "Update needed")
          }
          Spacer(minLength: 4)
          let boosts = summary.boosts.filter { ($0.expiresAt ?? .distantFuture) > context.date }
          ForEach(Array(boosts.prefix(3))) { boost in
            VStack(spacing: 1) {
              boostImage(boost)
              if let until = boost.expiresAt {
                Text(humanDuration(until: until, now: context.date))
                  .font(.system(size: 8)).monospacedDigit().lineLimit(1)
              }
            }
            .accessibilityLabel(boost.label)
          }
          if boosts.count > 3 { Text("+\(boosts.count - 3)").font(.system(size: 9)) }
          completionRing
        }
        HStack(alignment: .top, spacing: 12) {
          ForEach(summary.queues) { queue in
            ongoingQueueColumn(queue, now: context.date)
          }
        }
      }
    }
  }

  private func ongoingQueueColumn(_ queue: OngoingWidgetQueue, now: Date) -> some View {
    let future = queue.finishesAt.filter { $0 > now }
    return VStack(alignment: .leading, spacing: 3) {
      HStack(spacing: 4) {
        if let bytes = entry.images[queue.imageUrl], let image = UIImage(data: bytes) {
          Image(uiImage: image).resizable().widgetArtwork.scaledToFit().frame(width: 19, height: 19)
        }
        Text(queue.title).font(.system(size: 10, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
      }
      HStack(alignment: .firstTextBaseline, spacing: 3) {
        Text("\(future.count)/\(queue.capacity)")
          .font(.system(size: 17, weight: .semibold)).monospacedDigit()
        if queue.extra > 0 { Text("+\(queue.extra)").font(.system(size: 8)).accessibilityLabel("\(queue.extra)") }
      }
      Text(availability(queue, now: now))
        .font(.system(size: 9)).lineLimit(1).minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func availability(_ queue: OngoingWidgetQueue, now: Date) -> String {
    let future = queue.finishesAt.filter { $0 > now }
    let free = max(0, queue.capacity - future.count)
    if queue.capacity == 0 { return labels.notBuilt ?? "Not built" }
    if free > 0 { return (labels.freeSlots ?? "{count} free").replacingOccurrences(of: "{count}", with: "\(free)") }
    return (labels.freeIn ?? "Free in {duration}").replacingOccurrences(of: "{duration}", with: humanDuration(until: future.min() ?? now, now: now))
  }

  private var legacyMediumBody: some View {
    VStack(alignment: .leading, spacing: 6) {
      accountHeader
      if entry.data.hasFinishedTask(now: entry.date, showBuilderBase: entry.showBuilderBase) {
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
    let choices = entry.data.mediumTaskChoices(showBuilderBase: entry.showBuilderBase)
    guard !choices.isEmpty else { return nil }
    return choices[entry.mediumTaskIndex % choices.count]
  }

  private func mediumTaskCard(_ choice: UpgradeWidgetTaskChoice) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(choice.title)
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.primary)
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
      completionRing
    }
  }

  private var staleChip: some View {
    Text(labels.staleData ?? "Update needed")
      .font(.system(size: 8.5, weight: .bold))
      .foregroundStyle(.primary)
      .lineLimit(1)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(.orange.opacity(0.16), in: Capsule())
  }

  private var completionRing: some View {
    let progress = min(1, max(0, entry.data.completion ?? 0))
    let percent = Int((progress * 100).rounded())
    return ZStack {
      Circle().stroke(.primary.opacity(0.16), lineWidth: 4)
      Circle().trim(from: 0, to: progress)
        .stroke(widgetPositiveColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .widgetAccentable()
      Text(entry.data.completion == nil ? "—" : "\(percent)%")
        .font(.system(size: 10, weight: .bold)).monospacedDigit()
        .foregroundStyle(.primary)
    }
    .frame(width: 38, height: 38)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.data.completion == nil ? "—" : "\(percent)%")
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
                  .foregroundStyle(.primary)
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
              .foregroundStyle(.primary)
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
            .foregroundStyle(.primary)
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
      .foregroundStyle(.primary)
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
        .foregroundStyle(.primary)
      if let task = section.tasks.first {
        taskRow(task)
      } else {
        Text(emptySectionLabel(section))
          .font(.system(size: 8, weight: .medium))
          .foregroundStyle(.primary)
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
        .foregroundStyle(.primary)
      let builderTask = entry.showBuilderBase ? entry.data.builderBase.tasks.first : nil
      if let task = entry.data.laboratory.tasks.first ?? entry.data.pets.tasks.first ?? builderTask {
        taskRow(task)
      } else {
        Text(labels.noActiveResearch)
          .font(.system(size: 8, weight: .medium))
          .foregroundStyle(.primary)
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
        Image(uiImage: image).resizable().widgetArtwork.scaledToFit()
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
        Image(uiImage: image).resizable().widgetArtwork.scaledToFit()
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
          .foregroundStyle(.primary)
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
          .foregroundStyle(.primary)
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
          .foregroundStyle(.primary)
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
        Image(uiImage: image).resizable().widgetArtwork.scaledToFit()
      } else {
        RoundedRectangle(cornerRadius: 6).fill(.quaternary)
      }
    }
    .frame(width: 27, height: 27)
  }

  private func helperImage(_ helper: UpgradeWidgetHelper) -> some View {
    Group {
      if let data = entry.images[helper.imageUrl], let image = UIImage(data: data) {
        Image(uiImage: image).resizable().widgetArtwork.scaledToFit()
      } else {
        Image(systemName: "person.crop.circle.badge.clock")
          .foregroundStyle(.primary)
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
    .containerBackgroundRemovable(true)
  }
}

@main
struct ClashKingWidgetBundle: WidgetBundle {
  var body: some Widget {
    WarWidget()
    LegendsWidget()
    UpgradeWidget()
  }
}
