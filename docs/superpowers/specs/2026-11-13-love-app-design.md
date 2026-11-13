# Love App — Design Spec

**Date:** 2026-11-13
**Status:** Approved (design), pending spec review
**Owner:** Karan

## 1. Purpose

A single-purpose iOS app for the owner's own phone. It shows a quiet night sky with one small glowing ember. Tapping the ember reveals the words **"I love you"** in a single, warm moment. There is nothing else in the app.

Success is simple: open it, tap once, feel something. No accounts, no settings, no data, no network.

## 2. Scope

**In scope**

- One screen, one interaction, one message.
- Night sky with slow-drifting stars.
- A pulsing ember that acts as the only control.
- A reveal animation that ends with the message displayed.
- Light haptic feedback on tap.
- Built in CI as an unsigned `.ipa`, signed locally with Sideloadly.

**Out of scope**

- Persistence. Every launch starts at the ember again. There is no saved state and no "already revealed" flag.
- Configurable message. The text lives in one constant so it can be changed in a single edit, but there is no in-app UI to change it.
- Notifications, sound, sharing, analytics, onboarding, settings.
- App Store distribution, iPad layout, landscape layout, watchOS.
- Any BGMI or game-related functionality. This app has no connection to any game.

## 3. Platform and constraints

| Item | Decision |
|---|---|
| Language / UI | Swift + SwiftUI, no third-party dependencies |
| Minimum iOS | 17.0 |
| Devices | iPhone, portrait only |
| Signing | Free Apple ID via Sideloadly |
| Expiry | App stops launching ~7 days after signing; re-sign to continue |
| Build host | GitHub Actions macOS runner (no local Xcode available) |
| Project format | `project.yml` for XcodeGen (no hand-maintained `.xcodeproj`) |

Free-account limitations are accepted: no push, no iCloud, no App Groups, no background modes. The app needs none of them.

## 4. Experience

### 4.1 States

A single enum drives the screen:

```swift
enum Phase {
    case waiting    // ember pulsing, stars drifting
    case revealing  // tap registered, stars dim, message blooming
    case revealed   // message settled, ember gone
}
```

Transition is one-way. There is no way back to `.waiting` without relaunching the app.

### 4.2 The moment

1. **Launch.** Sky fades up from black over 400 ms. Stars are already drifting; they are not drawn in, they just appear.
2. **Waiting.** An ember sits at 58% of screen height, horizontally centered. It breathes: scale 1.0 → 1.06 → 1.0 over 2.4 s, with the glow's opacity rising in step. No text, no hint, no arrow. The pulse is the invitation.
3. **Tap.** A `UIImpactFeedbackGenerator` light impact fires immediately.
4. **Revealing (0–600 ms).** The ember flares to 1.4× and fades out over 180 ms. Star brightness drops to 35% over 250 ms, as if the sky is holding its breath.
5. **Bloom (120–900 ms).** "I love you" scales from 0.82 to 1.0 with a soft spring (response 0.55, damping 0.72) while fading 0 → 1. A rose-coloured radial halo behind it fades in to 22% opacity and then settles to 12%.
6. **Hearts (400–3900 ms).** Six hearts spawn near the message, drift upward 120–220 pt with a slight horizontal wander, fade out, and are removed. Staggered 300 ms apart.
7. **Settled.** Message stays at full opacity. Halo breathes very slowly (4.5 s period, 12% ↔ 18%). Stars return to 100% brightness over 1.2 s. Ember never returns.

Total time from tap to settled state: ~4 s. The message is legible from ~900 ms onward.

### 4.3 Interaction details

- The ember's tap target is 88×88 pt even though the visible glow is ~56 pt.
- Taps during `.revealing` or `.revealed` are ignored.
- App relaunch returns to `.waiting`.
- No navigation, no back gesture, no swipe actions.

## 5. Visual design

### 5.1 Palette

| Token | Hex | Use |
|---|---|---|
| `sky` | `#070A16` | Base background |
| `deepBlue` | `#121A33` | Vertical gradient top, halo core shadow |
| `rose` | `#FF6B8A` | Ember core, hearts, halo tint |
| `blush` | `#FFC7D4` | Halo highlight, ember outer glow |
| `starlight` | `#E9EDFF` | Star fill, message text |

Background is a vertical linear gradient from `deepBlue` at the top to `sky` at the bottom. The halo is a `RadialGradient` from `blush` at 22% through `rose` at 10% to clear.

Message text is `starlight` at 96% opacity with a soft `rose` shadow (radius 18, opacity 0.35) so it reads as emitting light rather than sitting on top of it.

### 5.2 Type

One typeface: **New York** (system serif, `Font.Design.serif`). No second family.

- Message: serif, `.light` weight, 44 pt base, tracking `1.5`, line spacing default, centered, single line, `minimumScaleFactor(0.6)` so narrow devices still fit.
- Size scales with Dynamic Type via `@ScaledMetric(relativeTo: .largeTitle)`.
- No other text exists in the app.

Tracking is deliberately loose; at 44 pt it slows the eye down and reads as written rather than rendered.

### 5.3 Layout

```
┌──────────────────┐
│  ·    ·      ·   │   stars: 60 pts, seeded, slow drift
│     ·     ·      │
│  ·          ·    │
│                  │
│                  │
│       ( ◍ )      │   ember at y = 58% of height
│                  │
│                  │
└──────────────────┘

after tap:

┌──────────────────┐
│  ·        ·      │   stars dimmed then restored
│      ♥   ♥       │   hearts rising
│    I love you    │   centered, y = 50%
│   ♥          ♥   │
│                  │
└──────────────────┘
```

