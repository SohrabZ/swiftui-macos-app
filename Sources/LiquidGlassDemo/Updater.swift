import SwiftUI
import Combine
import Sparkle

/// Wraps Sparkle's standard updater for direct-download auto-updates.
///
/// The updater only starts inside a signed `.app` bundle that declares an
/// `SUFeedURL` in its `Info.plist` (see `scripts/build_app.sh` and RELEASE.md).
/// Under `swift run` there is no bundle and no feed URL, so the controller is never
/// created — `checkForUpdates()` is a no-op and the menu item stays disabled. That
/// keeps development and the `--snapshot`/`--icon` CLI paths free of Sparkle.
@MainActor
final class Updater: ObservableObject {
    /// Mirrors `SPUUpdater.canCheckForUpdates` so the menu item can bind to it.
    @Published private(set) var canCheckForUpdates = false

    private let controller: SPUStandardUpdaterController?

    init() {
        if Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil {
            let controller = SPUStandardUpdaterController(
                startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
            self.controller = controller
            controller.updater.publisher(for: \.canCheckForUpdates)
                .assign(to: &$canCheckForUpdates)
        } else {
            controller = nil
        }
    }

    /// Shows Sparkle's "check for updates" UI. No-op outside a configured bundle.
    func checkForUpdates() {
        controller?.updater.checkForUpdates()
    }
}
