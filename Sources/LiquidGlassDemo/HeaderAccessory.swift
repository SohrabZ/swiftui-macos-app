import SwiftUI
import AppKit

/// Hosts a SwiftUI view as a native titlebar accessory (chrome-free), on the
/// leading or trailing edge — so header icons sit on the traffic-light row.
final class HeaderAccessoryController: NSTitlebarAccessoryViewController {
    init(edge: NSLayoutConstraint.Attribute, width: CGFloat, content: AnyView) {
        super.init(nibName: nil, bundle: nil)
        layoutAttribute = edge
        let hosting = NSHostingView(rootView: content)
        hosting.frame = NSRect(x: 0, y: 0, width: width, height: Layout.accessoryHeight)
        view = hosting
    }

    required init?(coder: NSCoder) { fatalError("not used") }
}

/// Leading accessory: the collapsible-sidebar toggle (right of the traffic lights).
struct LeadingAccessoryView: View {
    @Bindable var ui: UIState

    var body: some View {
        // Neutral state (no persistent highlight); tooltip reflects the action.
        IconButton(systemName: "rectangle.lefthalf.inset.filled",
                   tooltip: ui.leftSidebarVisible ? "Hide sidebar" : "Show sidebar") {
            ui.leftSidebarVisible.toggle()
        }
        .padding(.leading, 6)
    }
}

/// Trailing accessory: the settings cog and the right-panel toggle (rightmost).
struct TrailingAccessoryView: View {
    @Bindable var ui: UIState

    var body: some View {
        HStack(spacing: 2) {
            IconButton(systemName: "gearshape",
                       tooltip: "Open settings") {
                ui.showSettings.toggle()
            }
            IconButton(systemName: "rectangle.righthalf.inset.filled",
                       tooltip: ui.rightSidebarVisible ? "Hide panel" : "Show panel") {
                ui.rightSidebarVisible.toggle()
            }
        }
        .padding(.trailing, 8)
    }
}
