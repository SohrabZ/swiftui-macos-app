import Foundation
import Testing
@testable import LiquidGlassDemo

@Suite struct DeepLinkTests {
    @Test func parsesThemeLink() {
        #expect(DeepLink(url: URL(string: "liquidglassdemo://theme/ember")!) == .theme(.ember))
        #expect(DeepLink(url: URL(string: "liquidglassdemo://theme/cyberpunk")!) == .theme(.cyberpunk))
    }

    @Test func rejectsUnknownTheme() {
        #expect(DeepLink(url: URL(string: "liquidglassdemo://theme/plaid")!) == nil)
    }

    @Test func rejectsMissingThemeID() {
        #expect(DeepLink(url: URL(string: "liquidglassdemo://theme")!) == nil)
    }

    @Test func rejectsUnknownHost() {
        #expect(DeepLink(url: URL(string: "liquidglassdemo://settings")!) == nil)
    }

    @Test func rejectsWrongScheme() {
        #expect(DeepLink(url: URL(string: "https://example.com/theme/ember")!) == nil)
    }
}
