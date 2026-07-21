import AppKit

/// Inputs for the debug-info report, already resolved to plain values so the
/// report builder stays pure (and testable) — only the pasteboard write and
/// the live-state gathering touch the system.
struct DebugContext: Equatable {
    var appVersion: String
    var macOSVersion: String
    var theme: String
    var appearance: String
    var cardOpacityPercent: Int
    var cardBlurPercent: Int
    var launchAtLogin: String
    var updates: String
}

/// The Help ▸ Copy Debug Info report: everything a bug report needs, flattened
/// to plain text for pasting into an issue.
enum DebugInfo {
    /// Assembles the report from already-resolved values.
    static func report(_ c: DebugContext) -> String {
        """
        \(AppInfo.name) \(c.appVersion)
        macOS \(c.macOSVersion)
        Theme: \(c.theme) · Appearance: \(c.appearance)
        Card Opacity: \(c.cardOpacityPercent)% · Card Blur: \(c.cardBlurPercent)%
        Launch at Login: \(c.launchAtLogin)
        Updates: \(c.updates)
        """
    }

    /// Gathers live app state and copies the report to the pasteboard.
    @MainActor
    static func copyToPasteboard(theme: ThemeStore, ui: UIState, model: TransparencyModel,
                                 sparkle: Bool) {
        let loginItem = LaunchAtLogin()
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let context = DebugContext(
            appVersion: AppInfo.versionString,
            macOSVersion: "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)",
            theme: ThemeSwatch.name(for: theme.id),
            appearance: ui.mode.rawValue,
            cardOpacityPercent: OpacityControl.card.percent(model.cardOpacity),
            cardBlurPercent: model.blurPercent,
            launchAtLogin: loginItem.available ? (loginItem.enabled ? "enabled" : "disabled")
                                               : "unavailable (dev run)",
            updates: sparkle ? "Sparkle" : "disabled (dev run)"
        )
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report(context), forType: .string)
        AppLog.app.info("Copied debug info to the pasteboard")
    }
}
