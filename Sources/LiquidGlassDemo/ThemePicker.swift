import SwiftUI

/// One theme swatch's preview colors (adaptive light/dark).
struct ThemeSwatch: Identifiable {
    let themeID: ThemeID
    let name: String
    let desc: String
    let bg: Color
    let sidebar: Color
    let title: Color
    let sub: Color
    let pill: Color
    let pillBorder: Color

    var id: String { name }

    /// Display name for a theme id (hero card badge, inspector readout).
    static func name(for id: ThemeID) -> String {
        all.first { $0.themeID == id }?.name ?? id.rawValue.capitalized
    }

    // NOTE: these are mini-mockup preview colors, intentionally distinct from the
    // real palettes in `ThemeStore.palettes`. Keep the two tables in sync when a
    // theme's identity changes.
    static let all: [ThemeSwatch] = [
        ThemeSwatch(themeID: .slate, name: "Slate", desc: "Cool slate blue — focused developer theme",
                    bg: Color(lightHex: 0xFFFFFF, darkHex: 0x0F1218),
                    sidebar: Color(lightHex: 0xEEF0F3, darkHex: 0x0B0D12),
                    title: Color(lightHex: 0x1F2328, darkHex: 0xC9CCD1),
                    sub: Color(lightHex: 0x8A929E, darkHex: 0x6A707C),
                    pill: Color(lightHex: 0xDDE6FB, darkHex: 0x29303D),
                    pillBorder: Color(lightHex: 0xBBD0F5, darkHex: 0x3A4557)),
        ThemeSwatch(themeID: .nous, name: "Nous", desc: "Glass neutrals with Nous blue accents",
                    bg: Color(lightHex: 0xEEF3FF, darkHex: 0x1E3A8A),
                    sidebar: Color(lightHex: 0xE0E9FB, darkHex: 0x1B347D),
                    title: Color(lightHex: 0x1F2328, darkHex: 0xF0E6D2),
                    sub: Color(lightHex: 0x8A929E, darkHex: 0xA9C0F5),
                    pill: Color(lightHex: 0xDCE7FE, darkHex: 0x2E52B8),
                    pillBorder: Color(lightHex: 0xBBD0F5, darkHex: 0x3C63C9)),
        ThemeSwatch(themeID: .midnight, name: "Midnight", desc: "Deep blue-violet with cool accents",
                    bg: Color(lightHex: 0xFFFFFF, darkHex: 0x14142A),
                    sidebar: Color(lightHex: 0xF0EEF7, darkHex: 0x0F0F22),
                    title: Color(lightHex: 0x1F2328, darkHex: 0xCFC6E8),
                    sub: Color(lightHex: 0x8A929E, darkHex: 0x8E86B8),
                    pill: Color(lightHex: 0xE7E2F7, darkHex: 0x241F45),
                    pillBorder: Color(lightHex: 0xCFC6E8, darkHex: 0x3A3568)),
        ThemeSwatch(themeID: .ember, name: "Ember", desc: "Warm crimson and bronze — forge vibes",
                    bg: Color(lightHex: 0xFBF2EE, darkHex: 0x2A1410),
                    sidebar: Color(lightHex: 0xF3E6DE, darkHex: 0x22100C),
                    title: Color(lightHex: 0x1F2328, darkHex: 0xE8C6A0),
                    sub: Color(lightHex: 0x8A929E, darkHex: 0xB08968),
                    pill: Color(lightHex: 0xFBE6D6, darkHex: 0x3D1E14),
                    pillBorder: Color(lightHex: 0xE8C6A0, darkHex: 0x522A1C)),
        ThemeSwatch(themeID: .mono, name: "Mono", desc: "Clean grayscale — minimal and focused",
                    bg: Color(lightHex: 0xFFFFFF, darkHex: 0x0E0E0E),
                    sidebar: Color(lightHex: 0xF0F0F0, darkHex: 0x0A0A0A),
                    title: Color(lightHex: 0x1F2328, darkHex: 0xE0E0E0),
                    sub: Color(lightHex: 0x8A929E, darkHex: 0x808080),
                    pill: Color(lightHex: 0xEDEDED, darkHex: 0x1E1E1E),
                    pillBorder: Color(lightHex: 0xD8D8D8, darkHex: 0x2E2E2E)),
        ThemeSwatch(themeID: .cyberpunk, name: "Cyberpunk", desc: "Neon green on black — matrix terminal",
                    bg: Color(lightHex: 0xF1FBF3, darkHex: 0x081008),
                    sidebar: Color(lightHex: 0xE4F5E8, darkHex: 0x040A04),
                    title: Color(lightHex: 0x1F2328, darkHex: 0x5BE85B),
                    sub: Color(lightHex: 0x8A929E, darkHex: 0x3A9D3A),
                    pill: Color(lightHex: 0xDDF7DF, darkHex: 0x0E2810),
                    pillBorder: Color(lightHex: 0x9BE0A0, darkHex: 0x1E5020))
    ]
}

