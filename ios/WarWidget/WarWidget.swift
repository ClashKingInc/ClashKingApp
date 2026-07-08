import ActivityKit
import AppIntents
import SwiftUI
import UIKit
import WidgetKit

private let appGroupIdentifier = "group.com.clashking.apps"

struct WarLiveActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var state: String
    var mode: String
    var clanName: String
    var opponentName: String
    var clanStars: Int
    var opponentStars: Int
    var timeState: String
    var clanBadgeUrl: String
    var opponentBadgeUrl: String
    var clanBadgePath: String
    var opponentBadgePath: String
    var latestAttackerName: String
    var latestDefenderName: String
    var attackerTownHallUrl: String
    var defenderTownHallUrl: String
    var attackerTownHallPath: String
    var defenderTownHallPath: String
    var latestAttackStars: Int
    var latestAttackDestruction: String
  }

  var clanTag: String
  var warId: String
}

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

private struct WarWidgetFreshFetcher {
  func fetch(clanTag: String?) async -> WarWidgetData? {
    guard
      let clanTag,
      !clanTag.isEmpty,
      let defaults = UserDefaults(suiteName: appGroupIdentifier)
    else {
      return nil
    }

    let baseUrl = defaults.string(forKey: "warWidgetProxyUrl") ?? "https://proxy.clashk.ing/v1"
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
    if let token = defaults.string(forKey: "warWidgetAuthToken"), !token.isEmpty {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

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

@available(iOSApplicationExtension 16.1, *)
struct WarLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: WarLiveActivityAttributes.self) { context in
      WarLiveActivityLockScreenView(state: context.state)
      .activityBackgroundTint(.black.opacity(0.12))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          WarLiveActivityClanView(
            name: context.state.clanName,
            badgePath: context.state.clanBadgePath,
            trailing: false
          )
        }
        DynamicIslandExpandedRegion(.trailing) {
          WarLiveActivityClanView(
            name: context.state.opponentName,
            badgePath: context.state.opponentBadgePath,
            trailing: true
          )
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(spacing: 2) {
            scoreView(
              clanStars: context.state.clanStars,
              opponentStars: context.state.opponentStars,
              font: .headline
            )
            Text(context.state.timeState)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          WarLiveActivityAttackView(state: context.state, compact: true)
      }
      } compactLeading: {
        HStack(spacing: 2) {
          Text("\(context.state.clanStars)").monospacedDigit()
          Image(systemName: "star.fill").font(.caption2)
        }
      } compactTrailing: {
        HStack(spacing: 2) {
          Image(systemName: "star.fill").font(.caption2)
          Text("\(context.state.opponentStars)").monospacedDigit()
        }
      } minimal: {
        Image(systemName: "star.fill")
      }
    }
  }
}

private struct WarLiveActivityLockScreenView: View {
  let state: WarLiveActivityAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center, spacing: 12) {
        WarLiveActivityClanView(
          name: state.clanName,
          badgePath: state.clanBadgePath,
          trailing: false
        )
        Spacer(minLength: 8)
        VStack(spacing: 2) {
          scoreView(
            clanStars: state.clanStars,
            opponentStars: state.opponentStars,
            font: .title2.weight(.bold)
          )
          Text(state.timeState)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer(minLength: 8)
        WarLiveActivityClanView(
          name: state.opponentName,
          badgePath: state.opponentBadgePath,
          trailing: true
        )
      }

      Divider()
      WarLiveActivityAttackView(state: state, compact: false)
    }
    .padding()
  }
}

private struct WarLiveActivityClanView: View {
  let name: String
  let badgePath: String
  let trailing: Bool

  var body: some View {
    VStack(alignment: trailing ? .trailing : .leading, spacing: 4) {
      badge
      Text(name)
        .font(.caption.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
    }
    .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)
  }

  private var badge: some View {
    Group {
      if let image = UIImage(contentsOfFile: badgePath) {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
      } else {
        Image(systemName: "shield.fill")
          .resizable()
          .scaledToFit()
          .foregroundStyle(.red)
          .padding(8)
      }
    }
    .frame(width: 34, height: 34)
  }
}

private struct WarLiveActivityAttackView: View {
  let state: WarLiveActivityAttributes.ContentState
  let compact: Bool

  var body: some View {
    HStack(spacing: compact ? 6 : 8) {
      townHall(path: state.attackerTownHallPath)
      Text(state.latestAttackerName)
        .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
      Image(systemName: "arrow.right")
        .font(.caption2)
        .foregroundStyle(.secondary)
      townHall(path: state.defenderTownHallPath)
      Text(state.latestDefenderName)
        .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
      Spacer(minLength: 4)
      starRow(count: state.latestAttackStars)
      Text(state.latestAttackDestruction)
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
  }

  private func townHall(path: String) -> some View {
    Group {
      if let image = UIImage(contentsOfFile: path) {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
      } else {
        Image(systemName: "house.fill")
          .resizable()
          .scaledToFit()
          .foregroundStyle(.secondary)
          .padding(4)
      }
    }
    .frame(width: compact ? 18 : 22, height: compact ? 18 : 22)
  }

  private func starRow(count: Int) -> some View {
    HStack(spacing: 1) {
      ForEach(0..<3, id: \.self) { index in
        Image(systemName: index < count ? "star.fill" : "star")
          .font(.caption2)
          .foregroundStyle(index < count ? .yellow : .secondary)
      }
    }
  }
}

private func scoreView(clanStars: Int, opponentStars: Int, font: Font) -> some View {
  HStack(spacing: 5) {
    Image(systemName: "star.fill")
      .font(.caption)
      .foregroundStyle(.yellow)
    Text("\(clanStars) - \(opponentStars)")
      .font(font.monospacedDigit())
    Image(systemName: "star.fill")
      .font(.caption)
      .foregroundStyle(.yellow)
  }
}

@main
struct ClashKingWidgetBundle: WidgetBundle {
  var body: some Widget {
    WarWidget()
    if #available(iOSApplicationExtension 16.1, *) {
      WarLiveActivityWidget()
    }
  }
}
