import Testing
@testable import LiquidGlassDemo

@Suite struct SettingsSectionTests {
    @Test func everySectionHasIconTitleAndSubtitle() {
        #expect(SettingsSection.allCases.count == 3)
        for section in SettingsSection.allCases {
            #expect(!section.icon.isEmpty)
            #expect(!section.title.isEmpty)
            #expect(!section.subtitle.isEmpty)
        }
    }

    /// The cog/⌘, always lands on General: closing the modal resets the section,
    /// so only an explicit deep link (the card's Customize) opens another page.
    @MainActor
    @Test func closingSettingsResetsToGeneral() {
        let ui = UIState()
        ui.settingsSection = .accessibility
        ui.showSettings = true
        ui.showSettings = false
        #expect(ui.settingsSection == .general)
    }
}
