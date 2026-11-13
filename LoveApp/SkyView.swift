import SwiftUI

/// The night sky: a vertical gradient plus 60 stars that drift and twinkle.
///
/// `dim` scales every star's brightness. `1.0` is full brightness, `0.35` is the
/// moment after the tap when the sky appears to hold its breath. Conforming to
/// `Animatable` is what lets that change fade instead of snap.
struct SkyView: View, Animatable {
    var dim: Double
    var reduceMotion: Bool = false

    var animatableData: Double {
        get { dim }
        set { dim = newValue }
    }

    private static let stars = Star.makeField(count: 60)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.deepBlue, Theme.sky],
                startPoint: .top,
                endPoint: .bottom
            )

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate

                Canvas { context, size in
                    let span = Double(size.height) + 40
                    guard size.width > 0, span > 0 else { return }

                    for star in Self.stars {
                        let x = star.x * Double(size.width)

                        // Drift upward, wrapping around the visible band.
                        var y = (star.y * span - star.speed * t).truncatingRemainder(dividingBy: span)
                        if y < 0 { y += span }
                        y -= 20

                        let twinkle = 0.75 + 0.25 * sin(2 * Double.pi * t / star.period + star.phase)
                        let brightness = min(1, max(0, star.opacity * twinkle * dim))
                        guard brightness > 0.01 else { continue }

                        let r = star.radius
                        let rect = CGRect(
                            x: CGFloat(x - r),
                            y: CGFloat(y - r),
                            width: CGFloat(r * 2),
                            height: CGFloat(r * 2)
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(Theme.starlight.opacity(brightness))
                        )
                    }
                }
            }
        }
    }
}

private struct Star {
    let x: Double         // 0...1 of width
    let y: Double         // 0...1 of height
    let radius: Double
    let opacity: Double
    let speed: Double     // points per second
    let period: Double    // seconds per twinkle
    let phase: Double     // radians

    static func makeField(count: Int) -> [Star] {
        var generator = SeededGenerator(seed: 0x9E37_79B9)
        return (0..<count).map { _ in
            Star(
                x: Double.random(in: 0...1, using: &generator),
                y: Double.random(in: 0...1, using: &generator),
                radius: Double.random(in: 0.6...1.8, using: &generator),
                opacity: Double.random(in: 0.25...0.8, using: &generator),
                speed: Double.random(in: 0.5...2.0, using: &generator),
                period: Double.random(in: 3...7, using: &generator),
                phase: Double.random(in: 0...(2 * Double.pi), using: &generator)
            )
        }
    }
}

/// Deterministic PRNG so the sky and the hearts look identical on every launch.
/// SplitMix64 — small, fast, and good enough for scattering dots.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

#Preview {
    SkyView(dim: 1.0)
        .ignoresSafeArea()
}
