import SwiftUI

/// Light / Dark / System appearance mode.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }

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
final class UIState {
    var leftSidebarVisible = true {
        didSet { UserDefaults.standard.set(leftSidebarVisible, forKey: Prefs.leftSidebar) }
    }
    var rightSidebarVisible = false {
        didSet { UserDefaults.standard.set(rightSidebarVisible, forKey: Prefs.rightSidebar) }
    }
    var mode: AppearanceMode = .dark {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Prefs.mode) }
    }
    var showSettings = false

    init() {
        let defaults = UserDefaults.standard
        if let v = defaults.optionalBool(forKey: Prefs.leftSidebar) { leftSidebarVisible = v }
        if let v = defaults.optionalBool(forKey: Prefs.rightSidebar) { rightSidebarVisible = v }
        if let raw = defaults.string(forKey: Prefs.mode), let m = AppearanceMode(rawValue: raw) {
            mode = m
        }
    }
}
