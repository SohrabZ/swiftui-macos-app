import SwiftUI
import AppKit

/// The app icon: the water-drop logo on a blue→indigo squircle, matching the
/// app's accent. Rendered in-process with `ImageRenderer` and used as the Dock
/// icon (a SwiftPM executable has no bundled `.icns`).
struct AppIconView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 228, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x7C8CE8),
                            Color(hex: 0x5E7CE0),
                            Color(hex: 0x0B0D12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "drop.fill")
                .font(.system(size: 560, weight: .regular))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.22), radius: 34, y: 16)
        }
        .frame(width: 1024, height: 1024)
    }
}

@MainActor
enum AppIcon {
    /// Renders the icon to an `NSImage` for use as `NSApp.applicationIconImage`.
    static func make() -> NSImage? {
        let renderer = ImageRenderer(content: AppIconView())
        renderer.scale = 1
        return renderer.nsImage
    }

    /// Writes the icon to a PNG (used to preview/verify it).
    static func writePNG(to path: String) {
        guard let png = PNGRenderer.data(from: AppIconView(), scale: 1) else {
            FileHandle.standardError.write(Data("icon: render failed\n".utf8))
            exit(1)
        }
        do {
            try png.write(to: URL(fileURLWithPath: path))
            print("icon written to \(path)")
        } catch {
            FileHandle.standardError.write(Data("icon: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }
}
