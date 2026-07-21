import SwiftUI

/// The one place to surface errors: features call `present(title:message:)`,
/// and a single `.alert` in `ContentView` displays whatever was presented.
/// Injected through the environment so any view can reach it. This keeps error
/// presentation consistent instead of scattering ad-hoc alerts across features.
@Observable
@MainActor
final class ErrorStore {
    /// The error currently being displayed, if any.
    private(set) var current: PresentedError?

    struct PresentedError: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let message: String
    }

    /// Logs the error and shows it in the app-wide alert.
    func present(title: String, message: String) {
        AppLog.app.error("\(title, privacy: .public): \(message, privacy: .public)")
        current = PresentedError(title: title, message: message)
    }

    func dismiss() { current = nil }
}
