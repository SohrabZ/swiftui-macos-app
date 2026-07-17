import SwiftUI

/// Opacity of the theme tint laid over the window's behind-window vibrancy in the
/// sidebars: high enough that the (dark) theme color dominates for a darker
/// sidebar, while a little of the frosted desktop still reads through.
private let sidebarTintOpacity: Double = 0.7

/// A collapsible side column — a translucent theme tint over the window vibrancy,
/// so it reads as themed chrome while the frosted desktop still shows through
/// (empty content for now). Used for both the left and right columns.
struct SidebarTint: View {
    @Environment(ThemeStore.self) private var theme

    var body: some View {
        theme.background.opacity(sidebarTintOpacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A draggable column separator. It reads as the same hairline divider at rest,
/// but carries a wider invisible hit area; hovering (or dragging) thickens the
/// line, tints it with the theme accent, and shows the column-resize pointer.
/// Dragging adjusts the adjacent sidebar's width within `Layout.sidebar*Width`.
struct ResizableColumnDivider: View {
    @Environment(ThemeStore.self) private var theme
    @Bindable var ui: UIState

    /// Which side the resized sidebar sits on, so a rightward drag grows the left
    /// sidebar but shrinks the right one.
    let edge: HorizontalEdge

    @State private var hovering = false
    @State private var dragStartWidth: CGFloat?

    private var active: Bool { hovering || dragStartWidth != nil }

    private var width: Binding<CGFloat> {
        edge == .leading ? $ui.leftSidebarWidth : $ui.rightSidebarWidth
    }

    var body: some View {
        // A 1pt divider line pinned to the boundary edge, inside a wider transparent
        // grab zone. This is overlaid on the (opaque) sidebar tint rather than laid
        // out as its own column, so no window frost shows through and the layout
        // gains no extra width. Hovering/dragging recolors the line to the accent.
        ZStack(alignment: edge == .leading ? .trailing : .leading) {
            Color.clear
            Rectangle()
                .fill(active ? theme.accent : theme.divider)
                .frame(width: Layout.hairline)
        }
        .frame(width: Layout.resizeHandleWidth)
        .contentShape(Rectangle())
        .ignoresSafeArea(edges: .bottom)
        .pointerStyle(.columnResize)
        .onHover { hovering = $0 }
        .gesture(
            // Measure in global space: the handle moves as the sidebar resizes,
            // so a local translation would feed back on itself and jitter.
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    let start = dragStartWidth ?? width.wrappedValue
                    if dragStartWidth == nil { dragStartWidth = start }
                    let delta = edge == .leading ? value.translation.width : -value.translation.width
                    width.wrappedValue = UIState.clampSidebar(start + delta)
                }
                .onEnded { _ in dragStartWidth = nil }
        )
        .animation(.easeInOut(duration: 0.12), value: active)
    }
}
