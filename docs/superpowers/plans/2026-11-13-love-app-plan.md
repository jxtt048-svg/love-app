# Love App — Implementation Plan

**Spec:** `docs/superpowers/specs/2026-11-13-love-app-design.md`
**Date:** 2026-11-13
**Status:** Awaiting review

## How this gets verified

There is no Swift toolchain on this Windows machine, so **no task below can be compiled locally**. Every task is written carefully and verified by the CI build on GitHub Actions, which is the only compiler in the loop. That constraint drives three rules:

1. Commit small. One task per commit, so a compile failure points at a small diff.
2. Run the CI build after every commit that touches Swift, not at the end.
3. Prefer plain, boring SwiftUI APIs over anything version-sensitive.

Task 0 has to happen before any Swift is written, because until the workflow exists there is no feedback loop.

## Task 0 — Repository and feedback loop

**Files:** `.gitignore`, `.github/workflows/build.yml`, `README.md`

1. `git init`, default branch `main`.
2. `.gitignore`: `build/`, `DerivedData/`, `*.xcodeproj`, `.DS_Store`.
3. Write `build.yml` per spec §8.2: `macos-15`, checkout, Mint-pinned XcodeGen, `xcodebuild` with signing disabled, package `Payload/` into `LoveApp.ipa`, upload artifact.
4. Write `README.md`: what the app is, how to download the artifact, how to sign with Sideloadly, the 7-day expiry note.
5. Create the GitHub repo, push, run the workflow manually.

**Verification:** the workflow runs and fails at `xcodegen generate` because `project.yml` does not exist yet. That failure is the correct outcome and proves the pipeline is wired.

## Task 1 — XcodeGen project definition

