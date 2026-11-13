import SwiftUI

enum Phase {
    case waiting
    case revealing
    case revealed
}

struct ContentView: View {
    @State private var phase: Phase = .waiting

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
