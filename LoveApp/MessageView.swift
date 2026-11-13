import SwiftUI

/// The message and its halo. `progress` goes 0 → 1 as the bloom happens.
struct MessageView: View {
    var progress: Double
    var reduceMotion: Bool = false

    @ScaledMetric(relativeTo: .largeTitle) private var messageSize: CGFloat = 44

    @State private var haloBreathing = false

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Theme.blush.opacity(0.22),
                    Theme.rose.opacity(0.10),
                    Color.clear
                ],
                center: .center,
                startRadius: 8,
                endRadius: 190
            )
            .frame(width: 380, height: 260)
            .blur(radius: 24)
            // Settles at 12% and breathes up to 18% of the gradient's own alpha.
            .opacity(progress * (haloBreathing ? 0.82 : 0.55))

            Text(Theme.message)
                .font(.system(size: messageSize, weight: .light, design: .serif))
                .tracking(1.5)
                .foregroundStyle(Theme.starlight.opacity(0.96))
                .shadow(color: Theme.rose.opacity(0.35), radius: 18)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .scaleEffect(CGFloat(reduceMotion ? 1.0 : 0.82 + 0.18 * progress))
                .opacity(progress)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Theme.message)
        .accessibilityHidden(progress < 0.5)
        .onAppear {
            withAnimation(
                .easeInOut(duration: Theme.Timing.haloBreath).repeatForever(autoreverses: true)
            ) {
                haloBreathing = true
            }
        }
    }
}

#Preview("Waiting") {
    ZStack {
        Theme.sky
        MessageView(progress: 0)
    }
    .ignoresSafeArea()
}

#Preview("Bloom") {
    ZStack {
        Theme.sky
        MessageView(progress: 0.5)
    }
    .ignoresSafeArea()
}

#Preview("Settled") {
    ZStack {
        Theme.sky
        MessageView(progress: 1)
    }
    .ignoresSafeArea()
}
