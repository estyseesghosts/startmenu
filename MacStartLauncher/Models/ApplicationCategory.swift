import Foundation

/// A lower-level application category as exposed by Apple metadata.
///
/// The raw values are derived from either `kMDItemApplicationCategories` or
/// `LSApplicationCategoryType`. `CategoryResolver` maps these into the
/// Tahoe-style `CategoryGroup` values that the launcher presents.
enum ApplicationCategory: String, Codable, CaseIterable, Sendable {
    case productivity
    case finance
    case business
    case socialNetworking
    case developerTools
    case utilities
    case entertainment
    case graphicsDesign
    case music
    case photography
    case video
    case news
    case reference
    case games
    case arcadeGames
    case actionGames
    case adventureGames
    case puzzleGames
    case strategyGames
    case boardGames
    case cardGames
    case casinoGames
    case diceGames
    case educationalGames
    case familyGames
    case musicGames
    case racingGames
    case rolePlayingGames
    case simulationGames
    case sportsGames
    case triviaGames
    case wordGames
    case other

    /// Creates a category from an arbitrary Apple metadata string.
    ///
    /// Handles both human-readable values such as `"Social Networking"` and
    /// UTI values such as `"public.app-category.social-networking"`.
    init(metadataValue: String) {
        let normalized = Self.normalize(metadataValue)
        if let match = Self.allCases.first(where: { Self.normalize($0.rawValue) == normalized }) {
            self = match
        } else {
            self = .other
        }
    }

    /// Normalizes metadata values so that spaces, hyphens, and underscores do
    /// not prevent matching.
    static func normalize(_ value: String) -> String {
        var result = value.lowercased()
        if let range = result.range(of: "public.app-category.") {
            result.removeSubrange(result.startIndex..<range.upperBound)
        }
        if let range = result.range(of: "public.app-category-") {
            result.removeSubrange(result.startIndex..<range.upperBound)
        }
        return result
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}
