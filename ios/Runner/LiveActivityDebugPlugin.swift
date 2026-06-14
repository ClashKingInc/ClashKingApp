import ActivityKit
import Flutter
import UIKit

private let liveActivityAppGroupIdentifier = "group.com.clashking.apps"

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

final class LiveActivityDebugPlugin: NSObject, FlutterPlugin {
  private var activeActivity: Any?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "clashking/live_activity_debug",
      binaryMessenger: registrar.messenger()
    )
    let instance = LiveActivityDebugPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *) else {
      result(FlutterError(code: "unavailable", message: "This local Live Activity test requires iOS 16.2 or newer.", details: nil))
      return
    }

    switch call.method {
    case "start":
      start(result: result)
    case "update":
      update(result: result)
    case "end":
      end(result: result)
    case "status":
      result(status())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.2, *)
  private func start(result: @escaping FlutterResult) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      result(FlutterError(code: "disabled", message: "Live Activities are disabled for this device or app.", details: nil))
      return
    }

    Task {
      do {
        for activity in Activity<WarLiveActivityAttributes>.activities {
          await end(activity: activity)
        }

        let attributes = WarLiveActivityAttributes(
          clanTag: "#DEBUGCLAN",
          warId: "debug-war-\(Int(Date().timeIntervalSince1970))"
        )
        let clanBadgeUrl = "https://api-assets.clashofclans.com/badges/200/rUTlb1JZ2mWUsbWlYXukHVWZDU3WiSdWsa3pjTWPcD4.png"
        let opponentBadgeUrl = "https://api-assets.clashofclans.com/badges/200/r2lWyySjtwWG-bPTnsAmSP6tDihC5rRatgaOdQLgPZU.png"
        let attackerTownHallUrl = "https://assets.clashk.ing/home-base/town-hall-pics/town-hall-18.png"
        let defenderTownHallUrl = "https://assets.clashk.ing/home-base/town-hall-pics/town-hall-17.png"
        let state = WarLiveActivityAttributes.ContentState(
          state: "preparation",
          mode: "war",
          clanName: "Home Clan",
          opponentName: "Opponent Clan",
          clanStars: 0,
          opponentStars: 0,
          timeState: "Starts in 20h",
          clanBadgeUrl: clanBadgeUrl,
          opponentBadgeUrl: opponentBadgeUrl,
          clanBadgePath: await cachedImagePath(urlString: clanBadgeUrl, key: "debug-clan-badge"),
          opponentBadgePath: await cachedImagePath(urlString: opponentBadgeUrl, key: "debug-opponent-badge"),
          latestAttackerName: "Attacker",
          latestDefenderName: "Defender",
          attackerTownHallUrl: attackerTownHallUrl,
          defenderTownHallUrl: defenderTownHallUrl,
          attackerTownHallPath: await cachedImagePath(urlString: attackerTownHallUrl, key: "debug-attacker-th18"),
          defenderTownHallPath: await cachedImagePath(urlString: defenderTownHallUrl, key: "debug-defender-th17"),
          latestAttackStars: 0,
          latestAttackDestruction: "Prep"
        )

        let activity = try Activity.request(
          attributes: attributes,
          content: ActivityContent(state: state, staleDate: nil),
          pushType: nil
        )

        activeActivity = activity
        result(status())
      } catch {
        result(FlutterError(code: "start_failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  @available(iOS 16.2, *)
  private func update(result: @escaping FlutterResult) {
    guard let activity = currentActivity() else {
      result(FlutterError(code: "not_started", message: "No debug Live Activity is running.", details: nil))
      return
    }

    Task {
      let current = activity.content.state
      let clanStars = min(current.clanStars + 1, 45)
      let opponentStars = current.opponentStars + (clanStars.isMultiple(of: 3) ? 1 : 0)
      let defenderTownHallUrl = clanStars.isMultiple(of: 2)
        ? "https://assets.clashk.ing/home-base/town-hall-pics/town-hall-17.png"
        : "https://assets.clashk.ing/home-base/town-hall-pics/town-hall-18.png"
      let next = WarLiveActivityAttributes.ContentState(
        state: "inWar",
        mode: current.mode,
        clanName: current.clanName,
        opponentName: current.opponentName,
        clanStars: clanStars,
        opponentStars: opponentStars,
        timeState: "14h 32m left",
        clanBadgeUrl: current.clanBadgeUrl,
        opponentBadgeUrl: current.opponentBadgeUrl,
        clanBadgePath: current.clanBadgePath,
        opponentBadgePath: current.opponentBadgePath,
        latestAttackerName: clanStars.isMultiple(of: 2) ? "Attacker" : "Second Attacker",
        latestDefenderName: clanStars.isMultiple(of: 2) ? "Defender" : "Second Defender",
        attackerTownHallUrl: current.attackerTownHallUrl,
        defenderTownHallUrl: defenderTownHallUrl,
        attackerTownHallPath: current.attackerTownHallPath,
        defenderTownHallPath: await cachedImagePath(
          urlString: defenderTownHallUrl,
          key: clanStars.isMultiple(of: 2) ? "debug-defender-th17" : "debug-defender-th18"
        ),
        latestAttackStars: min((current.latestAttackStars + 1), 3),
        latestAttackDestruction: clanStars.isMultiple(of: 2) ? "83%" : "100%"
      )

      await activity.update(ActivityContent(state: next, staleDate: nil))
      result(status())
    }
  }

  @available(iOS 16.2, *)
  private func end(result: @escaping FlutterResult) {
    Task {
      for activity in Activity<WarLiveActivityAttributes>.activities {
        await end(activity: activity)
      }
      activeActivity = nil
      result(status())
    }
  }

  @available(iOS 16.2, *)
  private func end(activity: Activity<WarLiveActivityAttributes>) async {
    let final = WarLiveActivityAttributes.ContentState(
      state: "warEnded",
      mode: activity.content.state.mode,
      clanName: activity.content.state.clanName,
      opponentName: activity.content.state.opponentName,
      clanStars: activity.content.state.clanStars,
      opponentStars: activity.content.state.opponentStars,
      timeState: "War ended",
      clanBadgeUrl: activity.content.state.clanBadgeUrl,
      opponentBadgeUrl: activity.content.state.opponentBadgeUrl,
      clanBadgePath: activity.content.state.clanBadgePath,
      opponentBadgePath: activity.content.state.opponentBadgePath,
      latestAttackerName: activity.content.state.latestAttackerName,
      latestDefenderName: activity.content.state.latestDefenderName,
      attackerTownHallUrl: activity.content.state.attackerTownHallUrl,
      defenderTownHallUrl: activity.content.state.defenderTownHallUrl,
      attackerTownHallPath: activity.content.state.attackerTownHallPath,
      defenderTownHallPath: activity.content.state.defenderTownHallPath,
      latestAttackStars: activity.content.state.latestAttackStars,
      latestAttackDestruction: activity.content.state.latestAttackDestruction
    )

    await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
  }

  @available(iOS 16.2, *)
  private func currentActivity() -> Activity<WarLiveActivityAttributes>? {
    if let activity = activeActivity as? Activity<WarLiveActivityAttributes> {
      return activity
    }
    let activity = Activity<WarLiveActivityAttributes>.activities.first
    activeActivity = activity
    return activity
  }

  @available(iOS 16.2, *)
  private func status() -> [String: Any] {
    guard let activity = currentActivity() else {
      return ["running": false]
    }

    return [
      "running": true,
      "id": activity.id,
      "state": activity.content.state.state,
      "score": "\(activity.content.state.clanStars)-\(activity.content.state.opponentStars)",
      "timeState": activity.content.state.timeState,
    ]
  }

  private func cachedImagePath(urlString: String, key: String) async -> String {
    guard
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: liveActivityAppGroupIdentifier
      ),
      let url = URL(string: urlString)
    else {
      return ""
    }

    let directory = container.appendingPathComponent("LiveActivityImages", isDirectory: true)
    let pathExtension = url.pathExtension.isEmpty ? "png" : url.pathExtension
    let fileURL = directory.appendingPathComponent("\(key).\(pathExtension)")

    if FileManager.default.fileExists(atPath: fileURL.path) {
      return fileURL.path
    }

    do {
      try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
      )
      let (data, response) = try await URLSession.shared.data(from: url)
      guard
        let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200
      else {
        return ""
      }
      try data.write(to: fileURL, options: .atomic)
      return fileURL.path
    } catch {
      return ""
    }
  }
}
