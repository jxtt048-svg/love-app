import SwiftUI
import UIKit

enum Phase {
    case waiting
    case revealing
    case revealed
}

struct ContentView: View {
    @State private var phase: Phase = .waiting
    @State private var starsDim: Double = 1.0
    @State private var messageProgress: Double = 0.0
    @State private var showHearts = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SkyView(dim: starsDim, reduceMotion: reduceMotion)

                if phase == .waiting {
                    EmberView(reduceMotion: reduceMotion, action: reveal)
                        .transition(.opacity.combined(with: .scale(scale: 1.4)))
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.58)
                }

                // Decorative and non-interactive: it must never swallow the
                // ember's tap while it is sitting at zero opacity.
                MessageView(progress: messageProgress, reduceMotion: reduceMotion)
                    .allowsHitTesting(false)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.50)

                if showHearts {
                    HeartsView(reduceMotion: reduceMotion)
                        .transition(.opacity)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.50)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .background(Theme.sky)
    }

    /// The one interaction. Fires once; every later tap is ignored.
    private func reveal() {
        guard phase == .waiting else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // The ember flares and goes.
        withAnimation(.easeOut(duration: Theme.Timing.emberFlare)) {
            phase = .revealing
        }

        // The sky holds its breath, then recovers.
        withAnimation(.easeOut(duration: Theme.Timing.starDim)) {
            starsDim = 0.35
        }

        // The message blooms a beat later.
        withAnimation(.spring(response: Theme.Timing.bloom, dampingFraction: 0.72).delay(0.12)) {
            messageProgress = 1.0
            phase = .revealed
        }

        withAnimation(.easeOut(duration: 0.3)) {
            showHearts = true
        }

        withAnimation(.easeInOut(duration: 1.2).delay(1.4)) {
            starsDim = 1.0
        }

        // Hearts are spent after the moment is over.
        Task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.easeOut(duration: 0.4)) {
                showHearts = false
            }
        }
    }
}

#Preview {
    ContentView()
}
