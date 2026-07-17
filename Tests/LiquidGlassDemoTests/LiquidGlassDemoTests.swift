import XCTest
import SwiftUI
@testable import LiquidGlassDemo

final class LiquidGlassDemoTests: XCTestCase {

    // MARK: - Hover behavior

    func testHoverScaleWhenHovering() {
        XCTAssertEqual(GlassHover.scale(isHovering: true), GlassHover.hovered)
    }

    func testHoverScaleWhenNotHovering() {
        XCTAssertEqual(GlassHover.scale(isHovering: false), GlassHover.resting)
    }

    func testHoveredScaleIsLargerThanResting() {
        XCTAssertGreaterThan(GlassHover.hovered, GlassHover.resting,
                             "Hovering should scale the card up, not down.")
    }

    // MARK: - Mesh backdrop invariants

    func testDemoBackdropIsValid() {
        XCTAssertTrue(MeshBackdrop.demo.isValid,
                      "Point and color counts must equal width * height or MeshGradient crashes.")
    }

    func testDemoBackdropIsThreeByThree() {
        let backdrop = MeshBackdrop.demo
        XCTAssertEqual(backdrop.width, 3)
        XCTAssertEqual(backdrop.height, 3)
        XCTAssertEqual(backdrop.points.count, 9)
        XCTAssertEqual(backdrop.colors.count, 9)
    }

    func testInvalidBackdropIsDetected() {
        let broken = MeshBackdrop(
            width: 3,
            height: 3,
            points: [SIMD2(0, 0)],          // only 1 point for a 9-cell grid
            colors: [.red]
        )
        XCTAssertFalse(broken.isValid)
    }

    // MARK: - Card opacity control

    func testCardOpacityClampsToBounds() {
        let card = OpacityControl.card
        XCTAssertEqual(card.clamp(-0.5), card.range.lowerBound)
        XCTAssertEqual(card.clamp(5.0), card.range.upperBound)
    }

    func testCardOpacityPassesThroughInRange() {
        XCTAssertEqual(OpacityControl.card.clamp(0.3), 0.3, accuracy: 0.0001)
    }

    func testCardOpacityCanGoFullyTransparent() {
        let card = OpacityControl.card
        XCTAssertEqual(card.range.lowerBound, 0.0,
                       "The card panel may vanish entirely; its content stays on the backdrop.")
        XCTAssertEqual(card.clamp(0.0), 0.0)
    }

    func testCardOpacityPercent() {
        XCTAssertEqual(OpacityControl.card.percent(0.3), 30)
        XCTAssertEqual(OpacityControl.card.percent(5.0), 100)   // clamped above
        XCTAssertEqual(OpacityControl.card.percent(0.0), 0)     // card floor is 0
    }

    func testCardOpacityDefault() {
        XCTAssertEqual(OpacityControl.card.defaultValue, 0.8)   // card slightly glassy by default
    }

    // MARK: - Card content

    func testDemoCardContent() {
        let card = GlassCardModel.demo
        XCTAssertEqual(card.iconName, "drop.fill")
        XCTAssertEqual(card.title, "Liquid Glass")
        XCTAssertFalse(card.subtitle.isEmpty)
    }

    // MARK: - View wiring

    @MainActor
    func testContentViewUsesInjectedModels() {
        let card = GlassCardModel(
            iconName: "star.fill",
            title: "Custom",
            subtitle: "Sub"
        )
        let view = ContentView(backdrop: .demo, card: card)
        XCTAssertEqual(view.card, card)
        XCTAssertTrue(view.backdrop.isValid)
    }
}
