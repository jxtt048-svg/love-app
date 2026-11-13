import SwiftUI

/// The only control in the app: a breathing ember with an 88 pt tap target.
struct EmberView: View {
    var reduceMotion: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let wave = 0.5 + 0.5 * sin(2 * Double.pi * t / Theme.Timing.emberPulse - Double.pi / 2)

                // Motion breathes the scale; Reduce Motion breathes only the light.
                let scale = reduceMotion ? 1.0 : 1.0 + 0.06 * wave
                let glow = reduceMotion ? 0.75 + 0.25 * wave : 1.0

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.blush.opacity(0.55),
                                    Theme.rose.opacity(0.20),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 6,
                                endRadius: 46
                            )
                        )
                        .frame(width: 92, height: 92)
                        .blur(radius: 10)
                        .opacity(glow)

                    Circle()
                        .fill(Theme.rose)
                        .frame(width: 52, height: 52)
                        .blur(radius: 1.5)

                    Circle()
                        .fill(Theme.blush.opacity(0.85))
                        .frame(width: 16, height: 16)
                        .blur(radius: 6)
                }
                .scaleEffect(CGFloat(scale))
                .frame(width: 88, height: 88)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel("Reveal a message")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ZStack {
        Theme.sky
        EmberView { }
    }
    .ignoresSafeArea()
}
