import Testing
@testable import LiquidGlassDemo

@Suite struct OpacityControlTests {
    @Test func clampsToBounds() {
        let card = OpacityControl.card
        #expect(card.clamp(-0.5) == card.range.lowerBound)
        #expect(card.clamp(5.0) == card.range.upperBound)
    }

    @Test func passesThroughInRange() {
        #expect(abs(OpacityControl.card.clamp(0.3) - 0.3) < 0.0001)
    }

    @Test func canGoFullyTransparent() {
        let card = OpacityControl.card
        #expect(card.range.lowerBound == 0.0)   // the card panel may vanish entirely
        #expect(card.clamp(0.0) == 0.0)
    }

    @Test func percent() {
        #expect(OpacityControl.card.percent(0.3) == 30)
        #expect(OpacityControl.card.percent(5.0) == 100)   // clamped above
        #expect(OpacityControl.card.percent(0.0) == 0)     // card floor is 0
    }

    @Test func defaultValue() {
        #expect(OpacityControl.card.defaultValue == 0.8)   // slightly glassy by default
    }
}
