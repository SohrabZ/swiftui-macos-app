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
                Snapshot.write(to: args[i + 1], size: size)
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
}

struct LiquidGlassDemoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

/// Renders a SwiftUI view to a PNG file using `ImageRenderer` — no window, no
/// screen-capture permission required.
@MainActor
enum Snapshot {
    static func write(to path: String, size: CGSize) {
        let content = ContentView()
            .frame(width: size.width, height: size.height)

        guard let png = PNGRenderer.data(from: content, scale: 2) else {
            fail("could not render view to PNG")
        }

        do {
            try png.write(to: URL(fileURLWithPath: path))
            print("snapshot written to \(path)")
        } catch {
            fail("could not write \(path): \(error.localizedDescription)")
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("snapshot: \(message)\n".utf8))
        exit(1)
    }
}