Everything centered on the horizontal axis. Nothing pinned to an edge. The status bar is hidden and the app runs edge-to-edge; the home indicator still appears when iOS chooses to show it, so nothing is placed within 24 pt of the bottom edge.

### 5.4 Motion principles

- One orchestrated moment, not scattered effects. Nothing animates before the tap except the ember and the stars, and those are slow enough to read as ambient, not decorative.
- Every animation serves either invitation (ember pulse) or consequence (tap result).
- Ambient motion never exceeds 0.06 scale change or 2 pt/s drift.
- No bounce, no overshoot beyond the spring's own settle, no rotation.

## 6. Architecture

Four small views plus one theme file. Each has one job and no dependency on the others' internals.

```
LoveApp/
  LoveApp.swift        App entry. Hides status bar, sets portrait-only, black launch screen.
  ContentView.swift    Owns Phase state, composes the layers, handles the tap.
  SkyView.swift        Star field and background gradient. Input: dimming amount.
  EmberView.swift      The pulsing ember. Input: pulse phase. Calls back on tap.
  MessageView.swift    "I love you" + halo. Input: reveal progress.
  HeartsView.swift     Rising hearts, self-contained animation on appear.
  Theme.swift          Palette constants, message string, timing constants.
```

Dependencies point one way: `ContentView` → the four visual views → `Theme`. No view reads state from another view; all inputs arrive as plain values (progress, dimming, phase).

`SkyView` and `HeartsView` use `TimelineView(.animation)` with a `Canvas`, which keeps them cheap and gives deterministic motion without a timer or a `CADisplayLink`.

`Theme.swift` holds the single source of truth for the message string, so changing the words is a one-line edit.

## 7. Accessibility

- **VoiceOver:** the ember exposes `.accessibilityLabel("Reveal a message")` and `.accessibilityAddTraits(.isButton)`. After reveal, the message is an accessibility element labelled `"I love you"`, and the ember is removed from the accessibility tree.
- **Reduce Motion:** when `accessibilityReduceMotion` is on, hearts fade in place instead of drifting, the bloom becomes a 300 ms crossfade with no scale, and the ember pulse becomes a static glow with only opacity breathing. No large positional movement occurs.
- **Contrast:** `starlight` on `sky` is ~16:1. The ember's visible glow is decorative; the tappable area is the full 88 pt target, which exceeds the 44 pt minimum.
- **Dynamic Type:** the message scales with the user's text size and is allowed to shrink to 60% to stay on one line.
- **No time-limited content:** nothing disappears, so there is no duration requirement.

## 8. Build and distribution

### 8.1 Repository layout

```
project.yml
LoveApp/
  (sources listed above)
  Assets.xcassets/    AppIcon set (single 1024 px placeholder), accent colour
.github/workflows/build.yml
README.md             How to build and sideload
docs/superpowers/specs/2026-11-13-love-app-design.md
```

### 8.2 CI pipeline

Trigger: push to `main`, plus manual `workflow_dispatch`.

1. `macos-15` runner (Xcode 16.x), `actions/checkout`.
2. `brew install mint`, then `mint install yonaskolb/XcodeGen@2.44.1` (pinned), then `mint run xcodegen generate`.
3. `xcodebuild -project LoveApp.xcodeproj -scheme LoveApp -configuration Release -sdk iphoneos -derivedDataPath build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build`
4. Package: `mkdir Payload && cp -R build/Build/Products/Release-iphoneos/LoveApp.app Payload/ && zip -r LoveApp.ipa Payload`
5. Upload `LoveApp.ipa` with `actions/upload-artifact@v4`, retention 30 days.

Failure handling: the workflow fails loudly on any compile error. There is no partial artifact.

### 8.3 Local install (owner's phone)

1. Download `LoveApp.ipa` from the Actions run.
2. Connect iPhone, trust the computer.
3. Enable Settings → Privacy & Security → Developer Mode, reboot.
4. Sideloadly: drag in the `.ipa`, sign in with the free Apple ID (app-specific password if 2FA), start. Sideloadly signs with a development certificate and installs.
5. On the phone: Settings → General → VPN & Device Management → trust the developer certificate.
6. When the app stops opening after ~7 days, repeat step 4.

## 9. Testing

There is no meaningful unit-test surface: one view, one state transition, no data. Testing is therefore:

- **CI compile check** — a green build is the primary automated signal.
- **Preview harness** — SwiftUI previews for `.waiting`, `.revealing`, and `.revealed`, so each phase can be inspected without a device.
- **Manual pass on device** — the checklist below, run once after the first successful install.

Manual checklist:

1. Launch → sky fades up, ember pulses, no other UI visible.
2. Tap ember → haptic, ember disappears, message appears within 1 second.
3. Message is fully legible and centered on a 5.4" and a 6.7" device.
4. Hearts rise and disappear; nothing remains floating.
5. Tapping again after reveal does nothing.
6. Relaunch → back to ember.
7. VoiceOver on → ember announced as "Reveal a message", button trait present.
8. Reduce Motion on → no drifting hearts, no bloom scale.
9. Largest Dynamic Type → message still on one line.
10. Rotate device → app stays portrait.

## 10. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| macOS runner Xcode version lags iOS 17 SDK | Build failure | Pin `macos-15`; the app targets iOS 17 and uses no bleeding-edge APIs |
| Free-cert 7-day expiry surprises the owner | App appears broken | Documented in README and repeat step in §8.3 |
| XcodeGen breaks on a future Xcode | Build failure | XcodeGen pinned to a specific version in CI |
| Canvas animation cost on older phones | Battery drain | Only 60 stars and 6 hearts; `TimelineView` is paused when the app is backgrounded by the system |

## 11. Open questions

None. All decisions needed for implementation are settled in this document.
