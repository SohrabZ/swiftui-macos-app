import SwiftUI

/// A vertical ScrollView with a custom thin scrollbar: the native scroller is
/// hidden and replaced by a slim rounded thumb that reflects scroll position,
/// brightens on hover/drag, is draggable, and only appears when content overflows.
struct ScrollableContent<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @Environment(ThemeStore.self) private var theme
    @State private var scrollPos = ScrollPosition(edge: .top)
    @State private var offsetY: CGFloat = 0
    @State private var contentH: CGFloat = 0
    @State private var containerH: CGFloat = 0
    @State private var hovering = false
    @State private var dragging = false

    var body: some View {
        ScrollView {
            content()
        }
        .scrollIndicators(.never)
        .scrollPosition($scrollPos)
        .onScrollGeometryChange(for: Metrics.self) { geo in
            Metrics(offset: geo.contentOffset.y,
                    content: geo.contentSize.height,
                    container: geo.containerSize.height)
        } action: { _, m in
            offsetY = m.offset
            contentH = m.content
            containerH = m.container
        }
        .overlay(alignment: .trailing) { scrollbar }
    }

    private var scrollbar: some View {
        GeometryReader { geo in
            let trackH = geo.size.height
            let visibleRatio = contentH > 0 ? min(1, containerH / contentH) : 1
            let maxOffset = max(0, contentH - containerH)

            if visibleRatio < 1 {
                // Reflects the visible ratio, within a comfortable min/max height.
                let thumbH = min(130, max(64, trackH * visibleRatio))
                let progress = maxOffset > 0 ? min(1, max(0, offsetY / maxOffset)) : 0
                let thumbCenterY = (trackH - thumbH) * progress + thumbH / 2

                Capsule()
                    .fill(theme.textSecondary.opacity(hovering || dragging ? 0.55 : 0.30))
                    .frame(width: 6, height: thumbH)
                    .position(x: geo.size.width - 7, y: thumbCenterY)
                    .contentShape(Rectangle())
                    .onHover { hovering = $0 }
                    .gesture(
                        DragGesture(coordinateSpace: .named("scrollTrack"))
                            .onChanged { value in
                                dragging = true
                                let p = (value.location.y - thumbH / 2) / max(1, trackH - thumbH)
                                scrollPos.scrollTo(y: max(0, min(1, p)) * maxOffset)
                            }
                            .onEnded { _ in dragging = false }
                    )
                    .animation(.easeOut(duration: 0.15), value: hovering)
            }
        }
        .frame(width: 14)
        .coordinateSpace(.named("scrollTrack"))
    }

    private struct Metrics: Equatable {
        let offset: CGFloat
        let content: CGFloat
        let container: CGFloat
    }
}
