import Foundation

/// A deep link into the app (`liquidglassdemo://...`). Parsed as pure data so
/// routing stays unit-testable; `ContentView` handles incoming URLs via
/// `.onOpenURL`. The scheme is registered only in the packaged app's
/// Info.plist (`url_scheme` in app.yml), so links do nothing under `swift run`.
enum DeepLink: Equatable {
    /// `liquidglassdemo://theme/<id>` — switch the active theme.
    case theme(ThemeID)

    /// The URL scheme the packaged app registers (keep in sync with app.yml).
    static let scheme = "liquidglassdemo"

    init?(url: URL) {
        guard url.scheme == Self.scheme, let host = url.host() else { return nil }
        switch host {
        case "theme":
            // liquidglassdemo://theme/ember → pathComponents ["/", "ember"]
            guard let raw = url.pathComponents.dropFirst().first,
                  let id = ThemeID(rawValue: raw) else { return nil }
            self = .theme(id)
        default:
            return nil
        }
    }
}
