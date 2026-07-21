import SwiftUI

/// Corner radii used across the UI, named by role so they stay consistent.
enum Radius {
    static let control: CGFloat = 6   // icon-button hover, segmented pills
    static let row: CGFloat = 7       // settings nav row highlight
    static let field: CGFloat = 8     // search field, mode-picker track
    static let content: CGFloat = 12  // main content panel, theme cards
    static let panel: CGFloat = 16    // settings modal panel
    static let card: CGFloat = 24     // hero glass card
    static let window: CGFloat = 10   // window-edge border
}

/// Fixed layout metrics for the app shell.
enum Layout {
    static let headerHeight: CGFloat = 32
    static let leftSidebarWidth: CGFloat = 240   // default; user-resizable at runtime
    static let rightSidebarWidth: CGFloat = 280  // default; user-resizable at runtime
    static let mainInset: CGFloat = 20
    static let hairline: CGFloat = 1

    // User-resizable sidebar bounds and the drag handle straddling each column divider.
    static let sidebarMinWidth: CGFloat = 180
    static let sidebarMaxWidth: CGFloat = 420
    static let resizeHandleWidth: CGFloat = 10   // invisible hit area centered on the divider

    // Titlebar accessory hosting (see HeaderAccessory / ContentView.configure).
    static let accessoryHeight: CGFloat = 28
    static let leadingAccessoryWidth: CGFloat = 44
    static let trailingAccessoryWidth: CGFloat = 84

    // Chrome icon button (IconButton).
    static let iconButtonWidth: CGFloat = 26
    static let iconButtonHeight: CGFloat = 24

    // Hero card (HeroCard).
    static let heroDisc: CGFloat = 76  // gradient icon disc diameter
}

/// The UI type ramp. Named by role so the app's chrome stays consistent and a
/// single edit re-sizes every matching label/icon. (The hero card keeps semantic
/// system fonts like `.largeTitle`; these tokens cover the app chrome.)
enum Typography {
    static let title = Font.system(size: 18, weight: .semibold)   // modal title
    static let heading = Font.system(size: 14, weight: .semibold) // theme-card name
    static let label = Font.system(size: 13, weight: .semibold)   // section / row label
    static let body = Font.system(size: 13)                       // field text, nav row
    static let control = Font.system(size: 12, weight: .medium)   // segmented control, percent
    static let caption = Font.system(size: 12)                    // descriptions
    static let footnote = Font.system(size: 11)                   // help text
    static let badge = Font.system(size: 11, weight: .semibold)   // hero card theme badge

    // Icon sizes (applied to SF Symbols), matched to the labels they sit beside.
    static let iconHero = Font.system(size: 34, weight: .medium)  // hero card disc glyph
    static let iconLarge = Font.system(size: 14)
    static let icon = Font.system(size: 13)
    static let iconSmall = Font.system(size: 12)
    static let iconTiny = Font.system(size: 11)
}

/// `UserDefaults` keys for persisted settings, in one place.
enum Prefs {
    /// `NSWindow` frame-autosave name for the main window (AppKit owns the entry).
    static let mainWindowFrame = "MainWindow"
    static let cardOpacity = "lg.cardOpacity"
    static let leftSidebar = "lg.leftSidebar"
    static let rightSidebar = "lg.rightSidebar"
    static let leftSidebarWidth = "lg.leftSidebarWidth"
    static let rightSidebarWidth = "lg.rightSidebarWidth"
    static let mode = "lg.mode"
    static let theme = "lg.theme"
    static let blur = "lg.blur"
    static let hasCompletedOnboarding = "lg.hasCompletedOnboarding"
    static let reduceMotion = "lg.reduceMotion"
    static let reduceTransparency = "lg.reduceTransparency"
    static let increaseContrast = "lg.increaseContrast"
}

extension EnvironmentValues {
    /// In-app accessibility overrides, pushed from `ContentView`. Defaults are
    /// off so previews and secondary windows don't need to inject anything.
    @Entry var reduceTransparencyOverride = false
    @Entry var increaseContrastOverride = false
}

/// Strokes a continuous rounded-rectangle border. Implemented as a `ViewModifier`
/// (rather than a `View` extension with a `Theme.border` default argument) so it
/// can read the current `ThemeStore` from the environment — a default argument
/// couldn't, which is what previously forced `Theme` to be a global.
private struct ThemedBorder: ViewModifier {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.increaseContrastOverride) private var increaseContrastOverride
    let radius: CGFloat
    let color: Color?
    let width: CGFloat

    func body(content: Content) -> some View {
        // Under Increase Contrast (system or in-app override) the default border
        // swaps to the stronger text color; explicit colors stay as passed.
        let increased = colorSchemeContrast == .increased || increaseContrastOverride
        let stroke = color ?? (increased ? theme.textSecondary : theme.border)
        content.overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(stroke, lineWidth: width)
        )
    }
}

extension View {
    /// Strokes a continuous rounded-rectangle border (defaults to the theme border).
    func themedBorder(_ radius: CGFloat, color: Color? = nil, width: CGFloat = 1) -> some View {
        modifier(ThemedBorder(radius: radius, color: color, width: width))
    }
}

extension UserDefaults {
    /// Reads a `Double` only when a value is actually stored (so callers can keep
    /// their own default instead of `double(forKey:)`'s implicit `0`).
    func optionalDouble(forKey key: String) -> Double? {
        object(forKey: key) == nil ? nil : double(forKey: key)
    }

    /// Reads a `Bool` only when a value is actually stored.
    func optionalBool(forKey key: String) -> Bool? {
        object(forKey: key) == nil ? nil : bool(forKey: key)
    }
}
