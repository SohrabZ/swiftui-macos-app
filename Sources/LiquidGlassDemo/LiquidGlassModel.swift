import SwiftUI

/// Text content shown on the glass card, beneath the app icon. Extracted from
/// the view so the content is data that can be asserted on in tests.
struct GlassCardModel: Equatable {
    var title: String
    var subtitle: String

    static let demo = GlassCardModel(
        title: "Liquid Glass",
        subtitle: "Real Liquid Glass over a live themed mesh — tint, frost, and light respond as you tune them."
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

/// Accessibility-driven overrides for the glass rendering (Reduce Transparency
/// solidifies see-through surfaces). Pure functions so they stay testable.
enum GlassA11y {
    /// The effective value of a behavior: the system setting OR the in-app
    /// override (an override can only turn a behavior on, never off).
    static func effective(system: Bool, override: Bool) -> Bool {
        system || override
    }

    /// Card-panel opacity: fully opaque under Reduce Transparency.
    static func cardAlpha(_ alpha: Double, reduceTransparency: Bool) -> Double {
        reduceTransparency ? 1 : alpha
    }

    /// Backdrop frost: removed under Reduce Transparency.
    static func blur(_ blur: Double, reduceTransparency: Bool) -> Double {
        reduceTransparency ? 0 : blur
    }

    /// Sidebar tint over the window vibrancy: fully opaque under Reduce Transparency.
    static func sidebarOpacity(_ opacity: Double, reduceTransparency: Bool) -> Double {
        reduceTransparency ? 1 : opacity
    }
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

    /// Recolors the mesh to the active theme: background-derived points with a
    /// soft accent bloom (strongest at the center), so switching themes visibly
    /// transforms the hero area. Computed per light/dark hex pair, so the result
    /// stays appearance-adaptive.
    func tinted(with palette: Palette) -> MeshBackdrop {
        func color(_ t: Double) -> Color {
            Color(lightHex: Self.mix(palette.bgLightHex, palette.accentLightHex, by: t),
                  darkHex: Self.mix(palette.bgDarkHex, palette.accentDarkHex, by: t))
        }
        return MeshBackdrop(width: width, height: height, points: points, colors: [
            color(0.00), color(0.06), color(0.00),
            color(0.10), color(0.18), color(0.08),
            color(0.00), color(0.06), color(0.02)
        ])
    }

    /// Linearly interpolates two 0xRRGGBB colors per channel; `t` clamps to 0…1.
    static func mix(_ a: UInt32, _ b: UInt32, by t: Double) -> UInt32 {
        let t = min(max(t, 0), 1)
        func channel(_ shift: UInt32) -> UInt32 {
            let av = Double((a >> shift) & 0xFF)
            let bv = Double((b >> shift) & 0xFF)
            return UInt32((av + (bv - av) * t).rounded()) & 0xFF
        }
        return (channel(16) << 16) | (channel(8) << 8) | channel(0)
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
