import SwiftUI
import AppKit

struct ContentView: View {
    let backdrop: MeshBackdrop
    let card: GlassCardModel

    @State private var hoverScale: CGFloat = GlassHover.resting
    @State private var model = TransparencyModel()
    @State private var ui: UIState
    @State private var systemAppearance = SystemAppearance()
    @State private var errors = ErrorStore()
    @State private var a11y = AccessibilitySettings()
    // Owned by LiquidGlassDemoApp and shared with the MenuBarExtra scene, so a
    // theme switch from the tray recolors this window live.
    @Environment(ThemeStore.self) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // Fixed card size lives on HeroCard so the frosted-backdrop mask aligns
    // exactly with the card.

    /// The window's behind-window vibrancy material: the desktop frosts through the
    /// side margins and sidebars while the titlebar and content stay solid. Defaults
    /// to `.sidebar`; `--snapshot` passes `nil` to disable it so offscreen renders
    /// don't sample the live desktop through the translucent chrome.
    let windowMaterial: NSVisualEffectView.Material?

    init(backdrop: MeshBackdrop = .demo, card: GlassCardModel = .demo,
         windowMaterial: NSVisualEffectView.Material? = .sidebar,
         showsOnboarding: Bool = true) {
        self.backdrop = backdrop
        self.card = card
        self.windowMaterial = windowMaterial
        // `--snapshot` passes showsOnboarding: false so renders capture the shell.
        _ui = State(initialValue: UIState(showsOnboarding: showsOnboarding))
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

    /// Reduce Motion / Transparency as the system setting OR the in-app override.
    private var effectiveReduceMotion: Bool {
        GlassA11y.effective(system: reduceMotion, override: a11y.reduceMotion)
    }
    private var effectiveReduceTransparency: Bool {
        GlassA11y.effective(system: reduceTransparency, override: a11y.reduceTransparency)
    }

    /// Real Liquid Glass on the live window when the OS supports it. The
    /// `--snapshot` path (`windowMaterial == nil`) always uses the fallback stack
    /// so offscreen `ImageRenderer` output stays deterministic.
    private var nativeGlass: Bool {
        if #available(macOS 26, *) { return windowMaterial != nil }
        return false
    }

    var body: some View {
        appContent
        .animation(effectiveReduceMotion ? nil : .easeInOut(duration: 0.22), value: ui.leftSidebarVisible)
        .animation(effectiveReduceMotion ? nil : .easeInOut(duration: 0.22), value: ui.rightSidebarVisible)
        // Window-edge border in the same color as the header divider.
        .overlay {
            RoundedRectangle(cornerRadius: Radius.window, style: .continuous)
                .strokeBorder(theme.divider, lineWidth: Layout.hairline)
                .ignoresSafeArea()
        }
        // Settings modal.
        .overlay {
            if ui.showSettings {
                SettingsModal(model: model, ui: ui, a11y: a11y)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: ui.showSettings)
        // First-run onboarding (shows once; see UIState.completeOnboarding).
        .overlay {
            if ui.showOnboarding {
                OnboardingView(ui: ui)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: ui.showOnboarding)
        // Publish shell state to the menu-bar commands (ShellCommands) — they're
        // scene-level, so they can't see this view's @State directly.
        .focusedSceneValue(\.uiState, ui)
        .focusedSceneValue(\.transparencyModel, model)
        .focusedSceneValue(\.accessibilitySettings, a11y)
        // In-app a11y overrides for views too deep to receive the model directly.
        .environment(\.reduceTransparencyOverride, a11y.reduceTransparency)
        .environment(\.increaseContrastOverride, a11y.increaseContrast)
        // The app-wide error surface (see ErrorStore) — one alert for all features.
        .environment(errors)
        .alert(errors.current?.title ?? "", isPresented: Binding(
            get: { errors.current != nil },
            set: { if !$0 { errors.dismiss() } }
        )) {
            Button("OK") { errors.dismiss() }
        } message: {
            if let current = errors.current { Text(current.message) }
        }
        // Deep links (liquidglassdemo://…) — the scheme is registered only in
        // the packaged app's Info.plist, so this never fires under `swift run`.
        .onOpenURL(perform: handle)
        // Explicit default pointer for the whole content so a `.link` (hand)
        // cursor from a header/modal control never lingers over the card/main
        // area. Interactive controls override this with their own pointer.
        .pointerStyle(.default)
        // Drives the SwiftUI content's color scheme. `.system` resolves to the
        // real OS scheme (never nil), so switching back to System reverts cleanly.
        .preferredColorScheme(effectiveScheme)
        .background {
            // Passing the resolved scheme as the version makes the body observe it,
            // so `configure` re-runs (updating the window chrome appearance) on every
            // mode change and whenever the system appearance flips under System mode.
            // With no material (the `--snapshot` path) the vibrancy view is omitted
            // entirely — `ImageRenderer` renders even a hidden `NSVisualEffectView`,
            // sampling the live desktop, so it must not be in the tree at all.
            if let windowMaterial {
                WindowConfigurator(version: effectiveScheme, material: windowMaterial) { configure($0) }
            }
        }
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
                            .frame(width: ui.leftSidebarWidth)
                            .overlay { SidebarThemes() }
                            .overlay(alignment: .trailing) {
                                ResizableColumnDivider(ui: ui, edge: .leading)
                            }
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    mainColumn

                    if ui.rightSidebarVisible {
                        SidebarTint()
                            .frame(width: ui.rightSidebarWidth)
                            .overlay { SidebarInspector(model: model, ui: ui) }
                            .overlay(alignment: .leading) {
                                ResizableColumnDivider(ui: ui, edge: .trailing)
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    /// Flat header strip (traffic lights and accessory buttons overlay it). Always
    /// the solid theme fill — the titlebar stays opaque even when a Window Material
    /// frosts the rest of the chrome behind it.
    private var headerStrip: some View {
        theme.background
            .frame(height: Layout.headerHeight)
            .frame(maxWidth: .infinity)
            .overlay {
                Text("Liquid Glass")
                    .font(Typography.label)
                    .foregroundStyle(theme.textSecondary)
            }
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
                .blur(radius: GlassA11y.blur(model.blur, reduceTransparency: effectiveReduceTransparency))
                .mask {
                    // Scale the mask region with the fallback hover so the frost
                    // grows in step with the card. Real glass (macOS 26) responds
                    // natively via `.interactive()`, so no scale is applied then.
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .frame(width: HeroCard.width, height: HeroCard.height)
                        .scaleEffect(nativeGlass ? 1 : hoverScale)
                }

            // Card Opacity tint, painted as its own layer UNDER the card surface.
            // On the native-glass path this is what keeps the slider visibly
            // effective: `.regular` glass frosts over any tint baked into it, so
            // the tint lives here instead, showing through the clear glass. It
            // also casts the card's shadow, which a transparent glass surface
            // can't do on its own.
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(theme.panel.opacity(GlassA11y.cardAlpha(model.cardAlpha,
                                                              reduceTransparency: effectiveReduceTransparency)))
                .frame(width: HeroCard.width, height: HeroCard.height)
                .scaleEffect(nativeGlass ? 1 : hoverScale)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.5 : 0.18),
                        radius: 30, y: 14)

            HeroCard(card: card, ui: ui, nativeGlass: nativeGlass)
                .scaleEffect(nativeGlass ? 1 : hoverScale)
                .onHover { isHovering in
                    guard !nativeGlass else { return }
                    withAnimation(effectiveReduceMotion ? nil : .spring(duration: 0.3)) {
                        hoverScale = GlassHover.scale(isHovering: isHovering)
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    /// Sharp mesh + grid backdrop for the main content area, recolored to the
    /// active theme so a theme switch transforms the hero area too.
    private var backdropView: some View {
        ZStack {
            MeshGradient(
                width: themedBackdrop.width,
                height: themedBackdrop.height,
                points: themedBackdrop.points,
                colors: themedBackdrop.colors
            )
            GridPattern()
        }
    }

    private var themedBackdrop: MeshBackdrop {
        backdrop.tinted(with: theme.palette)
    }

    /// Routes a deep link (e.g. `liquidglassdemo://theme/ember`) to app state.
    private func handle(_ url: URL) {
        guard let link = DeepLink(url: url) else {
            AppLog.app.warning("Ignoring unrecognized deep link: \(url.absoluteString, privacy: .public)")
            return
        }
        AppLog.app.notice("Deep link: \(String(describing: link), privacy: .public)")
        switch link {
        case .theme(let id): theme.id = id
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

        // Persist the window frame (position + size) across launches; the saved
        // frame wins over the scene's defaultSize on later opens. Set once —
        // configure re-runs on every appearance change.
        if window.frameAutosaveName.isEmpty {
            window.setFrameUsingName(Prefs.mainWindowFrame, force: true)
            window.setFrameAutosaveName(Prefs.mainWindowFrame)
        }

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
    ContentView(showsOnboarding: false)
        .frame(width: 1180, height: 760)
        .environment(ThemeStore())
}
