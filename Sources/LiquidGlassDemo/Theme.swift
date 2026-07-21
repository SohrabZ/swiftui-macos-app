import SwiftUI
import AppKit

enum ThemeID: String, CaseIterable, Identifiable {
    case slate, nous, midnight, ember, mono, cyberpunk
    var id: String { rawValue }
}

/// A full semantic palette (each color adaptive to light/dark).
struct Palette {
    let background, panel, border, divider: Color
    let textPrimary, textSecondary, accent, gridLine: Color
    let bgLightHex, bgDarkHex: UInt32
    /// Accent as raw hex per appearance, for pure-hex color math (mesh tinting).
    let accentLightHex, accentDarkHex: UInt32
}

/// Observable theme store. Injected through the SwiftUI environment
/// (`@Environment(ThemeStore.self)`) and owned by `ContentView`, so switching
/// `id` re-colors the whole app and persists. AppKit bridge points that can't
/// read the environment (the window `configure` pass and the `NSHostingView`
/// titlebar accessories) receive the same instance explicitly.
@Observable
@MainActor
final class ThemeStore {
    var id: ThemeID = .slate {
        didSet {
            UserDefaults.standard.set(id.rawValue, forKey: Prefs.theme)
            p = Self.palettes[id] ?? Self.slate
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Prefs.theme),
           let t = ThemeID(rawValue: raw) {
            id = t
        }
    }

    /// The current palette, resolved once per `id` change rather than on every
    /// color read (every themed view reads several of these properties).
    private var p: Palette = ThemeStore.slate

    /// The active palette, for callers that derive colors (e.g. mesh tinting).
    var palette: Palette { p }

    var background: Color { p.background }
    var panel: Color { p.panel }
    var border: Color { p.border }
    var divider: Color { p.divider }
    var textPrimary: Color { p.textPrimary }
    var textSecondary: Color { p.textSecondary }
    var accent: Color { p.accent }
    var gridLine: Color { p.gridLine }

    /// Subtle theme-aware fill for hovered icon buttons (adapts light/dark instead
    /// of a hardcoded white that vanishes in light mode).
    var hoverFill: Color { textPrimary.opacity(0.10) }

    /// Fill for a selected list/nav row.
    var selectionFill: Color { textPrimary.opacity(0.06) }

    /// AppKit dynamic color for the window/titlebar fill (resolves per appearance).
    var backgroundNSColor: NSColor {
        let light = p.bgLightHex, dark = p.bgDarkHex
        return NSColor(name: nil) { $0.isDark ? NSColor(hex: dark) : NSColor(hex: light) }
    }

    // Shared across themes.
    private static let textPrimary = Color(lightHex: 0x1F2328, darkHex: 0xDDE1E7)
    private static let textSecondary = Color(lightHex: 0x6A737D, darkHex: 0x868D98)
    private static let gridLine = Color(lightHex: 0x000000, darkHex: 0xFFFFFF)

    /// Default palette, also used as the fallback when a lookup somehow misses.
    static let slate = Palette(
        background: Color(lightHex: 0xFFFFFF, darkHex: 0x0B0D12),
        panel: Color(lightHex: 0xF5F6F8, darkHex: 0x14171F),
        border: Color(lightHex: 0xE1E4E8, darkHex: 0x262B36),
        divider: Color(lightHex: 0xE1E4E8, darkHex: 0x333A47),
        textPrimary: textPrimary, textSecondary: textSecondary,
        accent: Color(lightHex: 0x4169E1, darkHex: 0x5E7CE0),
        gridLine: gridLine, bgLightHex: 0xFFFFFF, bgDarkHex: 0x0B0D12,
        accentLightHex: 0x4169E1, accentDarkHex: 0x5E7CE0)

