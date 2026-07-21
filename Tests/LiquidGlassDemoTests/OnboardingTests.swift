import Foundation
import Testing
@testable import LiquidGlassDemo

@Suite struct OnboardingTests {
    /// Uses the real defaults store (cleaned up before/after) because `UIState`
    /// persists there — parallel suites don't read this key, so no interference.
    @MainActor
    @Test func showsOnFirstRunAndPersistsCompletion() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Prefs.hasCompletedOnboarding)
        defer { defaults.removeObject(forKey: Prefs.hasCompletedOnboarding) }

        let fresh = UIState()
        #expect(fresh.showOnboarding)
        #expect(!fresh.hasCompletedOnboarding)

        fresh.completeOnboarding()
        #expect(!fresh.showOnboarding)
        #expect(defaults.bool(forKey: Prefs.hasCompletedOnboarding))

        let relaunched = UIState()
        #expect(!relaunched.showOnboarding)
    }

    @MainActor
    @Test func snapshotOptOutSkipsPanel() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Prefs.hasCompletedOnboarding)
        defer { defaults.removeObject(forKey: Prefs.hasCompletedOnboarding) }

        #expect(!UIState(showsOnboarding: false).showOnboarding)
    }
}
