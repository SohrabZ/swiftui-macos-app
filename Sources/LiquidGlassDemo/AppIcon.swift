import SwiftUI
import AppKit

/// The app icon in the macOS 26 "Liquid Glass" style: a lavender squircle plate
/// holding a large frosted-glass orb with the water drop suspended inside it —
/// specular light at the orb's top, refraction cooling its bottom, and a soft
/// cast shadow grounding it on the plate.
///
/// Rendered in-process with `ImageRenderer` (no asset catalog), and used as the
/// Dock icon (a SwiftPM executable has no bundled `.icns`), the About and
/// onboarding panels, and the hero card's logo. Everything is drawn with
/// shapes/gradients — `DropShape` is a path (not the SF Symbol) so it can be
/// filled, stroked, and masked per layer.
struct AppIconView: View {
    var body: some View {
        ZStack {
            basePlate
            glassOrb
        }
        .frame(width: 1024, height: 1024)
    }

    /// The squircle plate: lavender glass, brighter toward the top light.
    private var basePlate: some View {
        RoundedRectangle(cornerRadius: 228, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: 0xC0B4EC),
                        Color(hex: 0x9484D8),
                        Color(hex: 0x6F5CBD),
                        Color(hex: 0x453A8E)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            // Light source: a soft bloom falling from the top edge.
            .overlay {
                RoundedRectangle(cornerRadius: 228, style: .continuous)
                    .fill(
                        EllipticalGradient(
                            colors: [.white.opacity(0.35), .clear],
                            center: .top,
                            startRadiusFraction: 0,
                            endRadiusFraction: 0.85
                        )
                    )
            }
            // Depth: the bottom of the plate falls into shade.
            .overlay {
                RoundedRectangle(cornerRadius: 228, style: .continuous)
                    .fill(
                        LinearGradient(colors: [.clear, .black.opacity(0.28)],
                                       startPoint: .center, endPoint: .bottom)
                    )
            }
            // Rim light along the top edge — the highlight that sells the glass.
            .overlay {
                RoundedRectangle(cornerRadius: 224, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.12), .clear],
                                       startPoint: .top, endPoint: .center),
                        lineWidth: 5
                    )
                    .blur(radius: 1)
                    .padding(4)
            }
    }

    /// The frosted glass orb with the drop suspended inside.
    private var glassOrb: some View {
        ZStack {
            // Cast shadow grounding the orb on the plate.
            Circle()
                .fill(.black.opacity(0.28))
                .blur(radius: 44)
                .offset(y: 42)

            // Frosted body, lit from the upper left.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, Color(hex: 0xF0F3FF), Color(hex: 0xCDD6F6)],
                        center: UnitPoint(x: 0.32, y: 0.24),
                        startRadius: 60,
                        endRadius: 560
                    )
                )
            // Refraction: the plate's violet pooling in the orb's bottom.
            Circle()
                .fill(
                    LinearGradient(stops: [
                        .init(color: .clear, location: 0.55),
                        .init(color: Color(hex: 0x6F5CBD).opacity(0.35), location: 1.0)
                    ], startPoint: .top, endPoint: .bottom)
                )

            // The drop, suspended in the glass — large enough to read as a drop
            // even at Dock size.
            DropShape()
                .fill(
                    LinearGradient(colors: [Color(hex: 0x6A58BC), Color(hex: 0x3D2C85)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 400, height: 465)
            // A glass wash over the glyph's top, so it reads inside the orb.
            DropShape()
                .fill(
                    LinearGradient(colors: [.white.opacity(0.35), .clear],
                                   startPoint: .top, endPoint: .center)
                )
                .frame(width: 400, height: 465)

            // Specular highlights on the orb's upper left.
            Ellipse()
                .fill(.white.opacity(0.95))
                .frame(width: 210, height: 130)
                .rotationEffect(.degrees(-24))
                .blur(radius: 16)
                .offset(x: -155, y: -205)
            Ellipse()
                .fill(.white)
                .frame(width: 64, height: 40)
                .rotationEffect(.degrees(-24))
                .blur(radius: 8)
                .offset(x: -215, y: -245)

            // Rim: bright edge up top, violet edge below.
            Circle()
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.9), Color(hex: 0x6F5CBD).opacity(0.4)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 4
                )
                .blur(radius: 1)
        }
        .frame(width: 700, height: 700)
        .offset(y: 8)
    }
}

/// A teardrop: softly pointed top flowing into a full round bottom — the sides
/// meet the belly circle at tangent points, which is what keeps the silhouette
/// a drop rather than a spire. Drawn as a path so the icon can stroke and mask
/// it per layer (an SF Symbol exposes no outline).
struct DropShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let center = CGPoint(x: w * 0.5, y: h * 0.60)
        let radius = h * 0.42
        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.05))
        // Left side: tip → tangent point at 230° on the belly circle. control2
        // sits so the curve arrives along the circle's tangent (no shoulder kink).
        p.addCurve(to: CGPoint(x: center.x - radius * 0.643, y: center.y - radius * 0.766),
                   control1: CGPoint(x: w * 0.47, y: h * 0.18),
                   control2: CGPoint(x: w * 0.36, y: h * 0.20))
        // Bottom: the belly circle's long sweep (230° → 310° through the bottom).
        p.addArc(center: center, radius: radius,
                 startAngle: .degrees(230), endAngle: .degrees(310), clockwise: true)
        // Right side: tangent point at 310° → tip (mirror of the left).
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.05),
                   control1: CGPoint(x: w * 0.64, y: h * 0.20),
                   control2: CGPoint(x: w * 0.53, y: h * 0.18))
        p.closeSubpath()
        return p
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

    /// The icon at menu-bar size, rendered once for the tray label.
    static let tray: NSImage? = {
        guard let img = make() else { return nil }
        img.size = NSSize(width: 19, height: 19)
        return img
    }()

    /// Writes the icon to a PNG (used to preview/verify it).
    static func writePNG(to path: String) {
        PNGRenderer.write(AppIconView(), to: path, scale: 1, label: "icon")
    }
}
