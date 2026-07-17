import SwiftUI

/// Collapsible left column — transparent so the window tint/blur shows through
/// (empty for now).
struct LeftSidebar: View {
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Optional right column (hidden by default) — transparent, empty for now.
struct RightSidebar: View {
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
