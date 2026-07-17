import SwiftUI
import AppKit

struct ContentView: View {
    let backdrop: MeshBackdrop
    let card: GlassCardModel

    @State private var hoverScale: CGFloat = GlassHover.resting
    @State private var model = TransparencyModel()
    @State private var ui = UIState()
    @State private var theme = ThemeStore()

    // Fixed card size so the frosted-backdrop mask aligns exactly with the card.
    private let cardWidth: CGFloat = 420
    private let cardHeight: CGFloat = 340

    init(backdrop: MeshBackdrop = .demo, card: GlassCardModel = .demo) {
        self.backdrop = backdrop
        self.card = card
    }

    var body: some View {
        appContent
        .animation(.easeInOut(duration: 0.22), value: ui.leftSidebarVisible)
        .animation(.easeInOut(duration: 0.22), value: ui.rightSidebarVisible)
        // Window-edge border in the same color as the header divider.
        .overlay {
            RoundedRectangle(cornerRadius: Radius.window, style: .continuous)
                .strokeBorder(theme.divider, lineWidth: Layout.hairline)
                .ignoresSafeArea()
        }
        // Settings modal.
        .overlay {
            if ui.showSettings {
                SettingsModal(model: model, ui: ui)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: ui.showSettings)
        // Explicit default pointer for the whole content so a `.link` (hand)
        // cursor from a header/modal control never lingers over the card/main
        // area. Interactive controls override this with their own pointer.
        .pointerStyle(.default)
        // Reading ui.mode here makes the body observe it (so configure re-runs)
        // and applies the Light/Dark/System scheme to the SwiftUI content.
        .preferredColorScheme(ui.mode.colorScheme)
        .background(
            // Passing windowAlpha makes the body observe it, so the slider
            // live-updates the window's opacity.
            WindowConfigurator(version: model.windowAlpha) { configure($0) }
        )
        // Injected once at the root so every descendant (including the modal
        // overlay and the themedBorder modifier) resolves the same theme.
        .environment(theme)
    }

    /// The app shell: a translucent tint over the behind-window blur, plus the
    /// header and three columns. Window Opacity fades the tint (not the content),
    /// so at <100% the blurred desktop shows through the sidebars/margins.
    private var appContent: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerStrip
                // Full-width divider row (spans above the sidebars AND main).
                Rectangle().fill(theme.divider).frame(height: Layout.hairline)
                HStack(spacing: 0) {
                    if ui.leftSidebarVisible {
                        LeftSidebar()
                            .frame(width: Layout.leftSidebarWidth)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        columnDivider
                    }

                    mainColumn

                    if ui.rightSidebarVisible {
                        columnDivider
                        RightSidebar()
                            .frame(width: Layout.rightSidebarWidth)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    private var columnDivider: some View {
        Rectangle().fill(theme.divider).frame(width: Layout.hairline).ignoresSafeArea(edges: .bottom)
    }

    /// Flat header strip (traffic lights and accessory buttons overlay it).
    private var headerStrip: some View {
        theme.background
            .frame(height: Layout.headerHeight)
            .frame(maxWidth: .infinity)
    }

    /// Center column: the glass hero card over the grid, inset with padding on
    /// all sides so the content doesn't touch the header, edges, or sidebars.
    private var mainColumn: some View {
        ZStack {
            backdropView                                     // sharp backdrop

            // A blurred copy of the SAME backdrop, masked to the card — so the
            // glass frosts exactly what's behind it (and it stays aligned with
            // the sharp backdrop around the card). Blur amount = the Blur slider.
            backdropView
                .blur(radius: model.blur)
                .mask {
                    // Scale the mask region with the hover so the frost grows in
                    // step with the card (the backdrop content itself isn't
                    // scaled, so it stays aligned with the sharp grid).
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .frame(width: cardWidth, height: cardHeight)
                        .scaleEffect(hoverScale)
                }

            cardView
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.content, style: .continuous))
        .themedBorder(Radius.content)
        .padding(Layout.mainInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Sharp mesh + grid backdrop for the main content area.
    private var backdropView: some View {
        ZStack {
            MeshGradient(
                width: backdrop.width,
                height: backdrop.height,
                points: backdrop.points,
                colors: backdrop.colors
            )
            GridPattern()
        }
    }

    /// The glass hero card: a tinted, bordered panel over the frosted backdrop.
    /// Card Opacity fades the tint (revealing more of the frost); the frost
    /// itself (behind it) is always present, so it never becomes plain glass.
    private var cardView: some View {
        VStack(spacing: 24) {
            Image(systemName: card.iconName)
                .font(.system(size: 64))
                .foregroundStyle(theme.accent)

            Text(card.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(theme.textPrimary)

            Text(card.subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 36)
        .frame(width: cardWidth, height: cardHeight)
        .background(
            // Tint scales the full 0→1 range: 100% = solid panel, lower reveals
            // the frosted backdrop behind it (glass), 0% = pure frost.
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(theme.panel.opacity(model.cardAlpha))
        )
        .themedBorder(Radius.card)
        .scaleEffect(hoverScale)
        .onHover { isHovering in
            withAnimation(.spring(duration: 0.3)) {
                hoverScale = GlassHover.scale(isHovering: isHovering)
            }
        }
    }

    /// Window chrome, transparency, and accessories.
    private func configure(_ window: NSWindow) {
        switch ui.mode {
        case .light: window.appearance = NSAppearance(named: .aqua)
        case .dark: window.appearance = NSAppearance(named: .darkAqua)
        case .system: window.appearance = nil
        }

        window.isOpaque = false
        window.backgroundColor = theme.backgroundNSColor
        window.titlebarAppearsTransparent = true
        window.alphaValue = model.windowAlpha   // clean, reliable window transparency

        window.titleVisibility = .hidden
        window.title = ""
        window.styleMask.insert([.titled, .resizable, .miniaturizable, .closable, .fullSizeContentView])
        window.titlebarSeparatorStyle = .none
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.standardWindowButton(.zoomButton)?.isEnabled = true

        // Install the header accessory buttons once.
        if !window.titlebarAccessoryViewControllers.contains(where: { $0 is HeaderAccessoryController }) {
            // The accessories are hosted in their own NSHostingViews, so the
            // environment must be injected into each rootView explicitly.
            window.addTitlebarAccessoryViewController(
                HeaderAccessoryController(edge: .leading, width: 44,
                                          content: AnyView(LeadingAccessoryView(ui: ui).environment(theme)))
            )
            window.addTitlebarAccessoryViewController(
                HeaderAccessoryController(edge: .trailing, width: 84,
                                          content: AnyView(TrailingAccessoryView(ui: ui).environment(theme)))
            )
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 1180, height: 760)
}