/// The "Theme" section: header + Light/Dark/System mode control, a search field,
/// and the grid of theme cards.
struct ThemePicker: View {
    @Bindable var ui: UIState
    @Environment(ThemeStore.self) private var theme
    @State private var search = ""

    // Adaptive: fits as many ~180pt-min columns as the width allows, dropping to
    // 2 or 1 columns automatically when the modal is narrow.
    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 12)]

    private var filtered: [ThemeSwatch] {
        search.isEmpty ? ThemeSwatch.all
            : ThemeSwatch.all.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.theme).font(Typography.label).foregroundStyle(theme.textPrimary)
                    Text(L10n.themePickerHelp)
                        .font(Typography.footnote).foregroundStyle(theme.textSecondary)
                }
                Spacer()
                modePicker
            }

            searchField

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filtered) { card($0) }
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: 2) {
            ForEach(AppearanceMode.allCases) { m in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { ui.mode = m }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: m.icon).font(Typography.iconTiny)
                        Text(m.rawValue).font(Typography.control)
                    }
                    .foregroundStyle(ui.mode == m ? theme.textPrimary : theme.textSecondary)
                    .padding(.horizontal, 11).padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.control)
                            .fill(ui.mode == m ? theme.background : .clear)
                            .themedBorder(Radius.control, width: ui.mode == m ? 1 : 0)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: Radius.control))
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
                .pointerStyle(.link)
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: Radius.field).fill(theme.textSecondary.opacity(0.12)))
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(Typography.iconSmall).foregroundStyle(theme.textSecondary)
            TextField(L10n.searchThemes, text: $search)
                .textFieldStyle(.plain)
                .font(Typography.body)
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: Radius.field).fill(theme.textSecondary.opacity(0.06)))
        .themedBorder(Radius.field)
    }

    private func card(_ s: ThemeSwatch) -> some View {
        let isSelected = theme.id == s.themeID
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { theme.id = s.themeID }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                preview(s)
                VStack(alignment: .leading, spacing: 3) {
                    Text(s.name).font(Typography.heading).foregroundStyle(theme.textPrimary)
                    Text(s.desc).font(Typography.caption).foregroundStyle(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.content)
                    .fill(isSelected ? theme.accent.opacity(0.07) : theme.textSecondary.opacity(0.04))
            )
            .themedBorder(Radius.content, color: isSelected ? theme.accent : theme.border, width: isSelected ? 2 : 1)
            .contentShape(RoundedRectangle(cornerRadius: Radius.content))
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .pointerStyle(.link)
        // One VoiceOver element per card: name + selected state, not the mockup.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(s.name)
        .accessibilityHint("Applies the theme")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Mini window mockup. Sizes are relative to the card width so cards scale
    /// down gracefully as the adaptive grid reflows to fewer columns.
    private func preview(_ s: ThemeSwatch) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .topLeading) {
                s.bg
                HStack(spacing: 0) {
                    s.sidebar.frame(width: w * 0.20)
                    Spacer(minLength: 0)
                }
                VStack(alignment: .leading, spacing: 9) {
                    Capsule().fill(s.title).frame(width: w * 0.32, height: 11)
                    Capsule().fill(s.sub).frame(width: w * 0.54, height: 9)
                }
                .padding(.top, 20)
                .padding(.leading, w * 0.30)
            }
            .overlay(alignment: .bottomTrailing) {
                Capsule()
                    .fill(s.pill)
                    .overlay(Capsule().stroke(s.pillBorder, lineWidth: 1))
                    .frame(width: w * 0.26, height: 22)
                    .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .themedBorder(Radius.field, color: theme.border.opacity(0.6))
        }
        .frame(height: 92)
    }
}

#Preview {
    ThemePicker(ui: UIState())
        .padding()
        .frame(width: 640)
        .environment(ThemeStore())
}
