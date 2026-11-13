import SwiftUI

/// Six hearts that rise once and fade. Purely decorative.
struct HeartsView: View {
    var reduceMotion: Bool = false

    @State private var animate = false

    private static let hearts = Heart.makeField(count: 6)

    var body: some View {
        ZStack {
            ForEach(Self.hearts) { heart in
                Image(systemName: "heart.fill")
                    .font(.system(size: CGFloat(heart.size)))
                    .foregroundStyle(Theme.rose.opacity(0.85))
                    .blur(radius: 0.5)
                    .offset(
                        x: CGFloat(heart.dx + (animate ? heart.wander : 0)),
                        y: CGFloat(heart.dy - (animate && !reduceMotion ? heart.rise : 0))
                    )
                    .opacity(animate ? 0 : 0.9)
                    .animation(
                        .easeInOut(duration: heart.life).delay(heart.delay),
                        value: animate
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { animate = true }
    }
}

private struct Heart: Identifiable {
    let id: Int
    let dx: Double
    let dy: Double
    let rise: Double
    let wander: Double
    let size: Double
    let delay: Double
    let life: Double

    static func makeField(count: Int) -> [Heart] {
        var generator = SeededGenerator(seed: 0x5EED_1234)
        return (0..<count).map { index in
            Heart(
                id: index,
                dx: Double.random(in: -110...110, using: &generator),
                dy: Double.random(in: -26...26, using: &generator),
                rise: Double.random(in: 120...220, using: &generator),
                wander: Double.random(in: -18...18, using: &generator),
                size: Double.random(in: 10...16, using: &generator),
                delay: Double(index) * Theme.Timing.heartStagger,
                life: Theme.Timing.heartLife
            )
        }
    }
}

#Preview {
    ZStack {
        Theme.sky
        HeartsView()
    }
    .ignoresSafeArea()
}
