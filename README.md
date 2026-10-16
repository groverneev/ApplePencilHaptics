# Pencil Haptics

An iPad app that keeps your **Apple Pencil Pro** buzzing while you hover or draw, with a big on/off switch. You can also squeeze the pencil to turn haptics on or off.

## Features

- **Haptics on/off**: one switch, and the setting is remembered between launches.
- **Squeeze to toggle**: squeeze Apple Pencil Pro over the canvas to flip haptics on or off. When you turn them on, you feel a confirmation pulse.
- **Constant mode**: pulses continuously, 2–40 times per second, while the pencil touches or hovers over the canvas.
- **While Moving mode**: pulses every N points the pencil travels, so it feels like a texture under the tip.
- **Feel**: choose a light tick or a firm tap.
- **Play while hovering**: choose whether haptics also play while the pencil hovers above the screen.
- A drawing canvas, with a Clear button, to try it all out.

## Requirements

- An iPad that supports Apple Pencil Pro (iPad Pro M4 or later, iPad Air M2 or later, iPad mini A17 Pro)
- Apple Pencil Pro
- iPadOS 17.5 or later
- **Settings › Apple Pencil › Haptic Feedback** turned on

## Run it

### On your iPad (no Mac needed)

1. Install **Swift Playgrounds** from the App Store.
2. Download this repository as a ZIP from GitHub (Code › Download ZIP) and unzip it in the Files app.
3. Tap **`PencilHaptics.swiftpm`**. It opens in Swift Playgrounds.
4. Tap ▶︎ to run it. To install it as a standalone app on your Home Screen, use **App Settings › Install on Device** (Swift Playgrounds 4.5+).

### On a Mac

Open `PencilHaptics.swiftpm` in Xcode 15.4 or later, pick your iPad as the run destination, set your team under Signing & Capabilities, and run.

## Limitations

iPadOS does **not** let third-party apps change the system-wide pencil haptics setting, or play pencil haptics while you're using a different app. Apps can only trigger Apple Pencil Pro haptics (via `UICanvasFeedbackGenerator`) inside their own views. So the constant haptics work while you're in this app's canvas. To turn pencil haptics off system-wide, use Settings › Apple Pencil.

## Project layout

```
PencilHaptics.swiftpm/
├── Package.swift               App manifest (Swift Playgrounds / Xcode)
├── PencilHapticsApp.swift      App entry point
├── ContentView.swift           Settings sidebar and canvas UI
├── HapticCanvas.swift          Canvas that tracks the pencil and plays haptics
└── HapticConfiguration.swift   Modes, patterns and settings model
```
