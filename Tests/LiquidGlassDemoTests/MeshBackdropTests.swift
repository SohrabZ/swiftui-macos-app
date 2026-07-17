import Testing
import SwiftUI
@testable import LiquidGlassDemo

@Suite struct MeshBackdropTests {
    @Test func demoBackdropIsValid() {
        #expect(MeshBackdrop.demo.isValid)
    }

    @Test func demoBackdropIsThreeByThree() {
        let backdrop = MeshBackdrop.demo
        #expect(backdrop.width == 3)
        #expect(backdrop.height == 3)
        #expect(backdrop.points.count == 9)
        #expect(backdrop.colors.count == 9)
    }

    @Test func invalidBackdropIsDetected() {
        // Only 1 point/color for a 9-cell grid — MeshGradient would crash on this.
        let broken = MeshBackdrop(width: 3, height: 3, points: [SIMD2(0, 0)], colors: [.red])
        #expect(!broken.isValid)
    }
}
