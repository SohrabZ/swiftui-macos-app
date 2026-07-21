import Foundation

/// Localized demo-UI strings, read from the package resource bundle. SwiftUI's
/// `Text("…")` auto-localization only searches the *main* bundle, which a
/// SwiftPM executable doesn't have — this target's strings live in
/// `Resources/<lang>.lproj/Localizable.strings` (plain .strings files, because
/// command-line `swift build` copies .xcstrings without compiling them) and
/// load via `Bundle.module`. To localize another string, add it to each table
/// and expose it here.
enum L10n {
    /// The package resource bundle holding the compiled string catalog.
    static let bundle: Bundle = .module

    static let settings = String(localized: "Settings", bundle: bundle)
    static let launchAtLogin = String(localized: "Launch at Login", bundle: bundle)
    static let launchAtLoginHelp = String(
        localized: "Open LiquidGlassDemo automatically when you log in.", bundle: bundle)
    static let launchAtLoginUnavailable = String(
        localized: "Only available in the installed app.", bundle: bundle)
    static let theme = String(localized: "Theme", bundle: bundle)
    static let searchThemes = String(localized: "Search themes…", bundle: bundle)
    static let aboutTagline = String(
        localized: "A SwiftUI macOS app boilerplate — themed shell, settings, persistence, and Sparkle updates, wired and tested.",
        bundle: bundle)

    // First-run onboarding (OnboardingView).
    static let welcomeTitle = String(localized: "Welcome to LiquidGlassDemo", bundle: bundle)
    static let welcomeSubtitle = String(
        localized: "A themed SwiftUI shell for your next macOS app — here's the quick tour.",
        bundle: bundle)
    static let onboardingThemes = String(
        localized: "Six adaptive themes with Light/Dark/System", bundle: bundle)
    static let onboardingMenuBar = String(
        localized: "Menu bar quick access and keyboard shortcuts", bundle: bundle)
    static let onboardingUpdates = String(
        localized: "Sparkle auto-updates and launch at login", bundle: bundle)
    static let getStarted = String(localized: "Get Started", bundle: bundle)

    // Accessibility section (SettingsModal).
    static let accessibility = String(localized: "Accessibility", bundle: bundle)
    static let accessibilityHelp = String(
        localized: "Layered on top of the system settings.", bundle: bundle)
    static let reduceMotion = String(localized: "Reduce Motion", bundle: bundle)
    static let reduceTransparency = String(localized: "Reduce Transparency", bundle: bundle)
    static let increaseContrast = String(localized: "Increase Contrast", bundle: bundle)

    // Settings sections (SettingsSection) and their row help text.
    static let general = String(localized: "General", bundle: bundle)
    static let appearance = String(localized: "Appearance", bundle: bundle)
    static let generalHelp = String(
        localized: "Launch and login behavior.", bundle: bundle)
    static let appearanceHelp = String(
        localized: "Desktop display preferences.", bundle: bundle)
    static let themePickerHelp = String(
        localized: "The selected mode is applied on top of the palette.", bundle: bundle)
    static let reduceMotionHelp = String(
        localized: "Limit hover effects and panel animations.", bundle: bundle)
    static let reduceTransparencyHelp = String(
        localized: "Show solid surfaces instead of see-through glass.", bundle: bundle)
    static let increaseContrastHelp = String(
        localized: "Draw borders and separators in stronger colors.", bundle: bundle)
}
