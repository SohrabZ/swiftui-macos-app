import SwiftUI

/// Shared transparency state. Persisted to `UserDefaults` so the values survive
/// relaunches.
@Observable
@MainActor
final class TransparencyModel {
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
        if let v = defaults.optionalDouble(forKey: Prefs.cardOpacity) { cardOpacity = v }
        if let v = defaults.optionalDouble(forKey: Prefs.blur) { blur = v }
    }

    /// Opacity applied to the card's glass panel only.
    var cardAlpha: Double {
        OpacityControl.card.clamp(cardOpacity)
    }

    /// Blur intensity as a whole-number percentage of the max, for display.
    var blurPercent: Int {
        Int((blur / Self.blurRange.upperBound * 100).rounded())
    }
}
