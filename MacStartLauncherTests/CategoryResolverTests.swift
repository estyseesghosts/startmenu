import XCTest
@testable import MacStartLauncher

final class CategoryResolverTests: XCTestCase {
    private let resolver = CategoryResolver()

    func testProductivityMapsToProductivityAndFinance() {
        XCTAssertEqual(
            resolver.group(forRawCategories: ["public.app-category.productivity"]),
            .productivityFinance
        )
    }

    func testFinanceAndBusinessFoldIntoProductivityAndFinance() {
        XCTAssertEqual(resolver.group(forRawCategories: ["Finance"]), .productivityFinance)
        XCTAssertEqual(resolver.group(forRawCategories: ["Business"]), .productivityFinance)
    }

    func testSocialNetworkingMapsToSocial() {
        XCTAssertEqual(
            resolver.group(forRawCategories: ["public.app-category.social-networking"]),
            .social
        )
    }

    func testDeveloperToolsMapsToDeveloperTools() {
        XCTAssertEqual(
            resolver.group(forRawCategories: ["public.app-category.developer-tools"]),
            .developerTools
        )
    }

    func testUtilitiesMapsToUtilities() {
        XCTAssertEqual(resolver.group(forRawCategories: ["Utilities"]), .utilities)
    }

    func testEntertainmentMapsToEntertainment() {
        XCTAssertEqual(resolver.group(forRawCategories: ["Entertainment"]), .entertainment)
    }

    func testGraphicsAndMusicFoldIntoCreativity() {
        XCTAssertEqual(
            resolver.group(forRawCategories: ["public.app-category.graphics-design"]),
            .creativity
        )
        XCTAssertEqual(resolver.group(forRawCategories: ["public.app-category.music"]), .creativity)
    }

    func testPhotographyAndVideoFoldIntoPhotoAndVideo() {
        XCTAssertEqual(
            resolver.group(forRawCategories: ["public.app-category.photography"]),
            .photoVideo
        )
        XCTAssertEqual(resolver.group(forRawCategories: ["public.app-category.video"]), .photoVideo)
    }

    func testNewsAndReferenceFoldIntoInformationAndReading() {
        XCTAssertEqual(resolver.group(forRawCategories: ["News"]), .informationReading)
        XCTAssertEqual(resolver.group(forRawCategories: ["Reference"]), .informationReading)
    }

    func testGamesAndArcadeMapToTheirGroups() {
        XCTAssertEqual(resolver.group(forRawCategories: ["public.app-category.games"]), .games)
        XCTAssertEqual(
            resolver.group(forRawCategories: ["public.app-category.arcade-games"]),
            .arcade
        )
    }

    func testUnknownCategoryFallsBackToOther() {
        XCTAssertEqual(resolver.group(forRawCategories: ["totally-unknown"]), .other)
        XCTAssertEqual(resolver.group(forRawCategories: []), .other)
    }

    func testFirstKnownCategoryWins() {
        let raw = ["totally-unknown", "public.app-category.utilities", "public.app-category.games"]
        XCTAssertEqual(resolver.group(forRawCategories: raw), .utilities)
    }

    func testMetadataNormalizationHandlesSpacesAndHyphens() {
        XCTAssertEqual(ApplicationCategory(metadataValue: "Social Networking"), .socialNetworking)
        XCTAssertEqual(
            ApplicationCategory(metadataValue: "public.app-category.social-networking"),
            .socialNetworking
        )
        XCTAssertEqual(
            ApplicationCategory(metadataValue: "public.app-category.developer_tools"),
            .developerTools
        )
    }

    func testCategoryGroupNamesMatchFramework() {
        XCTAssertEqual(CategoryGroup.productivityFinance.displayName, "Productivity & Finance")
        XCTAssertEqual(CategoryGroup.informationReading.displayName, "Information & Reading")
        XCTAssertEqual(CategoryGroup.photoVideo.displayName, "Photo & Video")
    }
}
