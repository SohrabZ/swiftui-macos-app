import SwiftUI
import AppKit

struct ContentView: View {
    let backdrop: MeshBackdrop
    let card: GlassCardModel

    @State private var hoverScale: CGFloat = GlassHover.resting
    @State private var model = TransparencyModel()
    @State private var ui = UIState()
    @State private var theme = ThemeStore()
    @State private var systemAppearance = SystemAppearance()

    // Fixed card size so the frosted-backdrop mask aligns exactly with the card.
    private let cardWidth: CGFloat = 420
    private let cardHeight: CGFloat = 340

    /// The window's behind-window vibrancy material. Baked in (no longer user-
    /// selectable): the desktop frosts through the side margins and sidebars while
    /// the titlebar and content stay solid.
    private static let windowMaterial: NSVisualEffectView.Material = .sidebar

    init(backdrop: MeshBackdrop = .demo, card: GlassCardModel = .demo) {
        self.backdrop = backdrop
        self.card = card
    }

    /// The concrete color scheme to render: the picked Light/Dark, or the live OS
    /// scheme under System. Never nil, so reverting to System actually reverts.
    private var effectiveScheme: ColorScheme {
        switch ui.mode {
        case .light: .light
        case .dark: .dark
        case .system: systemAppearance.colorScheme
        }
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
        // Drives the SwiftUI content's color scheme. `.system` resolves to the
        // real OS scheme (never nil), so switching back to System reverts cleanly.
        .preferredColorScheme(effectiveScheme)
        .background(
            // Passing the resolved scheme as the version makes the body observe it,
            // so `configure` re-runs (updating the window chrome appearance) on every
            // mode change and whenever the system appearance flips under System mode.
            WindowConfigurator(version: effectiveScheme, material: Self.windowMaterial) { configure($0) }
        )
        // Injected once at the root so every descendant (including the modal
        // overlay and the themedBorder modifier) resolves the same theme.
        .environment(theme)
    }

    /// The app shell: the themed fill over the behind-window vibrancy, plus the
    /// header and three columns. When a Window Material is picked the fill drops
    /// to clear, so the frosted desktop shows through the sidebars/margins/header.
    private var appContent: some View {
        ZStack {
            // Clear so the window's vibrancy material frosts the desktop through the
            // side margins and sidebars. The header/titlebar and content paint their
            // own solid fills on top.
            Color.clear
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerStrip
                // Full-width divider row (spans above the sidebars AND main).
                Rectangle().fill(theme.divider).frame(height: Layout.hairline)
                HStack(spacing: 0) {
                    if ui.leftSidebarVisible {
                        SidebarTint()
                            .frame(width: Layout.leftSidebarWidth)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        columnDivider
                    }

                    mainColumn

                    if ui.rightSidebarVisible {
                        columnDivider
                        SidebarTint()
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

    /// Flat header strip (traffic lights and accessory buttons overlay it). Always
    /// the solid theme fill — the titlebar stays opaque even when a Window Material
    /// frosts the rest of the chrome behind it.
    private var headerStrip: some View {
        theme.background
            .frame(height: Layout.headerHeight)
            .frame(maxWidth: .infinity)
    }

    /// Center column: the glass hero card over the grid. The backdrop fills the
    /// whole column edge-to-edge (opaque — no window frost shows through here);
    /// only the sidebars carry the translucent vibrancy.
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
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
        // Match the window chrome to the resolved scheme. Under System this follows
        // the live OS setting, so it reverts correctly when switching back from
        // a forced Light/Dark.
        window.appearance = NSAppearance(named: effectiveScheme == .dark ? .darkAqua : .aqua)

        window.isOpaque = false
        // Clear background lets the behind-window vibrancy view frost the desktop.
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.alphaValue = 1

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
                HeaderAccessoryController(edge: .leading, width: Layout.leadingAccessoryWidth,
                                          content: AnyView(LeadingAccessoryView(ui: ui).environment(theme)))
            )
            window.addTitlebarAccessoryViewController(
                HeaderAccessoryController(edge: .trailing, width: Layout.trailingAccessoryWidth,
                                          content: AnyView(TrailingAccessoryView(ui: ui).environment(theme)))
            )
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 1180, height: 760)
}
