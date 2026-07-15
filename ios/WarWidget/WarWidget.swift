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
  var id: String { "\(name)-\(finishesAt.timeIntervalSince1970)" }
}

private struct UpgradeWidgetTaskChoice: Identifiable {
  let title: String
  let task: UpgradeWidgetTask

  var id: String { "\(title)-\(task.id)" }
}

private struct UpgradeWidgetBoost: Codable, Identifiable {
  let kind: String
  let label: String
  let imageUrl: String?
  let expiresAt: Date?
  var id: String { "\(kind)-\(label)" }
}

private struct UpgradeWidgetHelper: Codable, Identifiable {
  let name: String
  let imageUrl: String
  let status: String
  let statusUntil: Date?
  var id: String { name }
}

private struct UpgradeWidgetSectionData: Codable {
  let available: Bool
  let capacity: Int
  let remainingCount: Int
  let tasks: [UpgradeWidgetTask]
}

private struct UpgradeWidgetData: Codable {
  let tag: String
  let name: String
  let townHallLevel: Int
  let builderHallLevel: Int
  let hallImageUrl: String
  let updatedAt: Date
  let boosts: [UpgradeWidgetBoost]
  let helpers: [UpgradeWidgetHelper]
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
    boosts: [UpgradeWidgetBoost(kind: "builderPotion", label: "Builder Potion", imageUrl: "https://assets.clashk.ing/magic_items/builder_potion.webp", expiresAt: Date().addingTimeInterval(1800))],
    helpers: [UpgradeWidgetHelper(name: "Builder Apprentice", imageUrl: "https://assets.clashk.ing/helpers/builder's_apprentice.webp", status: "Helping Archer Tower", statusUntil: Date().addingTimeInterval(1200))],
    homeBuilders: UpgradeWidgetSectionData(
      available: true,
      capacity: 6,
      remainingCount: 2,
      tasks: [
        UpgradeWidgetTask(name: "Archer Tower", imageUrl: "https://assets.clashk.ing/buildings/home-village/archer_tower/level_18.webp", fromLevel: 17, toLevel: 18, finishesAt: Date().addingTimeInterval(7200), helperName: "Builder Apprentice", helperFinishesAt: Date().addingTimeInterval(1800)),
        UpgradeWidgetTask(name: "Cannon", imageUrl: "https://assets.clashk.ing/buildings/home-village/cannon/level_19.webp", fromLevel: 18, toLevel: 19, finishesAt: Date().addingTimeInterval(14400), helperName: nil, helperFinishesAt: nil),
      ]
    ),
    laboratory: UpgradeWidgetSectionData(
      available: true,
      capacity: 1,
      remainingCount: 1,
      tasks: [UpgradeWidgetTask(name: "Dragon", imageUrl: "https://assets.clashk.ing/troops/dragon/icon.webp", fromLevel: 12, toLevel: 13, finishesAt: Date().addingTimeInterval(21600), helperName: nil, helperFinishesAt: nil)]
    ),
    pets: UpgradeWidgetSectionData(available: true, capacity: 1, remainingCount: 0, tasks: []),
    builderBase: UpgradeWidgetSectionData(available: true, capacity: 2, remainingCount: 1, tasks: [])
  )

  static func current(accountTag: String?) -> UpgradeWidgetData? {
    guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    defaults.synchronize()
    let linkedTags = UpgradeWidgetAccountQuery.linkedTags(defaults: defaults)
    guard !linkedTags.isEmpty else { return nil }
    let selected = accountTag.map(UpgradeWidgetAccountQuery.normalizedTag)
    let candidateTags = [selected, linkedTags.first].compactMap { $0 }
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
      : (.current(accountTag: configuration.account?.id) ?? .placeholder)
    return UpgradeWidgetEntry(
      date: Date(),
      data: data,
      images: await images(for: data),
      mediumTaskIndex: 0
    )
  }

  func timeline(for configuration: SelectUpgradeAccountIntent, in context: Context) async -> Timeline<UpgradeWidgetEntry> {
    let data = UpgradeWidgetData.current(accountTag: configuration.account?.id) ?? .placeholder
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
    return Timeline(entries: entries, policy: .after(next))
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
  var allTasks: [UpgradeWidgetTask] {
    homeBuilders.tasks + laboratory.tasks + pets.tasks + builderBase.tasks
  }

  var mediumTaskChoices: [UpgradeWidgetTaskChoice] {
    let groups: [(String, [UpgradeWidgetTask])] = [
      ("VILLAGE", homeBuilders.tasks),
      ("LAB", laboratory.tasks),
      ("PETS", pets.tasks),
      ("BUILDER BASE", builderBase.tasks),
    ]
    return groups.flatMap { title, tasks in
      tasks.map { UpgradeWidgetTaskChoice(title: title, task: $0) }
    }
  }

  var timelineDates: [Date] {
    let taskDates = allTasks.flatMap { task in
      [task.finishesAt, task.helperFinishesAt].compactMap { $0 }
    }
    return taskDates + boosts.compactMap(\.expiresAt) + helpers.compactMap(\.statusUntil)
  }
}

