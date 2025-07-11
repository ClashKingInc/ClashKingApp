import WidgetKit
import SwiftUI
import Intents

struct WarWidget: Widget {
    let kind: String = "WarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WarWidgetProvider()) { entry in
            WarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ClashKing War Status")
        .description("Stay updated with your clan's war status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WarWidget_Previews: PreviewProvider {
    static var previews: some View {
        WarWidgetEntryView(entry: WarWidgetEntry(
            date: Date(),
            warState: .inWar,
            clanName: "Sample Clan",
            opponentName: "Enemy Clan",
            clanBadgeUrl: "",
            opponentBadgeUrl: "",
            score: "15 - 12",
            timeState: "War Day",
            clanPercent: "85%",
            clanAttacks: "12/15",
            opponentPercent: "78%",
            opponentAttacks: "10/15",
            colorTheme: .winning,
            primaryText: "Winning!",
            secondaryText: "6h 23m left",
            updatedAt: "5m ago"
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}