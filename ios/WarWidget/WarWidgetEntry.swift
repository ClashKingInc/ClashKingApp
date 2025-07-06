import WidgetKit
import SwiftUI

struct WarWidgetEntry: TimelineEntry {
    let date: Date
    let warState: WarState
    let clanName: String
    let opponentName: String
    let clanBadgeUrl: String
    let opponentBadgeUrl: String
    let score: String
    let timeState: String
    let clanPercent: String
    let clanAttacks: String
    let opponentPercent: String
    let opponentAttacks: String
    let colorTheme: WarColorTheme
    let primaryText: String
    let secondaryText: String
    let updatedAt: String
}

enum WarState: String, CaseIterable {
    case notInWar = "notInWar"
    case notInClan = "notInClan"
    case accessDenied = "accessDenied"
    case inWar = "inWar"
    case cwl = "cwl"
    case preparation = "preparation"
    case warDay = "warDay"
    case ended = "ended"
    case error = "error"
}

enum WarColorTheme: String, CaseIterable {
    case winning = "winning"
    case losing = "losing"
    case tied = "tied"
    case victory = "victory"
    case defeat = "defeat"
    case preparation = "preparation"
    case cwl = "cwl"
    case warning = "warning"
    case neutral = "neutral"
    
    var color: Color {
        switch self {
        case .winning:
            return Color(red: 27/255, green: 94/255, blue: 32/255) // Dark green
        case .losing:
            return Color(red: 183/255, green: 28/255, blue: 28/255) // Dark red
        case .tied:
            return Color(red: 230/255, green: 81/255, blue: 0/255) // Orange
        case .victory:
            return Color(red: 46/255, green: 125/255, blue: 50/255) // Green
        case .defeat:
            return Color(red: 198/255, green: 40/255, blue: 40/255) // Red
        case .preparation:
            return Color(red: 21/255, green: 101/255, blue: 192/255) // Blue
        case .cwl:
            return Color(red: 106/255, green: 27/255, blue: 154/255) // Purple
        case .warning:
            return Color(red: 239/255, green: 108/255, blue: 0/255) // Orange
        case .neutral:
            return Color(red: 66/255, green: 66/255, blue: 66/255) // Gray
        }
    }
}