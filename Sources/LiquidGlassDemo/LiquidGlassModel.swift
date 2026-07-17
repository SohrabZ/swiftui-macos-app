import SwiftUI

/// Text/icon content shown on the glass card. Extracted from the view so the
/// content is data that can be asserted on in tests.
struct GlassCardModel: Equatable {
    var iconName: String
    var title: String
    var subtitle: String

    static let demo = GlassCardModel(
        iconName: "drop.fill",
        title: "Liquid Glass",
        subtitle: "This card uses ultraThinMaterial to create a glass effect on macOS 26."
    )
}

/// Hover interaction constants plus the pure scaling function used by the card.
/// Kept separate from the view so the behavior is unit-testable without a UI.
enum GlassHover {
    static let resting: CGFloat = 1.0
    static let hovered: CGFloat = 1.02

    /// The scale the card should adopt for a given hover state.
    static func scale(isHovering: Bool) -> CGFloat {
        isHovering ? hovered : resting
    }
}

/// A clamped opacity control (1.0 = fully solid, lower = more see-through).
/// Extracted so the range and clamping are testable without any UI. Currently only
/// the card background uses it (`.card`); it stays parameterized by range so other
/// opacity controls can reuse it.
struct OpacityControl {
    let range: ClosedRange<Double>
    let defaultValue: Double

    /// Clamps an arbitrary opacity into the usable range.
    func clamp(_ value: Double) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }

    /// Whole-number percent for display, e.g. 0.42 -> 42.
    func percent(_ value: Double) -> Int {
        Int((clamp(value) * 100).rounded())
    }

    /// Card-panel opacity. Defaults below 100% so the glass/blur effect (grid
    /// showing through the frosted panel) is visible on first launch. May go
    /// fully transparent — the content in front stays readable.
    static let card = OpacityControl(range: 0.0...1.0, defaultValue: 0.8)
}

/// Backdrop mesh-gradient definition. Storing the grid as plain data lets tests
/// verify the mesh is well-formed (point/color counts match the grid size).
struct MeshBackdrop {
    let width: Int
    let height: Int
    let points: [SIMD2<Float>]
    let colors: [Color]

    /// True when the number of control points and colors matches `width * height`,
    /// which `MeshGradient` requires — an invalid mesh crashes at render time.
    var isValid: Bool {
        let expected = width * height
        return points.count == expected && colors.count == expected
    }

    static let demo = MeshBackdrop(
        width: 3,
        height: 3,
        points: [
            SIMD2(0, 0), SIMD2(0.5, 0), SIMD2(1, 0),
            SIMD2(0, 0.5), SIMD2(0.5, 0.5), SIMD2(1, 0.5),
            SIMD2(0, 1), SIMD2(0.5, 1), SIMD2(1, 1)
        ],
        colors: [
            Color(lightHex: 0xFFFFFF, darkHex: 0x090B10),
            Color(lightHex: 0xF7F8FA, darkHex: 0x0B0D12),
            Color(lightHex: 0xFBFCFD, darkHex: 0x0A0C11),
            Color(lightHex: 0xF2F4F7, darkHex: 0x0D1019),
            Color(lightHex: 0xEEF1F5, darkHex: 0x11141F),
            Color(lightHex: 0xF7F8FA, darkHex: 0x0C0E15),
            Color(lightHex: 0xFFFFFF, darkHex: 0x090B10),
            Color(lightHex: 0xF4F6F9, darkHex: 0x0C0F17),
            Color(lightHex: 0xFAFBFC, darkHex: 0x0A0C12)
        ]
    )
}
