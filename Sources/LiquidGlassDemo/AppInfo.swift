import Foundation

/// Static app metadata. Read from the bundle's Info.plist when packaged; under
/// `swift run` there is no bundle, so everything falls back to dev values.
enum AppInfo {
    static let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "LiquidGlassDemo"
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    static let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

    /// "1.0.0 (42)" when packaged, "dev" under `swift run`.
    static var versionString: String {
        guard let version else { return "dev" }
        return build.map { "\(version) (\($0))" } ?? version
    }

    static let repositoryURL = URL(string: "https://github.com/SohrabZ/swiftui-macos-app")!
}
