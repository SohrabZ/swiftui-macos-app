import SwiftUI
import AppKit

/// Entry point. Runs the normal windowed app, unless invoked with
/// `--snapshot <path>`, in which case it renders `ContentView` to a PNG in-process
/// and exits. The snapshot path needs no Screen Recording permission and no visible
/// window, which makes it the visual-confirmation artifact for `verify.sh`.
@main
struct Main {
    static func main() {
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count {
            let size = parseSize(args) ?? CGSize(width: 800, height: 600)
            MainActor.assumeIsolated {
                Snapshot.write(to: args[i + 1], size: size,
                               theme: value(of: "--theme", in: args),
                               appearance: value(of: "--appearance", in: args))
            }
            return
        }
        if let i = args.firstIndex(of: "--icon"), i + 1 < args.count {
            MainActor.assumeIsolated {
                AppIcon.writePNG(to: args[i + 1])
            }
            return
        }
        LiquidGlassDemoApp.main()
    }

    /// Parses `--size WxH` (e.g. `--size 1200x800`), if present.
    private static func parseSize(_ args: [String]) -> CGSize? {
        guard let i = args.firstIndex(of: "--size"), i + 1 < args.count else { return nil }
        let parts = args[i + 1].split(separator: "x")
        guard parts.count == 2, let w = Double(parts[0]), let h = Double(parts[1]) else { return nil }
        return CGSize(width: w, height: h)
    }

    /// Returns the value following `flag` (e.g. `--theme nous`), if present.
    private static func value(of flag: String, in args: [String]) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
}

struct LiquidGlassDemoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var updater = Updater()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Room for the sidebars + a padded main column on all sides.
                .frame(minWidth: 820, minHeight: 560)
                // Empty title so macOS never flashes the executable name in the
                // header on hover / when the window becomes key.
                .navigationTitle("")
        }
        // Transparent, full-size titlebar so the SwiftUI header strip becomes the
        // header background (the default titlebar material otherwise shows through).
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1180, height: 760)
        .defaultPosition(.center)
        .commands {
            // Standard "Check for Updates…" item under the app menu. Disabled (and
            // inert) unless running as a configured, signed bundle — see Updater.
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { updater.checkForUpdates() }
                    .disabled(!updater.canCheckForUpdates)
            }
        }
    }
}

/// Makes this SwiftPM executable behave like a normal app: a Dock icon, a menu
/// bar, and a window that activates/comes-to-front on click. Without `.regular`,
/// a non-bundled executable defaults to an accessory policy (no Dock, can't
/// become the active app).
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        MainActor.assumeIsolated {
            if let icon = AppIcon.make() {
                NSApp.applicationIconImage = icon
            }
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    // Keep the app running after its last window closes (standard macOS behavior):
    // the menu bar stays, and clicking the Dock icon reopens a window.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // Recreate a window when the app is reactivated (Dock click / ⌘-Tab) with no
    // visible windows. `WindowGroup` supplies the window; this just asks AppKit to
    // restore one.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        true
    }
}

/// Renders a SwiftUI view to a PNG file using `ImageRenderer` — no window, no
/// screen-capture permission required.
@MainActor
enum Snapshot {
    /// Renders `ContentView` to a PNG. `theme` (a `ThemeID` raw value like `nous`)
    /// and `appearance` (`light`/`dark`) let the README asset script capture varied
    /// shots — they seed `UserDefaults` and force the app appearance so the adaptive
    /// palette resolves for the requested mode before `ImageRenderer` rasterizes.
    static func write(to path: String, size: CGSize, theme: String? = nil, appearance: String? = nil) {
        if let theme { UserDefaults.standard.set(theme, forKey: Prefs.theme) }

        let dark = appearance?.lowercased() == "dark"
        if appearance != nil {
            UserDefaults.standard.set(dark ? "Dark" : "Light", forKey: Prefs.mode)
        }
        let scheme: ColorScheme = dark ? .dark : .light

        // Disable the behind-window vibrancy (no live desktop to sample offscreen)
        // and paint an opaque theme fill behind the content so the translucent
        // sidebars/margins read as clean chrome instead of desktop bleed.
        let content = ContentView(windowMaterial: nil)
            .frame(width: size.width, height: size.height)
            .background(ThemeStore().background)
            // ImageRenderer ignores `.preferredColorScheme`, so drive the scheme via
            // the environment directly — that's what SwiftUI resolves adaptive
            // colors against, giving genuinely different light/dark snapshots.
            .environment(\.colorScheme, scheme)
        PNGRenderer.write(content, to: path, scale: 2, label: "snapshot",
                          appearance: NSAppearance(named: dark ? .darkAqua : .aqua))
    }
}
