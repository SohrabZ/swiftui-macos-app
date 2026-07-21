import SwiftUI

/// The sections shown in the settings modal's left nav. Add a case (plus its
/// localized title/subtitle) to add a settings page.
enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case accessibility = "Accessibility"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintpalette"
        case .accessibility: "accessibility"
        }
    }

    var title: String {
        switch self {
        case .general: L10n.general
        case .appearance: L10n.appearance
        case .accessibility: L10n.accessibility
        }
    }

    var subtitle: String {
        switch self {
        case .general: L10n.generalHelp
        case .appearance: L10n.appearanceHelp
        case .accessibility: L10n.accessibilityHelp
        }
    }
}

/// Modal settings panel: dim backdrop + centered panel with a left section nav
/// and a scrollable content area (label+help rows with right-aligned controls).
struct SettingsModal: View {
    @Bindable var model: TransparencyModel
    @Bindable var ui: UIState
    @Bindable var a11y: AccessibilitySettings

    @Environment(ThemeStore.self) private var theme
    @Environment(ErrorStore.self) private var errors
    // Owned here (recreated on each open) so the toggle always reflects the
    // real SMAppService status, including changes made in System Settings.
    @State private var launchAtLogin = LaunchAtLogin()
    @State private var section: SettingsSection = .general

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
            .frame(maxWidth: 900, maxHeight: 720)
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

    // MARK: Nav

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(SettingsSection.allCases) { item in
                navRow(item)
            }
            Spacer()
        }
        .padding(10)
        .frame(width: 200)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func navRow(_ item: SettingsSection) -> some View {
        Button {
            section = item
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.icon).font(Typography.icon).frame(width: 18)
                Text(item.title).font(Typography.body)
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
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(section == item ? .isSelected : [])
    }

    // MARK: Content

    private var content: some View {
        ScrollableContent {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title).font(Typography.title).foregroundStyle(theme.textPrimary)
                    Text(section.subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 16)

                switch section {
                case .general: generalSection
                case .appearance: appearanceSection
                case .accessibility: accessibilitySection
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
    }

    private var generalSection: some View {
        settingRow(L10n.launchAtLogin,
                   launchAtLogin.available
                       ? L10n.launchAtLoginHelp
                       : L10n.launchAtLoginUnavailable) {
            Toggle(L10n.launchAtLogin, isOn: Binding(
                get: { launchAtLogin.enabled },
                set: { launchAtLogin.setEnabled($0, reporting: errors) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(theme.accent)
            .disabled(!launchAtLogin.available)
        }
    }

    private var appearanceSection: some View {
        Group {
            ThemePicker(ui: ui)
            rowDivider

            settingRow("Card Opacity",
                       "Fade just the glass card panel; the content stays readable.") {
                SliderControl(value: $model.cardOpacity,
                              range: OpacityControl.card.range,
                              percent: OpacityControl.card.percent(model.cardOpacity),
                              label: "Card Opacity")
            }
            rowDivider

            settingRow("Card Blur",
                       "Frost intensity of the glass backdrop behind the card.") {
                SliderControl(value: $model.blur,
                              range: TransparencyModel.blurRange,
                              percent: model.blurPercent,
                              label: "Card Blur")
            }
        }
    }

    private var accessibilitySection: some View {
        Group {
            toggleRow(L10n.reduceMotion, L10n.reduceMotionHelp, isOn: $a11y.reduceMotion)
            rowDivider
            toggleRow(L10n.reduceTransparency, L10n.reduceTransparencyHelp,
                      isOn: $a11y.reduceTransparency)
            rowDivider
            toggleRow(L10n.increaseContrast, L10n.increaseContrastHelp, isOn: $a11y.increaseContrast)
        }
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

    /// A settings row whose control is a right-aligned switch (the Launch at
    /// Login pattern): title + help on the left, tinted switch on the right.
    private func toggleRow(_ title: String, _ help: String, isOn: Binding<Bool>) -> some View {
        settingRow(title, help) {
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(theme.accent)
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
    /// VoiceOver label (the row's visible title); the percent is the spoken value.
    let label: String

    @Environment(ThemeStore.self) private var theme
    @State private var width: CGFloat = 179

    var body: some View {
        HStack(spacing: 12) {
            Slider(value: $value, in: range) { Text(label) }
                .labelsHidden()
                .accessibilityValue("\(percent)%")
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
    SettingsModal(model: TransparencyModel(), ui: UIState(), a11y: AccessibilitySettings())
        .frame(width: 1000, height: 760)
        .environment(ThemeStore())
        .environment(ErrorStore())
}
