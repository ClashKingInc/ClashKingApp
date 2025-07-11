import SwiftUI
import WidgetKit

struct WarWidgetEntryView: View {
    var entry: WarWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWarWidgetView(entry: entry)
        case .systemMedium:
            MediumWarWidgetView(entry: entry)
        default:
            MediumWarWidgetView(entry: entry)
        }
    }
}

struct SmallWarWidgetView: View {
    let entry: WarWidgetEntry
    
    var body: some View {
        VStack(spacing: 4) {
            // Header with colored background
            VStack(spacing: 2) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                    Text("ClashKing")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                }
                
                if !entry.primaryText.isEmpty {
                    Text(entry.primaryText)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                } else {
                    Text(entry.score.isEmpty ? "No War" : entry.score)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(entry.colorTheme.color)
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            // Content area
            VStack(spacing: 2) {
                if !entry.secondaryText.isEmpty {
                    Text(entry.secondaryText)
                        .font(.system(size: 11))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                } else if !entry.timeState.isEmpty {
                    Text(entry.timeState)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                if !entry.updatedAt.isEmpty {
                    Text(entry.updatedAt)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
    }
}

struct MediumWarWidgetView: View {
    let entry: WarWidgetEntry
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with colored background
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                Text("ClashKing")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if !entry.updatedAt.isEmpty {
                    Text(entry.updatedAt)
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 10))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(entry.colorTheme.color)
            
            // War status section
            VStack(spacing: 4) {
                HStack {
                    Text(!entry.primaryText.isEmpty ? entry.primaryText : entry.score)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                if !entry.secondaryText.isEmpty {
                    HStack {
                        Text(entry.secondaryText)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if !entry.timeState.isEmpty {
                    HStack {
                        Text(entry.timeState)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            // Clan vs Opponent section (only show if we have clan data)
            if !entry.clanName.isEmpty && !entry.opponentName.isEmpty {
                HStack(spacing: 12) {
                    // Clan side
                    VStack(spacing: 2) {
                        AsyncBadgeImage(url: entry.clanBadgeUrl)
                            .frame(width: 24, height: 24)
                        
                        Text(entry.clanName)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        if !entry.clanPercent.isEmpty {
                            Text(entry.clanPercent)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        
                        if !entry.clanAttacks.isEmpty {
                            Text(entry.clanAttacks)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // VS separator
                    Text("VS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    // Opponent side
                    VStack(spacing: 2) {
                        AsyncBadgeImage(url: entry.opponentBadgeUrl)
                            .frame(width: 24, height: 24)
                        
                        Text(entry.opponentName)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        if !entry.opponentPercent.isEmpty {
                            Text(entry.opponentPercent)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        
                        if !entry.opponentAttacks.isEmpty {
                            Text(entry.opponentAttacks)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            } else {
                Spacer()
                    .frame(height: 8)
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
    }
}

struct AsyncBadgeImage: View {
    let url: String
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } placeholder: {
            Image(systemName: "shield.fill")
                .foregroundColor(.gray)
        }
    }
}

// Extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}