private struct UpgradeWidgetView: View {
  let entry: UpgradeWidgetEntry
  @Environment(\.widgetFamily) private var family

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
    VStack(alignment: .leading, spacing: 7) {
      accountHeader

      if !entry.data.boosts.isEmpty {
        LazyVGrid(
          columns: [
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible())
          ],
          alignment: .leading,
          spacing: 4
        ) {
          ForEach(Array(entry.data.boosts.prefix(3))) { boost in
            boostPill(boost)
          }
        }
      }

      if !entry.data.helpers.isEmpty {
        helperStrip
      }

      HStack(alignment: .top, spacing: 7) {
        sectionCard(title: "HOME VILLAGE", section: entry.data.homeBuilders, columns: 1)
        VStack(alignment: .leading, spacing: 7) {
          sectionCard(title: "LAB", section: entry.data.laboratory, columns: 1)
          sectionCard(title: "PETS", section: entry.data.pets, columns: 1)
          sectionCard(title: "BUILDER BASE", section: entry.data.builderBase, columns: 1)
        }
      }
    }
  }

  private var mediumBody: some View {
    VStack(alignment: .leading, spacing: 6) {
      accountHeader
      if let choice = mediumTaskChoice {
        mediumTaskCard(choice)
      } else {
        HStack(alignment: .top, spacing: 7) {
          compactSection(title: "VILLAGE", section: entry.data.homeBuilders)
          compactResearchSection
        }
      }
      HStack(spacing: 5) {
        ForEach(Array(entry.data.boosts.prefix(2))) { boost in
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
          Text(shortBoostName(boost.label))
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
      VStack(alignment: .leading, spacing: 0) {
        Text(shortHelperName(helper.name)).fontWeight(.semibold)
        Text(helper.status)
          .foregroundStyle(.secondary)
      }
      .font(.system(size: 7.5))
      .lineLimit(1)
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
          Text(shortHelperName(helper.name))
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
          HStack(spacing: 2) {
            Text(helper.statusUntil != nil && helper.statusUntil! <= context.date ? "Ready" : helper.status)
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
      Text("RESEARCH")
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.secondary)
      if let task = entry.data.laboratory.tasks.first ?? entry.data.pets.tasks.first ?? entry.data.builderBase.tasks.first {
        taskRow(task)
      } else {
        Text("No active research")
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
        Text(task.name)
          .font(.system(size: 10, weight: .semibold))
          .lineLimit(1)
        TimelineView(.periodic(from: .now, by: 1)) { context in
          HStack(spacing: 3) {
            Text("Lv \(task.fromLevel) → \(task.toLevel) ·")
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
    guard section.available else { return "LOCKED" }
    if section.tasks.isEmpty && section.remainingCount == 0 { return "MAXED" }
    let idle = max(0, section.capacity - section.tasks.count)
    if idle > 0 { return "\(idle) IDLE" }
    return ""
  }

  private func sectionStatusColor(_ section: UpgradeWidgetSectionData) -> Color {
    guard section.available else { return .secondary }
    if section.tasks.isEmpty && section.remainingCount == 0 { return .green }
    if section.capacity > section.tasks.count { return .orange }
    return .secondary
  }

  private func emptySectionLabel(_ section: UpgradeWidgetSectionData) -> String {
    guard section.available else { return "Not unlocked" }
    return section.remainingCount == 0 ? "Fully upgraded" : "No active upgrades"
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
    if #available(iOSApplicationExtension 16.1, *) {
      WarLiveActivityWidget()
    }
  }
}
