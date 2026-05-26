import ActivityKit
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

struct WarWidgetData: Decodable {
  struct Side: Decodable {
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

  static func current() -> WarWidgetData {
    guard
      let raw = UserDefaults(suiteName: appGroupIdentifier)?.string(forKey: "warInfo"),
      let data = raw.data(using: .utf8),
      let decoded = try? JSONDecoder().decode(WarWidgetData.self, from: data)
    else {
      return .empty
    }
    return decoded
  }
}

struct WarTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> WarWidgetEntry {
    makeEntry(data: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (WarWidgetEntry) -> Void) {
    completion(makeEntry(data: context.isPreview ? .placeholder : .current()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WarWidgetEntry>) -> Void) {
    let entry = makeEntry(data: .current())
    let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
    completion(Timeline(entries: [entry], policy: .after(next)))
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

struct WarWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: WarWidgetEntry

  var body: some View {
    switch family {
    case .systemSmall:
      compactWarView
    case .systemLarge:
      largeWarView
    case .accessoryRectangular:
      accessoryView
    default:
      mediumWarView
    }
  }

  private var compactWarView: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(entry.data.primaryText ?? entry.data.timeState ?? "War")
        .font(.caption.weight(.semibold))
        .lineLimit(2)
        .minimumScaleFactor(0.72)
      Text(scoreText)
        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
        .lineLimit(1)
      Spacer(minLength: 0)
      footer
    }
    .padding()
    .widgetBackground
  }

  private var mediumWarView: some View {
    VStack(spacing: 8) {
      if entry.data.opponent == nil {
        emptyStateView
      } else {
        HStack(alignment: .center, spacing: 10) {
          sideView(entry.data.clan, badgeData: entry.clanBadgeData)
          VStack(spacing: 4) {
            Text(scoreText)
              .font(.system(size: scoreText == "-" ? 22 : 34, weight: .bold, design: .rounded).monospacedDigit())
            Text(entry.data.primaryText ?? entry.data.timeState ?? "")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .minimumScaleFactor(0.75)
          }
          .frame(minWidth: 72)
          sideView(entry.data.opponent, badgeData: entry.opponentBadgeData)
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
        Text(scoreText)
          .font(.headline.monospacedDigit())
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

  private var emptyStateView: some View {
    VStack(spacing: 8) {
      Image(systemName: "shield")
        .font(.title2.weight(.semibold))
        .foregroundStyle(.red)
      Text(entry.data.primaryText ?? "No active war")
        .font(.headline.weight(.semibold))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.72)
      Text(entry.data.timeState?.isEmpty == false ? entry.data.timeState! : "Open ClashKing to refresh")
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
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

  private func sideView(_ side: WarWidgetData.Side?, badgeData: Data?) -> some View {
    VStack(spacing: 5) {
      badgeView(side, badgeData: badgeData, size: 54)
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
    StaticConfiguration(kind: kind, provider: WarTimelineProvider()) { entry in
      WarWidgetView(entry: entry)
    }
    .configurationDisplayName("Clan War")
    .description("Track selected-clan war and CWL score.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
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
