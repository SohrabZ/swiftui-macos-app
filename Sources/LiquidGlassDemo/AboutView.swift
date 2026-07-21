import SwiftUI
import AppKit

/// The themed About panel, opened from the app menu (replaces the stock AppKit
/// panel so it matches the app's theme). Fixed size; at most one instance via
/// the "about" `Window` scene.
struct AboutView: View {
    @Environment(ThemeStore.self) private var theme

    /// The appearance mode read from prefs at open time. The panel is its own
    /// window/scene, so it can't observe `UIState.mode` — and the theme colors
    /// are adaptive NSColors that resolve against *this* window's scheme, which
    /// must match the forced Light/Dark instead of the system setting.
    @State private var scheme: ColorScheme = {
        let mode = UserDefaults.standard.string(forKey: Prefs.mode)
            .flatMap { AppearanceMode(rawValue: $0) } ?? .dark
        switch mode {
        case .light: return .light
        case .dark: return .dark
        case .system: return SystemAppearance.resolve()
        }
    }()

    var body: some View {
        VStack(spacing: 14) {
            AppIconView()
                .scaleEffect(88 / 1024)
                .frame(width: 88, height: 88)

            VStack(spacing: 4) {
                Text(AppInfo.name)
                    .font(Typography.title)
                    .foregroundStyle(theme.textPrimary)
                Text("Version \(AppInfo.versionString)")
                    .font(Typography.caption)
                    .foregroundStyle(theme.textSecondary)
            }

            Text(L10n.aboutTagline)
                .font(Typography.footnote)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Plain button styled as a link — `Link` doesn't rasterize in the
            // offscreen `--snapshot --view about` path.
            Button("GitHub Repository") {
                NSWorkspace.shared.open(AppInfo.repositoryURL)
            }
            .buttonStyle(.plain)
            .font(Typography.caption)
            .foregroundStyle(theme.accent)
            .focusEffectDisabled()
            .pointerStyle(.link)

            Text("Auto-updates powered by Sparkle")
                .font(Typography.footnote)
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .frame(width: 320)
        .background(theme.background)
        // Window-edge border matching the main window's.
        .overlay {
            RoundedRectangle(cornerRadius: Radius.window, style: .continuous)
                .strokeBorder(theme.divider, lineWidth: Layout.hairline)
                .ignoresSafeArea()
        }
        .preferredColorScheme(scheme)
        .pointerStyle(.default)
    }
}

#Preview {
    AboutView()
        .environment(ThemeStore())
}
