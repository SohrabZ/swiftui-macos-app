import SwiftUI

/// First-run welcome panel, shown once at launch (see `UIState.showOnboarding`).
/// Completing persists via `UIState.completeOnboarding()` so it never shows
/// again; Debug ▸ Reset Onboarding brings it back. Styling mirrors the settings
/// modal — this is the template's "show once" flow pattern.
struct OnboardingView: View {
    @Bindable var ui: UIState

    @Environment(ThemeStore.self) private var theme

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                AppIconView()
                    .scaleEffect(72 / 1024)
                    .frame(width: 72, height: 72)
                    .padding(.bottom, 16)

                Text(L10n.welcomeTitle)
                    .font(Typography.title)
                    .foregroundStyle(theme.textPrimary)
                    .padding(.bottom, 6)
                Text(L10n.welcomeSubtitle)
                    .font(Typography.caption)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 12) {
                    feature("paintpalette", L10n.onboardingThemes)
                    feature("menubar.rectangle", L10n.onboardingMenuBar)
                    feature("arrow.triangle.2.circlepath", L10n.onboardingUpdates)
                }
                .padding(.bottom, 22)

                Button(L10n.getStarted) { ui.completeOnboarding() }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accent)
                    .controlSize(.large)
                    .focusEffectDisabled()
                    .pointerStyle(.link)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(32)
            .frame(width: 460)
            .background(theme.panel)
            .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
            .themedBorder(Radius.panel)
            // Esc completes too (same as the button) — dismissing without
            // completing would resurface the panel on every launch.
            .background {
                Button("Close") { ui.completeOnboarding() }
                    .keyboardShortcut(.cancelAction)
                    .hidden()
            }
        }
        .pointerStyle(.default)
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(Typography.iconLarge)
                .foregroundStyle(theme.accent)
                .frame(width: 22)
            Text(text)
                .font(Typography.body)
                .foregroundStyle(theme.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingView(ui: UIState())
        .frame(width: 800, height: 600)
        .environment(ThemeStore())
}
