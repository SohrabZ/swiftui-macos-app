import Foundation
import Testing
@testable import LiquidGlassDemo

@Suite struct LocalizationTests {
    /// Reads a key straight from a shipped table (the lookup-language machinery
    /// would make assertions depend on the test runner's locale instead).
    private func value(_ key: String, localization: String) -> String? {
        guard let path = L10n.bundle.path(forResource: "Localizable", ofType: "strings",
                                          inDirectory: nil, forLocalization: localization),
              let dict = NSDictionary(contentsOfFile: path) else { return nil }
        return dict[key] as? String
    }

    @Test func translatedTablesShip() {
        let expected: [String: [String: String]] = [
            "de": ["Settings": "Einstellungen", "Theme": "Design", "Get Started": "Los geht's",
                   "Accessibility": "Bedienungshilfen", "General": "Allgemein",
                   "Appearance": "Erscheinungsbild"],
            "fr": ["Settings": "Réglages", "Theme": "Thème", "Get Started": "C'est parti",
                   "Accessibility": "Accessibilité", "General": "Général",
                   "Appearance": "Apparence"],
            "es": ["Settings": "Ajustes", "Theme": "Tema", "Get Started": "Empezar",
                   "Accessibility": "Accesibilidad", "General": "General",
                   "Appearance": "Apariencia"],
            "pt": ["Settings": "Definições", "Theme": "Tema", "Get Started": "Começar",
                   "Accessibility": "Acessibilidade", "General": "Geral",
                   "Appearance": "Aparência"]
        ]
        for (lang, pairs) in expected {
            for (key, want) in pairs {
                #expect(value(key, localization: lang) == want, "\(lang): \(key)")
            }
        }
    }

    @Test func englishTableShips() {
        #expect(value("Settings", localization: "en") == "Settings")
    }

    @Test func unknownKeyFallsBackToItself() {
        #expect(String(localized: "No such key", bundle: L10n.bundle) == "No such key")
    }
}
