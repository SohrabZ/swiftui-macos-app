import SwiftUI

/// In-app accessibility overrides, persisted like the other preferences. They
/// layer ON TOP of the system accessibility settings: a toggle can only force
/// a behavior on, never off — the effective value is `system || override`
/// (see `GlassA11y.effective`).
@Observable
@MainActor
final class AccessibilitySettings {
    var reduceMotion = false {
        didSet { UserDefaults.standard.set(reduceMotion, forKey: Prefs.reduceMotion) }
    }
    var reduceTransparency = false {
        didSet { UserDefaults.standard.set(reduceTransparency, forKey: Prefs.reduceTransparency) }
    }
    var increaseContrast = false {
        didSet { UserDefaults.standard.set(increaseContrast, forKey: Prefs.increaseContrast) }
    }

    init() {
        let defaults = UserDefaults.standard
        if let v = defaults.optionalBool(forKey: Prefs.reduceMotion) { reduceMotion = v }
        if let v = defaults.optionalBool(forKey: Prefs.reduceTransparency) { reduceTransparency = v }
        if let v = defaults.optionalBool(forKey: Prefs.increaseContrast) { increaseContrast = v }
    }
}
