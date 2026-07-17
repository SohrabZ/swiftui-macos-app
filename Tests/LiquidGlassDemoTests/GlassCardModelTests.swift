import Testing
@testable import LiquidGlassDemo

@Suite struct GlassCardModelTests {
    @Test func demoContent() {
        let card = GlassCardModel.demo
        #expect(card.iconName == "drop.fill")
        #expect(card.title == "Liquid Glass")
        #expect(!card.subtitle.isEmpty)
    }
}
