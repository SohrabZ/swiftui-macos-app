import OSLog

/// Structured logging, viewable in Console.app or via `log stream`. One
/// `Logger` per subsystem area so each can be filtered on its own
/// (`subsystem:com.sohrabz.LiquidGlassDemo category:updates`). The subsystem
/// matches the bundle id in `app.yml` — keep them in sync when renaming.
enum AppLog {
    private static let subsystem = "com.sohrabz.LiquidGlassDemo"

    /// App lifecycle (launch, activation).
    static let app = Logger(subsystem: subsystem, category: "app")
    /// Sparkle auto-updates.
    static let updates = Logger(subsystem: subsystem, category: "updates")
    /// Settings and preferences (launch at login, persistence).
    static let settings = Logger(subsystem: subsystem, category: "settings")
}
