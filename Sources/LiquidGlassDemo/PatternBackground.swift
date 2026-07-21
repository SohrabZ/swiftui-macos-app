import SwiftUI

/// A faint grid drawn behind the card so window/card transparency is actually
/// *visible*: as either opacity drops, the grid shows through the glass. Every
/// `majorEvery`-th line is accent-tinted to give the eye something to track.
struct GridPattern: View {
    var spacing: CGFloat = 40
    var majorEvery: Int = 4

    @Environment(ThemeStore.self) private var theme

    var body: some View {
        let minorColor = theme.gridLine.opacity(0.10)
        let majorColor = theme.accent.opacity(0.25)
        Canvas { context, size in
            var minor = Path()
            var major = Path()

            func add(_ line: Path, isMajor: Bool) {
                if isMajor { major.addPath(line) } else { minor.addPath(line) }
            }

            var index = 0
            var x: CGFloat = 0
            while x <= size.width {
                add(Path { $0.move(to: CGPoint(x: x, y: 0)); $0.addLine(to: CGPoint(x: x, y: size.height)) },
                    isMajor: index % majorEvery == 0)
                x += spacing; index += 1
            }

            index = 0
            var y: CGFloat = 0
            while y <= size.height {
                add(Path { $0.move(to: CGPoint(x: 0, y: y)); $0.addLine(to: CGPoint(x: size.width, y: y)) },
                    isMajor: index % majorEvery == 0)
                y += spacing; index += 1
            }

            context.stroke(minor, with: .color(minorColor), lineWidth: 1)
            context.stroke(major, with: .color(majorColor), lineWidth: 1)
        }
    }
}
