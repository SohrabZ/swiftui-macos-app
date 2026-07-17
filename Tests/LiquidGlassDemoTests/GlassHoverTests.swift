import Testing
@testable import LiquidGlassDemo

@Suite struct GlassHoverTests {
    @Test func scaleWhenHovering() {
        #expect(GlassHover.scale(isHovering: true) == GlassHover.hovered)
    }

    @Test func scaleWhenNotHovering() {
        #expect(GlassHover.scale(isHovering: false) == GlassHover.resting)
    }

    @Test func hoveredScaleIsLargerThanResting() {
        #expect(GlassHover.hovered > GlassHover.resting)
    }
}
