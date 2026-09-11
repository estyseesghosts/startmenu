import Foundation

/// The final, Tahoe-style folder shown in the launcher.
///
/// Apple does not publish the exact grouping its own Spotlight Apps surface
/// uses, so this type reproduces it as closely as the public metadata allows.
enum CategoryGroup: String, Codable, CaseIterable, Identifiable, Sendable {
    case productivityFinance
    case social
    case developerTools
    case utilities
    case entertainment
    case creativity
    case photoVideo
    case informationReading
    case games
    case arcade
    case other

    var id: String { rawValue }

    /// The user-facing folder name.
    var displayName: String {
        switch self {
        case .productivityFinance: return "Productivity & Finance"
        case .social: return "Social"
        case .developerTools: return "Developer Tools"
        case .utilities: return "Utilities"
        case .entertainment: return "Entertainment"
        case .creativity: return "Creativity"
        case .photoVideo: return "Photo & Video"
        case .informationReading: return "Information & Reading"
        case .games: return "Games"
        case .arcade: return "Arcade"
        case .other: return "Other"
        }
    }

    /// An SF Symbol used as a fallback when the group has no member icons.
    var symbolName: String {
        switch self {
        case .productivityFinance: return "chart.bar.doc.horizontal"
        case .social: return "bubble.left.and.bubble.right"
        case .developerTools: return "hammer"
        case .utilities: return "wrench.and.screwdriver"
        case .entertainment: return "popcorn"
        case .creativity: return "paintpalette"
        case .photoVideo: return "camera"
        case .informationReading: return "book"
        case .games: return "gamecontroller"
        case .arcade: return "arcade.stick"
        case .other: return "square.grid.2x2"
        }
    }

    /// The lower-level categories that fold into this group.
    var sourceCategories: [ApplicationCategory] {
        switch self {
        case .productivityFinance:
            return [.productivity, .finance, .business]
        case .social:
            return [.socialNetworking]
        case .developerTools:
            return [.developerTools]
        case .utilities:
            return [.utilities]
        case .entertainment:
            return [.entertainment]
        case .creativity:
            return [.graphicsDesign, .music]
        case .photoVideo:
            return [.photography, .video]
        case .informationReading:
            return [.news, .reference]
        case .games:
            return [.games, .actionGames, .adventureGames, .puzzleGames, .strategyGames,
                    .boardGames, .cardGames, .casinoGames, .diceGames, .educationalGames,
                    .familyGames, .racingGames, .rolePlayingGames, .simulationGames,
                    .sportsGames, .triviaGames, .wordGames]
        case .arcade:
            return [.arcadeGames, .musicGames]
        case .other:
            return [.other]
        }
    }
}
