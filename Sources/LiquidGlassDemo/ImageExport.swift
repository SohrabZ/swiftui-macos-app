import SwiftUI
import AppKit

/// Renders a SwiftUI view to PNG data via `ImageRenderer` — no window and no
/// screen-capture permission required. Shared by the app-icon and snapshot paths
/// so the `ImageRenderer → NSImage → TIFF → PNG` chain lives in one place.
@MainActor
enum PNGRenderer {
    static func data(from view: some View, scale: CGFloat) -> Data? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return rep.representation(using: .png, properties: [:])
    }

    /// Renders `view` to a PNG file. On any failure it writes `label: <reason>` to
    /// stderr and exits non-zero — this is the shared path for the `--snapshot` and
    /// `--icon` command-line tools, which have no UI to report errors through.
    static func write(_ view: some View, to path: String, scale: CGFloat, label: String) {
        func fail(_ message: String) -> Never {
            FileHandle.standardError.write(Data("\(label): \(message)\n".utf8))
            exit(1)
        }

        guard let png = data(from: view, scale: scale) else {
            fail("could not render view to PNG")
        }
        do {
            try png.write(to: URL(fileURLWithPath: path))
            print("\(label) written to \(path)")
        } catch {
            fail("could not write \(path): \(error.localizedDescription)")
        }
    }
}
