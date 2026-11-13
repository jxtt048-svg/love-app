import SwiftUI

/// Single source of truth for colour, copy, and timing.
enum Theme {

    // MARK: Copy

    /// The only words in the app. Change this line to change the message.
    static let message = "I love you"

    // MARK: Palette

    /// #070A16 — base background, bottom of the sky gradient.
    static let sky = Color(red: 0.027, green: 0.039, blue: 0.086)
    /// #121A33 — top of the sky gradient.
    static let deepBlue = Color(red: 0.071, green: 0.102, blue: 0.200)
    /// #FF6B8A — ember core, hearts, halo tint.
    static let rose = Color(red: 1.000, green: 0.420, blue: 0.541)
    /// #FFC7D4 — halo highlight, ember outer glow.
    static let blush = Color(red: 1.000, green: 0.780, blue: 0.831)
    /// #E9EDFF — stars and message text.
    static let starlight = Color(red: 0.914, green: 0.929, blue: 1.000)

    // MARK: Timing (seconds)

    enum Timing {
        static let emberPulse: Double = 2.4
        static let emberFlare: Double = 0.18
        static let starDim: Double = 0.25
        /// Spring response for the message bloom.
        static let bloom: Double = 0.55
        static let heartStagger: Double = 0.3
        static let heartLife: Double = 2.4
        static let haloBreath: Double = 4.5
    }
}
