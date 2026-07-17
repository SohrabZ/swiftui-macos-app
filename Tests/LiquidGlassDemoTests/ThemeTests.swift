import Testing
@testable import LiquidGlassDemo

@Suite struct ThemeTests {
    // Every selectable theme must resolve to a palette or the store falls back.
    @MainActor
    @Test func everyThemeHasAPalette() {
        for id in ThemeID.allCases {
            #expect(ThemeStore.palettes[id] != nil)
        }
    }

    // ThemeSwatch.all (settings previews) and the real palettes must cover the same
    // themes — keep the two tables in sync.
    @Test func themeSwatchesCoverAllThemes() {
        let swatchIDs = Set(ThemeSwatch.all.map(\.themeID))
        #expect(swatchIDs == Set(ThemeID.allCases))
    }
}
