import SwiftUI

/// The glass hero card: theme badge, gradient icon disc, title, subtitle, and
/// actions. The card's tint and shadow are painted underneath by `ContentView`
/// (see `mainColumn`), so the Card Opacity/Blur sliders drive real pixels on
/// every OS. On macOS 26 the surface is clear native Liquid Glass
/// (`.clear.interactive()`) — it contributes the glass edge, light response, and
/// hover/press physics without frosting over the tint/blur layers beneath
/// (`.regular` glass washes both out, which made the sliders appear dead).
/// Below macOS 26 the surface is a border plus a top edge highlight.
struct HeroCard: View {
    let card: GlassCardModel
    let ui: UIState
    /// True when the real glass effect may be used (live window on macOS 26).
    /// The `--snapshot` path passes false so offscreen renders stay deterministic.
    let nativeGlass: Bool

    @Environment(ThemeStore.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    // Fixed card size so ContentView's frosted-backdrop mask aligns exactly.
    static let width: CGFloat = 440
    static let height: CGFloat = 400

    var body: some View {
        if #available(macOS 26, *), nativeGlass {
            content
                .frame(width: Self.width, height: Self.height)
                .glassEffect(.clear.interactive(), in: .rect(cornerRadius: Radius.card))
        } else {
            content
                .frame(width: Self.width, height: Self.height)
                .themedBorder(Radius.card)
                .overlay { edgeHighlight }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            badge
            iconDisc
                .padding(.top, 20)
            Text(card.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(theme.textPrimary)
                .padding(.top, 18)
            Text(card.subtitle)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            actions
                .padding(.top, 24)
        }
        .padding(.horizontal, 36)
    }

    /// The current theme's name as a small accent capsule — ties the card to the
    /// active theme.
    private var badge: some View {
        Text(ThemeSwatch.name(for: theme.id).uppercased())
            .font(Typography.badge)
            .tracking(0.6)
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(theme.accent.opacity(0.12)))
            .overlay(Capsule().strokeBorder(theme.accent.opacity(0.35), lineWidth: Layout.hairline))
    }

    private var iconDisc: some View {
        Image(systemName: card.iconName)
            .font(Typography.iconHero)
            .foregroundStyle(.white)
            .frame(width: Layout.heroDisc, height: Layout.heroDisc)
            .background(
                Circle().fill(
                    LinearGradient(colors: [theme.accent, theme.accent.opacity(0.75)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            )
            .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: Layout.hairline))
            .shadow(color: theme.accent.opacity(0.35), radius: 12, y: 6)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button { ui.showSettings = true } label: {
                Label("Customize…", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)

            Button { ui.rightSidebarVisible.toggle() } label: {
                Label(ui.rightSidebarVisible ? "Hide Inspector" : "Show Inspector",
                      systemImage: "sidebar.right")
            }
            .buttonStyle(.bordered)
        }
        .controlSize(.large)
        .pointerStyle(.link)
    }

    /// Top inner highlight — the bright rim that sells the glass edge on the
    /// fallback path (real glass draws its own edge on macOS 26).
    private var edgeHighlight: some View {
        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(colorScheme == .dark ? 0.28 : 0.7),
                             .white.opacity(0.02)],
                    startPoint: .top, endPoint: .center
                ),
                lineWidth: Layout.hairline
            )
    }
}

#Preview {
    HeroCard(card: .demo, ui: UIState(), nativeGlass: false)
        .padding(40)
        .background(Color.gray.opacity(0.3))
        .environment(ThemeStore())
}
