# Love

A one-button iOS app. A night sky, a small glow, and two words.

Tap the ember. It blooms into "I love you" and drifts away. There is nothing else — no settings, no account, no network, no data collection. Every launch starts over.

Built for a single phone, installed by sideloading. Not on the App Store.

## What it looks like

- Black-to-deep-blue night sky, 60 slowly drifting stars.
- A rose-coloured ember near the bottom, breathing every 2.4 seconds.
- Tap it: light haptic, the stars dim, the message blooms in a serif face with a warm halo, six hearts rise and fade.
- The message stays. The ember does not come back until you relaunch.

## Build it

The build runs on [Cirrus CI](https://cirrus-ci.com) macOS VMs and produces an **unsigned** `.ipa`:

1. Install the Cirrus CI app on this repo, once: <https://github.com/apps/cirrus-ci>
2. Push to `main`, or start a build from the Cirrus dashboard.
3. Open the finished task and download the `ipa` artifact — it is `LoveApp.ipa`.

Locally you need nothing. No Xcode, no Mac, no toolchain.

`project.yml` is the source of truth for the Xcode project; `LoveApp.xcodeproj` is generated in CI by XcodeGen and is never committed.

## Install it (Windows + iPhone)

1. Install [Sideloadly](https://sideloadly.io).
2. Connect the iPhone by USB and trust the computer.
3. On the iPhone: **Settings → Privacy & Security → Developer Mode → On**, then restart.
4. Open Sideloadly, drag in `LoveApp.ipa`, enter your Apple ID, click Start.
   - If your Apple ID has two-factor authentication, generate an app-specific password at [appleid.apple.com](https://appleid.apple.com) and use that instead of your real password.
5. On the iPhone: **Settings → General → VPN & Device Management →** tap your Apple ID → **Trust**.

## The 7-day thing

A free Apple ID signs apps for **7 days**. After that the app stops opening — it is not broken, the certificate expired. Repeat step 4 of the install instructions to re-sign it. Your data and settings are not affected, because there are none.

If that becomes annoying, a paid Apple Developer account ($99/year) signs for a year at a time.

## Repo layout

```
.cirrus.yml                     CI: build unsigned .ipa on a macOS VM
project.yml                     XcodeGen project definition
LoveApp/                        app sources
docs/superpowers/specs/         design spec
docs/superpowers/plans/         implementation plan
```

## Changing the words

`LoveApp/Theme.swift`, one line:

```swift
static let message = "I love you"
```

Commit, let CI rebuild, reinstall.
