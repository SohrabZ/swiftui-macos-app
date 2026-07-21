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
}
