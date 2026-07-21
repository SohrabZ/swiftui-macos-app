import Testing
@testable import LiquidGlassDemo

@Suite struct DebugInfoTests {
    @Test func reportIncludesEveryField() {
        let report = DebugInfo.report(DebugContext(
            appVersion: "1.2.3 (45)",
            macOSVersion: "15.4.1",
            theme: "Ember",
            appearance: "Dark",
            cardOpacityPercent: 80,
            cardBlurPercent: 33,
            launchAtLogin: "enabled",
            updates: "Sparkle"
        ))
        #expect(report.contains("LiquidGlassDemo 1.2.3 (45)"))
        #expect(report.contains("macOS 15.4.1"))
        #expect(report.contains("Ember"))
        #expect(report.contains("Dark"))
        #expect(report.contains("80%"))
        #expect(report.contains("33%"))
        #expect(report.contains("enabled"))
        #expect(report.contains("Sparkle"))
    }
}
