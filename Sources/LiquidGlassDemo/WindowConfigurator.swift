import SwiftUI
import AppKit

/// The window's vibrancy backdrop, and the bridge that reaches the hosting
/// `NSWindow` for settings SwiftUI doesn't expose (non-opaque/clear background,
/// appearance, titlebar accessories).
///
/// The `NSVisualEffectView` is placed in the root view's `.background`, so it sits
/// behind all SwiftUI content and composites reliably against SwiftUI's own layers
/// (an AppKit subview injected into the `NSHostingView` does not — it only lands
/// where macOS draws its default titlebar vibrancy). With `.behindWindow` blending
/// it frosts the desktop showing through wherever the SwiftUI content is
/// translucent. The material is currently baked in by the caller; passing `nil`
/// hides the effect view for an opaque window (kept for reuse).
///
/// The `version` value is read from observed state (the resolved appearance), so
/// the owning view re-runs `configure` when it changes — that's what live-updates
/// the window chrome on Light/Dark/System switches. When rendered without a window
/// (the `--snapshot` path uses `ImageRenderer`, which has no window), `view.window`
/// is nil and `configure` simply doesn't run — no crash.
struct WindowConfigurator: NSViewRepresentable {
    /// A value the caller reads from observed state (e.g. the appearance mode).
    /// Passing it here makes the owning view observe that state and re-run
    /// `configure` when it changes — without it, live updates like switching
    /// Light/Dark/System are never re-applied to the window.
    var version: AnyHashable = 0
    /// Vibrancy material to render behind the window, or `nil` for an opaque window.
    var material: NSVisualEffectView.Material?
    let configure: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        apply(from: view)
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        apply(from: nsView)
    }

    private func apply(from view: NSVisualEffectView) {
        if let material {
            view.material = material
            view.isHidden = false
        } else {
            view.isHidden = true
        }
        // Defer until the view is attached to its window.
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            configure(window)
        }
    }
}
