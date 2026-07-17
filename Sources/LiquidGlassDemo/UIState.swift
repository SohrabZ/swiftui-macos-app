import SwiftUI
import AppKit

/// Tracks the OS-level Light/Dark setting so `.system` mode can resolve to a
/// concrete `ColorScheme`. Resolving it ourselves — instead of relying on
/// `.preferredColorScheme(nil)` — sidesteps a SwiftUI bug where switching back to
/// System from a forced Light/Dark fails to revert. Updates live when the user
/// flips the system appearance (KVO on the app's effective appearance, which
/// tracks the system since we only ever force per-*window* appearances).
@Observable
@MainActor
final class SystemAppearance {
    private(set) var colorScheme: ColorScheme = SystemAppearance.resolve()

    @ObservationIgnored private var observation: NSKeyValueObservation?

    init() {
        observation = NSApplication.shared.observe(\.effectiveAppearance) { [weak self] _, _ in
            Task { @MainActor in self?.colorScheme = SystemAppearance.resolve() }
        }
    }

    static func resolve() -> ColorScheme {
        NSApplication.shared.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? .dark : .light
    }
}

/// Light / Dark / System appearance mode.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .light: "sun.max"
        case .dark: "moon"
        case .system: "desktopcomputer"
        }
    }
}

/// App-shell UI state shared between the window content and the titlebar
/// accessory buttons (sidebar toggles + settings). Sidebar visibility and the
/// appearance mode are persisted to `UserDefaults`; `showSettings` is transient.
@Observable
@MainActor
final class UIState {
    var leftSidebarVisible = true {
        didSet { UserDefaults.standard.set(leftSidebarVisible, forKey: Prefs.leftSidebar) }
    }
    var rightSidebarVisible = false {
        didSet { UserDefaults.standard.set(rightSidebarVisible, forKey: Prefs.rightSidebar) }
    }
    var leftSidebarWidth: CGFloat = Layout.leftSidebarWidth {
        didSet { UserDefaults.standard.set(Double(leftSidebarWidth), forKey: Prefs.leftSidebarWidth) }
    }
    var rightSidebarWidth: CGFloat = Layout.rightSidebarWidth {
        didSet { UserDefaults.standard.set(Double(rightSidebarWidth), forKey: Prefs.rightSidebarWidth) }
    }
    var mode: AppearanceMode = .dark {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Prefs.mode) }
    }
    var showSettings = false

    init() {
        let defaults = UserDefaults.standard
        if let v = defaults.optionalBool(forKey: Prefs.leftSidebar) { leftSidebarVisible = v }
        if let v = defaults.optionalBool(forKey: Prefs.rightSidebar) { rightSidebarVisible = v }
        if let w = defaults.optionalDouble(forKey: Prefs.leftSidebarWidth) {
            leftSidebarWidth = Self.clampSidebar(CGFloat(w))
        }
        if let w = defaults.optionalDouble(forKey: Prefs.rightSidebarWidth) {
            rightSidebarWidth = Self.clampSidebar(CGFloat(w))
        }
        if let raw = defaults.string(forKey: Prefs.mode), let m = AppearanceMode(rawValue: raw) {
            mode = m
        }
    }

    /// Confines a sidebar width to the resizable bounds.
    static func clampSidebar(_ width: CGFloat) -> CGFloat {
        min(max(width, Layout.sidebarMinWidth), Layout.sidebarMaxWidth)
    }
}
