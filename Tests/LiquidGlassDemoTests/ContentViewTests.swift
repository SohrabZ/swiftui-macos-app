import Testing
@testable import LiquidGlassDemo

@Suite struct ContentViewTests {
    @MainActor
    @Test func usesInjectedModels() {
        let card = GlassCardModel(iconName: "star.fill", title: "Custom", subtitle: "Sub")
        let view = ContentView(backdrop: .demo, card: card)
        #expect(view.card == card)
        #expect(view.backdrop.isValid)
    }
}
