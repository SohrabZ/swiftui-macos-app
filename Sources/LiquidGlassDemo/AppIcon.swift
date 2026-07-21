import SwiftUI
import AppKit

/// The app icon in the macOS 26 "Liquid Glass" style: a glass squircle plate lit
/// from above, with a translucent water drop floating over it — rim light on the
/// plate and the drop, a specular highlight, the plate color refracting up
/// through the drop's bottom, and a soft cast shadow for depth.
///
/// Rendered in-process with `ImageRenderer` (no asset catalog), and used as the
/// Dock icon (a SwiftPM executable has no bundled `.icns`). Everything is drawn
/// with shapes/gradients — `DropShape` is a path (not the SF Symbol) so it can
/// be filled, stroked, and masked per layer.
struct AppIconView: View {
    var body: some View {
        ZStack {
            basePlate
            dropGlyph
        }
        .frame(width: 1024, height: 1024)
    }

    /// The squircle plate: deep indigo glass, brighter toward the top light.
    private var basePlate: some View {
        RoundedRectangle(cornerRadius: 228, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: 0x6E8AEE),
                        Color(hex: 0x4161D8),
                        Color(hex: 0x24348F),
                        Color(hex: 0x0D1233)
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
                            colors: [.white.opacity(0.30), .clear],
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
                        LinearGradient(colors: [.clear, .black.opacity(0.35)],
                                       startPoint: .center, endPoint: .bottom)
                    )
            }
            // Rim light along the top edge — the highlight that sells the glass.
            .overlay {
                RoundedRectangle(cornerRadius: 224, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.85), .white.opacity(0.12), .clear],
                                       startPoint: .top, endPoint: .center),
                        lineWidth: 5
                    )
                    .blur(radius: 1)
                    .padding(4)
            }
    }

    /// The water drop as a translucent glass element floating over the plate.
    private var dropGlyph: some View {
        ZStack {
            // Cool glow on the plate behind the drop.
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xBFD4FF).opacity(0.35), .clear],
                                     center: .center, startRadius: 20, endRadius: 330))

            // Cast shadow grounding the drop on the plate.
            DropShape()
                .fill(.black.opacity(0.4))
                .blur(radius: 26)
                .offset(y: 30)

            // Glass body: opaque frost — bright at the top, cooling to pale blue
            // at the belly so the drop separates from the plate.
            DropShape()
                .fill(
                    LinearGradient(colors: [.white,
                                            Color(hex: 0xE4ECFF),
                                            Color(hex: 0xAFC3FF)],
                                   startPoint: .top, endPoint: .bottom)
                )
            // Refraction: a thin indigo band hugging the belly's bottom edge.
            DropShape()
                .fill(
                    LinearGradient(stops: [
                        .init(color: .clear, location: 0.6),
                        .init(color: Color(hex: 0x4161D8).opacity(0.55), location: 1.0)
                    ], startPoint: .top, endPoint: .bottom)
                )
            // Lit from above: a soft white bloom inside the drop's top.
            Ellipse()
                .fill(.white.opacity(0.3))
                .frame(width: 280, height: 170)
                .blur(radius: 30)
                .offset(y: -140)
                .mask(DropShape())
            // Edge definition: bright rim up top, indigo refraction rim below.
            DropShape()
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.9), Color(hex: 0x24348F).opacity(0.5)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 4
                )
                .blur(radius: 1)
            // Specular highlights, confined to the drop.
            ZStack {
                Ellipse()
                    .fill(.white)
                    .frame(width: 90, height: 140)
                    .rotationEffect(.degrees(-18))
                    .blur(radius: 6)
                    .offset(x: -105, y: -45)
                Ellipse()
                    .fill(.white.opacity(0.7))
                    .frame(width: 26, height: 44)
                    .rotationEffect(.degrees(-15))
                    .blur(radius: 5)
                    .offset(x: -60, y: 75)
            }
            .mask(DropShape())
        }
        .frame(width: 500, height: 580)
    }
}

/// A teardrop: softly pointed top flowing into a full round bottom — the sides
/// meet the bottom circle at tangent points, which is what keeps the silhouette
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

    /// Writes the icon to a PNG (used to preview/verify it).
    static func writePNG(to path: String) {
        PNGRenderer.write(AppIconView(), to: path, scale: 1, label: "icon")
    }
}
