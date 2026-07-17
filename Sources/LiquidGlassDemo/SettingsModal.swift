import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case appearance = "Appearance"

    var id: String { rawValue }
    var icon: String { "paintpalette" }
}

/// Modal settings panel: dim backdrop + centered panel with a left nav and a
/// content area. Currently only Appearance, laid out as label+help rows with a
/// right-aligned control.
struct SettingsModal: View {
    @Bindable var model: TransparencyModel
    @Bindable var ui: UIState

    @Environment(ThemeStore.self) private var theme
    @State private var section: SettingsSection = .appearance

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { close() }

            HStack(spacing: 0) {
                sidebar
                Rectangle().fill(theme.divider).frame(width: Layout.hairline)
                content
            }
            .frame(maxWidth: 1080, maxHeight: 780)
            .background(theme.panel)
            .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
            .themedBorder(Radius.panel)
            .overlay(alignment: .topTrailing) {
                IconButton(systemName: "xmark", tooltip: "Close") { close() }
                    .padding(12)
            }
            .padding(28)
        }
        // Reset the pointer for the modal's area (the cog's `.link` cursor would
        // otherwise stay "stuck" while occluded). Inner controls override this.
        .pointerStyle(.default)
    }

    private func close() { ui.showSettings = false }

    // MARK: Nav

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(SettingsSection.allCases) { item in
                navRow(item)
            }
            Spacer()
        }
        .padding(10)
        .frame(width: 210)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func navRow(_ item: SettingsSection) -> some View {
        Button {
            section = item
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.icon).font(Typography.icon).frame(width: 18)
                Text(item.rawValue).font(Typography.body)
                Spacer()
            }
            .foregroundStyle(section == item ? theme.textPrimary : theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: Radius.row)
                    .fill(section == item ? theme.selectionFill : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .pointerStyle(.link)
    }

    // MARK: Content

    private var content: some View {
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
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "paintpalette").font(Typography.iconLarge).foregroundStyle(theme.textSecondary)
                Text("Appearance").font(Typography.title).foregroundStyle(theme.textPrimary)
            }
            Text("Desktop-only display preferences. Theme controls the accent palette and surface styling; transparency controls how much shows through.")
                .font(Typography.caption)
                .foregroundStyle(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 20)
    }

    private var rowDivider: some View {
        Rectangle().fill(theme.border).frame(height: 1).padding(.vertical, 18)
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
        .frame(width: 1000, height: 720)
        .environment(ThemeStore())
}
