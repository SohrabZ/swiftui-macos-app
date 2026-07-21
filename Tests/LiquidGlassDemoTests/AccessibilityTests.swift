import Foundation
import Testing
@testable import LiquidGlassDemo

@Suite struct AccessibilityTests {
    @Test func reduceTransparencySolidifiesGlass() {
        #expect(GlassA11y.cardAlpha(0.5, reduceTransparency: true) == 1)
        #expect(GlassA11y.blur(12, reduceTransparency: true) == 0)
        #expect(GlassA11y.sidebarOpacity(0.7, reduceTransparency: true) == 1)
    }

    @Test func standardKeepsValues() {
        #expect(GlassA11y.cardAlpha(0.5, reduceTransparency: false) == 0.5)
        #expect(GlassA11y.blur(12, reduceTransparency: false) == 12)
        #expect(GlassA11y.sidebarOpacity(0.7, reduceTransparency: false) == 0.7)
    }

    @Test func effectiveCombinesSystemAndOverride() {
        #expect(!GlassA11y.effective(system: false, override: false))
        #expect(GlassA11y.effective(system: true, override: false))
        #expect(GlassA11y.effective(system: false, override: true))
        #expect(GlassA11y.effective(system: true, override: true))
    }

    /// Overrides persist via UserDefaults (same pattern as the other prefs).
    @MainActor
    @Test func overridesPersist() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Prefs.reduceMotion)
        defer { defaults.removeObject(forKey: Prefs.reduceMotion) }

        let settings = AccessibilitySettings()
        #expect(!settings.reduceMotion)
        settings.reduceMotion = true
        #expect(AccessibilitySettings().reduceMotion)
    }
}
