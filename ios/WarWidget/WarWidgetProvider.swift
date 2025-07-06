import WidgetKit
import SwiftUI

struct WarWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WarWidgetEntry {
        WarWidgetEntry(
            date: Date(),
            warState: .notInWar,
            clanName: "Your Clan",
            opponentName: "Opponent",
            clanBadgeUrl: "",
            opponentBadgeUrl: "",
            score: "0 - 0",
            timeState: "Not in war",
            clanPercent: "0%",
            clanAttacks: "0/0",
            opponentPercent: "0%",
            opponentAttacks: "0/0",
            colorTheme: .neutral,
            primaryText: "Not in war",
            secondaryText: "",
            updatedAt: "Now"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WarWidgetEntry) -> ()) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WarWidgetEntry>) -> ()) {
        var entries: [WarWidgetEntry] = []
        
        // Get war data from UserDefaults (shared with main app)
        let userDefaults = UserDefaults(suiteName: "group.com.clashking.clashkingapp")
        
        let currentDate = Date()
        let entry = createWarWidgetEntry(from: userDefaults, date: currentDate)
        entries.append(entry)
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func createWarWidgetEntry(from userDefaults: UserDefaults?, date: Date) -> WarWidgetEntry {
        guard let userDefaults = userDefaults,
              let warInfoString = userDefaults.string(forKey: "warInfo"),
              let warInfoData = warInfoString.data(using: .utf8),
              let warInfo = try? JSONSerialization.jsonObject(with: warInfoData) as? [String: Any] else {
            return createDefaultEntry(date: date)
        }
        
        let state = warInfo["state"] as? String ?? "error"
        let updatedAt = warInfo["updatedAt"] as? String ?? ""
        let primaryText = warInfo["primaryText"] as? String ?? ""
        let secondaryText = warInfo["secondaryText"] as? String ?? ""
        let colorThemeString = warInfo["colorTheme"] as? String ?? "neutral"
        let score = warInfo["score"] as? String ?? ""
        let timeState = warInfo["timeState"] as? String ?? ""
        
        let warState = WarState(rawValue: state) ?? .error
        let colorTheme = WarColorTheme(rawValue: colorThemeString) ?? .neutral
        
        // Handle clan and opponent data
        var clanName = ""
        var opponentName = ""
        var clanBadgeUrl = ""
        var opponentBadgeUrl = ""
        var clanPercent = ""
        var clanAttacks = ""
        var opponentPercent = ""
        var opponentAttacks = ""
        
        if let clanInfo = warInfo["clan"] as? [String: Any] {
            clanName = clanInfo["name"] as? String ?? ""
            clanBadgeUrl = clanInfo["badgeUrlMedium"] as? String ?? ""
            clanPercent = clanInfo["percent"] as? String ?? ""
            clanAttacks = clanInfo["attacks"] as? String ?? ""
        }
        
        if let opponentInfo = warInfo["opponent"] as? [String: Any] {
            opponentName = opponentInfo["name"] as? String ?? ""
            opponentBadgeUrl = opponentInfo["badgeUrlMedium"] as? String ?? ""
            opponentPercent = opponentInfo["percent"] as? String ?? ""
            opponentAttacks = opponentInfo["attacks"] as? String ?? ""
        }
        
        return WarWidgetEntry(
            date: date,
            warState: warState,
            clanName: clanName,
            opponentName: opponentName,
            clanBadgeUrl: clanBadgeUrl,
            opponentBadgeUrl: opponentBadgeUrl,
            score: score,
            timeState: timeState,
            clanPercent: clanPercent,
            clanAttacks: clanAttacks,
            opponentPercent: opponentPercent,
            opponentAttacks: opponentAttacks,
            colorTheme: colorTheme,
            primaryText: primaryText,
            secondaryText: secondaryText,
            updatedAt: updatedAt
        )
    }
    
    private func createDefaultEntry(date: Date) -> WarWidgetEntry {
        return WarWidgetEntry(
            date: date,
            warState: .error,
            clanName: "",
            opponentName: "",
            clanBadgeUrl: "",
            opponentBadgeUrl: "",
            score: "",
            timeState: "",
            clanPercent: "",
            clanAttacks: "",
            opponentPercent: "",
            opponentAttacks: "",
            colorTheme: .neutral,
            primaryText: "Unable to load war data",
            secondaryText: "Open ClashKing app to refresh",
            updatedAt: ""
        )
    }
}