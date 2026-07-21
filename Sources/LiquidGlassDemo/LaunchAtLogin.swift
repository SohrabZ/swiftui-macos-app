import Foundation
import ServiceManagement

/// Launch-at-login state, backed by `SMAppService`. Registration needs a
/// packaged `.app` bundle — under `swift run` the toggle is disabled and
/// `setEnabled` is a no-op (same philosophy as the Sparkle guard in `Updater`).
@Observable
@MainActor
final class LaunchAtLogin {
    /// False outside a packaged `.app` bundle — there's nothing to register.
    let available: Bool
    private(set) var enabled = false

    init() {
        available = Bundle.main.bundleURL.pathExtension == "app"
        if available {
            enabled = SMAppService.mainApp.status == .enabled
        }
    }

    /// Registers or unregisters the login item, then re-reads the real status —
    /// the source of truth, since it can also change from System Settings.
    /// Failures are logged and surfaced through `errors` when given.
    func setEnabled(_ newValue: Bool, reporting errors: ErrorStore? = nil) {
        guard available, newValue != enabled else { return }
        do {
            if newValue {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            AppLog.settings.error("Launch at Login update failed: \(error.localizedDescription, privacy: .public)")
            errors?.present(title: "Launch at Login", message: error.localizedDescription)
        }
        enabled = SMAppService.mainApp.status == .enabled
    }
}
