import SwiftUI

/// Opacity of the theme tint laid over the window's behind-window vibrancy in the
/// sidebars: high enough that the (dark) theme color dominates for a darker
/// sidebar, while a little of the frosted desktop still reads through.
private let sidebarTintOpacity: Double = 0.7

/// Collapsible left column — a translucent theme tint over the window vibrancy, so
/// it reads as themed chrome while the frosted desktop still shows through (empty
/// for now).
struct LeftSidebar: View {
    @Environment(ThemeStore.self) private var theme

    var body: some View {
        theme.background.opacity(sidebarTintOpacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Optional right column (hidden by default) — same translucent theme tint.
struct RightSidebar: View {
    @Environment(ThemeStore.self) private var theme

    var body: some View {
        theme.background.opacity(sidebarTintOpacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
