import Testing
@testable import LiquidGlassDemo

@Suite struct LaunchAtLoginTests {
    /// The test runner isn't a packaged `.app`, so registration must report as
    /// unavailable and `setEnabled` must be a safe no-op (never touching
    /// `SMAppService`). This is the same guard philosophy as Sparkle's.
    @MainActor
    @Test func unavailableOutsideBundle() {
        let item = LaunchAtLogin()
        #expect(!item.available)
        #expect(!item.enabled)
        item.setEnabled(true)
        #expect(!item.enabled)
    }
}
