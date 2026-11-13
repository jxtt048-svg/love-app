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
                SkyView(dim: starsDim)

                if phase == .waiting {
                    EmberView(reduceMotion: reduceMotion, action: reveal)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.58)
                        .transition(.opacity.combined(with: .scale(scale: 1.4)))
                }

                MessageView(progress: messageProgress, reduceMotion: reduceMotion)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.50)

                if showHearts {
                    HeartsView(reduceMotion: reduceMotion)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.50)
                        .transition(.opacity)
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
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.12)) {
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
