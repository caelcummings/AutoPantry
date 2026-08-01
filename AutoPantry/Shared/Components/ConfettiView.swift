import SwiftUI

/// Lightweight confetti burst for plan-complete celebration.
struct ConfettiView: View {
    var pieceCount: Int = 80

    @State private var pieces: [ConfettiPiece] = []

    private let colors: [Color] = [
        APTheme.accent,
        Color.orange,
        Color.pink,
        Color.yellow,
        Color.cyan,
        Color.mint,
        Color.purple.opacity(0.85),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                guard !pieces.isEmpty else { return }

                for piece in pieces {
                    var progress = (now - piece.born) / piece.lifetime
                    // Loop so confetti keeps falling while the summary is open.
                    progress = progress.truncatingRemainder(dividingBy: 1)
                    if progress < 0 { continue }

                    let x = piece.startX
                        + piece.drift * progress
                        + sin(progress * .pi * 4 + piece.wobble) * 16
                    let y = -40 + progress * (size.height + 80)
                    let opacity = Double(1 - progress * 0.85)
                    let rotation = Angle.degrees(piece.spin * progress * 360)

                    var transform = CGAffineTransform.identity
                        .translatedBy(x: x, y: y)
                        .rotated(by: CGFloat(rotation.radians))

                    let rect = CGRect(
                        x: -piece.width / 2,
                        y: -piece.height / 2,
                        width: piece.width,
                        height: piece.height
                    )
                    context.opacity = opacity
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 1.5).applying(transform),
                        with: .color(piece.color)
                    )
                }
            }
            .onAppear {
                if pieces.isEmpty {
                    spawn(in: UIScreen.main.bounds.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func spawn(in size: CGSize) {
        let now = Date().timeIntervalSinceReferenceDate
        let width = max(size.width, 320)
        pieces = (0..<pieceCount).map { index in
            ConfettiPiece(
                born: now - Double.random(in: 0...1.2),
                lifetime: Double.random(in: 2.4...3.6),
                startX: CGFloat.random(in: 0...width),
                drift: CGFloat.random(in: -50...50),
                wobble: Double.random(in: 0...(2 * .pi)),
                spin: Double.random(in: 1.5...4.0) * (Bool.random() ? 1 : -1),
                width: CGFloat.random(in: 6...11),
                height: CGFloat.random(in: 8...16),
                color: colors[index % colors.count]
            )
        }
    }
}

private struct ConfettiPiece {
    let born: TimeInterval
    let lifetime: TimeInterval
    let startX: CGFloat
    let drift: CGFloat
    let wobble: Double
    let spin: Double
    let width: CGFloat
    let height: CGFloat
    let color: Color
}
