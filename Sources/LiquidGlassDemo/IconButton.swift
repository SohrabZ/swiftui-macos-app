import SwiftUI

/// A chrome-free header/toolbar icon button: rounded-square hover highlight, no
/// background at rest, hand cursor, native tooltip, and no macOS focus ring.
/// Used for the sidebar toggles, the settings cog, and the modal close button.
struct IconButton: View {
    let systemName: String
    let tooltip: String
    let action: () -> Void

    @Environment(ThemeStore.self) private var theme
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(Typography.icon)
                .foregroundStyle(hovering ? theme.textPrimary : theme.textSecondary)
                .frame(width: Layout.iconButtonWidth, height: Layout.iconButtonHeight)
                .background(
                    RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                        .fill(hovering ? theme.hoverFill : .clear)
                )
                .contentShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .pointerStyle(.link)
        .help(tooltip)
        .accessibilityLabel(tooltip)
        .onHover { hovering = $0 }
    }
}

#Preview {
    HStack(spacing: 8) {
        IconButton(systemName: "gearshape", tooltip: "Settings") {}
        IconButton(systemName: "sidebar.left", tooltip: "Toggle") {}
    }
    .padding()
    .environment(ThemeStore())
}