    static let palettes: [ThemeID: Palette] = [
        .slate: slate,
        .nous: Palette(
            background: Color(lightHex: 0xFFFFFF, darkHex: 0x0E1420),
            panel: Color(lightHex: 0xF3F5F9, darkHex: 0x161E2E),
            border: Color(lightHex: 0xE1E4E8, darkHex: 0x25304A),
            divider: Color(lightHex: 0xE1E4E8, darkHex: 0x2E3B5A),
            textPrimary: textPrimary, textSecondary: textSecondary,
            accent: Color(lightHex: 0x2E6BE6, darkHex: 0x5B8DEF),
            gridLine: gridLine, bgLightHex: 0xFFFFFF, bgDarkHex: 0x0E1420,
            accentLightHex: 0x2E6BE6, accentDarkHex: 0x5B8DEF),
        .midnight: Palette(
            background: Color(lightHex: 0xFFFFFF, darkHex: 0x12122A),
            panel: Color(lightHex: 0xF4F3FA, darkHex: 0x1B1B38),
            border: Color(lightHex: 0xE4E1EE, darkHex: 0x2E2C55),
            divider: Color(lightHex: 0xE4E1EE, darkHex: 0x38356A),
            textPrimary: textPrimary, textSecondary: textSecondary,
            accent: Color(lightHex: 0x6D5FD6, darkHex: 0x9385F0),
            gridLine: gridLine, bgLightHex: 0xFFFFFF, bgDarkHex: 0x12122A,
            accentLightHex: 0x6D5FD6, accentDarkHex: 0x9385F0),
        .ember: Palette(
            background: Color(lightHex: 0xFFFBF8, darkHex: 0x1E1210),
            panel: Color(lightHex: 0xF7EFE9, darkHex: 0x2A1B16),
            border: Color(lightHex: 0xEBDED5, darkHex: 0x3E2A22),
            divider: Color(lightHex: 0xEBDED5, darkHex: 0x4A2E24),
            textPrimary: textPrimary, textSecondary: textSecondary,
            accent: Color(lightHex: 0xC0562E, darkHex: 0xE0793F),
            gridLine: gridLine, bgLightHex: 0xFFFBF8, bgDarkHex: 0x1E1210,
            accentLightHex: 0xC0562E, accentDarkHex: 0xE0793F),
        .mono: Palette(
            background: Color(lightHex: 0xFFFFFF, darkHex: 0x0E0E0E),
            panel: Color(lightHex: 0xF4F4F4, darkHex: 0x181818),
            border: Color(lightHex: 0xE2E2E2, darkHex: 0x2A2A2A),
            divider: Color(lightHex: 0xE2E2E2, darkHex: 0x333333),
            textPrimary: textPrimary, textSecondary: textSecondary,
            accent: Color(lightHex: 0x555555, darkHex: 0xAAAAAA),
            gridLine: gridLine, bgLightHex: 0xFFFFFF, bgDarkHex: 0x0E0E0E,
            accentLightHex: 0x555555, accentDarkHex: 0xAAAAAA),
        .cyberpunk: Palette(
            background: Color(lightHex: 0xFFFFFF, darkHex: 0x060A06),
            panel: Color(lightHex: 0xF1F7F2, darkHex: 0x0E160E),
            border: Color(lightHex: 0xDDE8DD, darkHex: 0x1C2A1C),
            divider: Color(lightHex: 0xDDE8DD, darkHex: 0x24361F),
            textPrimary: textPrimary, textSecondary: textSecondary,
            accent: Color(lightHex: 0x1FA81F, darkHex: 0x4CE44C),
            gridLine: gridLine, bgLightHex: 0xFFFFFF, bgDarkHex: 0x060A06,
            accentLightHex: 0x1FA81F, accentDarkHex: 0x4CE44C)
    ]
}

extension Color {
    /// A single 0xRRGGBB literal (used for mode-independent colors like the icon).
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    /// An adaptive color: `lightHex` in light appearance, `darkHex` in dark.
    init(lightHex: UInt32, darkHex: UInt32) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            NSColor(hex: appearance.isDark ? darkHex : lightHex)
        })
    }
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

extension NSAppearance {
    var isDark: Bool {
        bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }
}
