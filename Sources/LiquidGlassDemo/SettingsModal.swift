import SwiftUI

/// Modal settings panel: dim backdrop + a compact centered panel with the
/// Appearance content (mode picker, theme grid, transparency sliders).
struct SettingsModal: View {
    @Bindable var model: TransparencyModel
    @Bindable var ui: UIState

    @Environment(ThemeStore.self) private var theme

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { close() }

            ScrollableContent {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    ThemePicker(ui: ui)
                    rowDivider

                    settingRow("Card Opacity",
                               "Fade just the glass card panel; the content stays readable.") {
                        SliderControl(value: $model.cardOpacity,
                                      range: OpacityControl.card.range,
                                      percent: OpacityControl.card.percent(model.cardOpacity))
                    }
                    rowDivider

                    settingRow("Card Blur",
                               "Frost intensity of the glass backdrop behind the card.") {
                        SliderControl(value: $model.blur,
                                      range: TransparencyModel.blurRange,
                                      percent: model.blurPercent)
                    }
                }
                // Extra top/right padding reserves space for the close icon
                // (top-right) and the scrollbar (right edge).
                .padding(.top, 22)
                .padding(.leading, 28)
                .padding(.trailing, 42)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 640)
            .frame(maxHeight: 720)
            .background(theme.panel)
            .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
            .themedBorder(Radius.panel)
            .overlay(alignment: .topTrailing) {
                IconButton(systemName: "xmark", tooltip: "Close") { close() }
                    .padding(12)
            }
            // Esc / ⌘. closes the modal (hidden button carrying the shortcut).
            .background {
                Button("Close") { close() }
                    .keyboardShortcut(.cancelAction)
                    .hidden()
            }
            .padding(24)
        }
        // Reset the pointer for the modal's area (the cog's `.link` cursor would
        // otherwise stay "stuck" while occluded). Inner controls override this.
        .pointerStyle(.default)
    }

    private func close() { ui.showSettings = false }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Appearance").font(Typography.title).foregroundStyle(theme.textPrimary)
            Text("Desktop-only display preferences. Theme controls the accent palette and surface styling; transparency controls how much shows through.")
                .font(Typography.caption)
                .foregroundStyle(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 16)
    }

    private var rowDivider: some View {
        Rectangle().fill(theme.border).frame(height: 1).padding(.vertical, 14)
    }

    /// One settings row: title + help on the left, control on the right.
    private func settingRow<Control: View>(_ title: String,
                                           _ help: String,
                                           @ViewBuilder control: () -> Control) -> some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(Typography.label).foregroundStyle(theme.textPrimary)
                Text(help).font(Typography.footnote).foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 20)
            control()
        }
    }
}

/// Inline slider + trailing live percentage (right-aligned control). Nudges its
/// width 1pt after appear so `NSSlider` draws its knob without needing a first
/// hover. Callers pass the already-computed `percent` for the trailing readout.
struct SliderControl: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let percent: Int

    @Environment(ThemeStore.self) private var theme
    @State private var width: CGFloat = 179

    var body: some View {
        HStack(spacing: 12) {
            Slider(value: $value, in: range)
                .frame(width: width)
                .tint(theme.accent)
            Text("\(percent)%")
                .font(Typography.control)
                .foregroundStyle(theme.textSecondary)
                .frame(width: 42, alignment: .trailing)
        }
        .task { width = 180 }
    }
}

#Preview {
    SettingsModal(model: TransparencyModel(), ui: UIState())
        .frame(width: 800, height: 760)
        .environment(ThemeStore())
}
