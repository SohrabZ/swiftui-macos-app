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
}