**Files:** `project.yml`, `LoveApp/Info.plist` (only if XcodeGen's generated plist cannot express a setting)

```yaml
name: LoveApp
options:
  bundleIdPrefix: com.karan
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
targets:
  LoveApp:
    type: application
    platform: iOS
    sources: [LoveApp]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.karan.loveapp
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        SUPPORTS_MACCATALYST: NO
        TARGETED_DEVICE_FAMILY: "1"
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        CODE_SIGN_STYLE: Manual
    info:
      path: LoveApp/Info.plist
      properties:
        CFBundleDisplayName: Love
        UILaunchScreen: {}
        UIStatusBarHidden: true
        UIViewControllerBasedStatusBarAppearance: false
        UISupportedInterfaceOrientations: [UIInterfaceOrientationPortrait]
        UISupportedInterfaceOrientations~ipad: []
        ITSAppUsesNonExemptEncryption: false
```

**Verification:** CI gets past `xcodegen generate` and fails at compile, because there are no Swift files in the target yet.

## Task 2 — Theme

**Files:** `LoveApp/Theme.swift`

- `enum Theme` with static `Color` values: `sky`, `deepBlue`, `rose`, `blush`, `starlight` (hex per spec §5.1, via a `Color(hex:)` initialiser or explicit sRGB components — prefer explicit components to avoid a hex parser).
- `static let message = "I love you"` — the single source of truth for the copy.
- Timing constants as a nested `enum Timing`: `emberPulse = 2.4`, `flair = 0.18`, `starDim = 0.25`, `bloom = 0.78`, `heartStagger = 0.3`, `heartLife = 3.5`, `haloBreath = 4.5`.

**Verification:** CI compiles. No behaviour yet.

## Task 3 — App shell

**Files:** `LoveApp/LoveApp.swift`, `LoveApp/ContentView.swift`

- `@main struct LoveApp: App` with `WindowGroup { ContentView() }`, `.preferredColorScheme(.dark)`, `.statusBarHidden(true)`.
- `ContentView` holds `@State private var phase: Phase = .waiting` and an empty `ZStack` for now, on top of a `Color.black`.
- `enum Phase { case waiting, revealing, revealed }` defined in `ContentView.swift`.

**Verification:** CI green — this is the first commit that produces a real, installable app (a black screen). Install it once at this point to confirm the whole chain works end to end before adding animation. If signing or install has a problem, better to discover it here than after the animation exists.

## Task 4 — Sky

**Files:** `LoveApp/SkyView.swift`

- Vertical `LinearGradient` from `deepBlue` to `sky`.
- `Canvas` inside `TimelineView(.animation)` drawing 60 stars.
- Stars are seeded deterministically from a fixed `UInt64` so the sky is identical on every launch: position, radius (0.6–1.8 pt), base opacity (0.25–0.8), drift speed (0.5–2.0 pt/s), twinkle period (3–7 s).
- Drift is vertical, wrapping at the top edge.
- Input: `dim: Double` (0–1), multiplied into star opacity. `1.0` = full brightness.
- Star count and geometry scale with the canvas size, computed once per size change.

**Verification:** CI green. Star field visible on a black screen, moving slowly.

## Task 5 — Ember

**Files:** `LoveApp/EmberView.swift`

- `Button` with `action`, 88×88 pt frame, `.buttonStyle(.plain)`.
- Visual: 56 pt circle filled with `rose`, overlaid `RadialGradient` halo from `blush` 45% to clear, blurred 12 pt.
- Pulse: driven by `TimelineView(.animation)` computing a 0…1 sine from time and the 2.4 s period; scale 1.0→1.06, halo opacity 0.35→0.6.
- When `reduceMotion` is on, scale stays at 1.0 and only opacity breathes.
- Accessibility: `.accessibilityLabel("Reveal a message")`, `.accessibilityAddTraits(.isButton)`.

**Verification:** CI green. Ember pulses in the lower third; tapping does nothing visible yet, but the haptic fires if wired in Task 8.

## Task 6 — Message

**Files:** `LoveApp/MessageView.swift`

- `Text(Theme.message)` in `.system(size: messageSize, weight: .light, design: .serif)`, `@ScaledMetric(relativeTo: .largeTitle) private var messageSize = 44.0`.
- `.tracking(1.5)`, `.foregroundStyle(Theme.starlight.opacity(0.96))`, `.shadow(color: Theme.rose.opacity(0.35), radius: 18)`.
- `.lineLimit(1)`, `.minimumScaleFactor(0.6)`, `.multilineTextAlignment(.center)`, horizontal padding 32.
- Behind it: `RadialGradient` halo, `blush` 22% → `rose` 10% → clear, blurred, sized 2.2× the text's width.
- Input: `progress: Double` (0–1). Scale = `0.82 + 0.18 * progress`; opacity = `progress`. With `reduceMotion`, scale is fixed at 1.0.
- Accessibility: `.accessibilityLabel(Theme.message)`; hidden when `progress < 0.5` so VoiceOver does not announce a half-faded string.

**Verification:** CI green. Hardcode `progress` in a preview to inspect all three states.

## Task 7 — Hearts

**Files:** `LoveApp/HeartsView.swift`

- Six hearts rendered as `Image(systemName: "heart.fill")` views, each with fixed seeded parameters: start x offset (−110…110 pt), start delay (0, 0.3, … 1.5 s), rise height (120–220 pt), horizontal wander (±18 pt), size (10–16 pt), lifetime 2.4 s.
- Heart shape: two arcs plus a path, or `Image(systemName: "heart.fill")` tinted `rose` at 85% opacity. Use the SF Symbol — it is one line and the shape is already correct.
- Behaviour: `progress ≤ 0` draws nothing; `0 < progress < 1` is animating; `progress ≥ 1` draws nothing. Once finished, the view is removed from the tree by the parent.
- Reduce Motion: hearts fade in place at their start positions instead of rising.
- Decorative only: `.accessibilityHidden(true)`.

**Verification:** CI green. Hearts rise once and vanish.

## Task 8 — Wire it together

**Files:** `LoveApp/ContentView.swift`

- `ZStack`: sky, ember (when `phase == .waiting`), message, hearts.
- Tap handler: guard `phase == .waiting`, fire `UIImpactFeedbackGenerator(style: .light).impactOccurred()`, set `phase = .revealing`, then `withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.12)) { phase = .revealed }` and a `Task.sleep` of 4 s to retire the hearts view.
- `starDim`: 1.0 in `.waiting`, animated to 0.35 then back to 1.0 over 1.2 s in `.revealed`.
- `messageProgress`: 0 in `.waiting`; driven by the spring in `.revealing`/`.revealed`.
- Wrap all animation amounts so `accessibilityReduceMotion` swaps drift/scale for fades, per spec §7.

**Verification:** CI green, then install and run the 10-point manual checklist from spec §9.

## Task 9 — Icon and finishing

**Files:** `LoveApp/Assets.xcassets/**`, `README.md`

- `AppIcon.appiconset` with a single 1024×1024 PNG: `sky` background, a soft `rose` ember glow, no text. Generated programmatically or drawn by hand — it must be opaque and text-free.
- `AccentColor.colorset` set to `rose`.
- README gets a screenshot-free "what it looks like" paragraph and the exact Sideloadly steps.

**Verification:** CI green; icon appears on the home screen after install.

## Execution order and cost

Tasks are strictly ordered; each depends on the previous one compiling.

| Stage | Tasks | What you can see |
|---|---|---|
| Pipeline | 0–3 | A black app that installs |
| Visuals | 4–7 | Sky, ember, message, hearts — each previewable |
| Moment | 8 | The full interaction |
| Polish | 9 | Icon, docs |

Each task is one commit, one CI run. Expect one or two red builds along the way; that is normal when the compiler lives in the cloud.

## Open questions for the owner

1. **GitHub repo** — public or private? Public gets free macOS minutes; private is billed at ~10× the Linux rate (still cents for a build this size). This plan assumes **public**.
2. **Bundle identifier** — `com.karan.loveapp` is a placeholder. Sideloadly does not care, but if you ever want a paid account, it must be unique to you.
3. **App name on the home screen** — plan says `Love`. Change it in `project.yml` → `CFBundleDisplayName` if you want something else.
