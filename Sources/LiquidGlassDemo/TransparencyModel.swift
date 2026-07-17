import SwiftUI

/// Shared transparency state. Persisted to `UserDefaults` so the values survive
/// relaunches.
@Observable
final class TransparencyModel {
    var windowOpacity: Double = OpacityControl.window.defaultValue {
        didSet { UserDefaults.standard.set(windowOpacity, forKey: Prefs.windowOpacity) }
    }
    var cardOpacity: Double = OpacityControl.card.defaultValue {
        didSet { UserDefaults.standard.set(cardOpacity, forKey: Prefs.cardOpacity) }
    }
    /// Frost intensity (blur radius, pt) of the glass backdrop behind the card.
    var blur: Double = TransparencyModel.defaultBlur {
        didSet { UserDefaults.standard.set(blur, forKey: Prefs.blur) }
    }

    static let blurRange: ClosedRange<Double> = 0...24
    static let defaultBlur: Double = 8

    init() {
        let defaults = UserDefaults.standard
        if let v = defaults.optionalDouble(forKey: Prefs.windowOpacity) { windowOpacity = v }
        if let v = defaults.optionalDouble(forKey: Prefs.cardOpacity) { cardOpacity = v }
        if let v = defaults.optionalDouble(forKey: Prefs.blur) { blur = v }
    }

    /// Alpha applied to the whole window.
    var windowAlpha: Double {
        OpacityControl.window.clamp(windowOpacity)
    }

    /// Opacity applied to the card's glass panel only.
    var cardAlpha: Double {
        OpacityControl.card.clamp(cardOpacity)
    }
}
