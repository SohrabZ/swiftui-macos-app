import SwiftUI
import AppKit

/// Reaches the hosting `NSWindow` so we can apply window-level settings that
/// SwiftUI doesn't expose — here, making the window non-opaque with a clear
/// background and driving its overall `alphaValue`.
///
/// `configure` runs on every SwiftUI update, so binding it to `@State` (e.g. the
/// transparency slider) live-updates the real window. When rendered without a
/// window (the `--snapshot` path uses `ImageRenderer`, which has no window),
/// `view.window` is nil and the closure simply doesn't run — no crash.
struct WindowConfigurator: NSViewRepresentable {
    /// A value the caller reads from observed state (e.g. window alpha). Passing
    /// it here makes the owning view observe that state and re-run `configure`
    /// when it changes — without it, live updates like the opacity slider are
    /// never re-applied to the window.
    var version: Double = 0
    let configure: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        apply(from: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        apply(from: nsView)
    }

    private func apply(from view: NSView) {
        // Defer until the view is attached to its window.
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            configure(window)
        }
    }
}
