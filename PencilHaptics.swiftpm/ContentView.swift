import SwiftUI

struct ContentView: View {
    @AppStorage("hapticsEnabled") private var isEnabled = true
    @AppStorage("hapticMode") private var mode: HapticMode = .constant
    @AppStorage("hapticPattern") private var pattern: HapticPattern = .tick
    @AppStorage("pulsesPerSecond") private var pulsesPerSecond = 15.0
    @AppStorage("pulseSpacing") private var spacing = 20.0
    @AppStorage("playsWhileHovering") private var playsWhileHovering = true
    @AppStorage("squeezeToggles") private var squeezeToggles = true

    @State private var pencilState: PencilState = .away
    @State private var clearRequest = 0

    private var configuration: HapticConfiguration {
        HapticConfiguration(
            isEnabled: isEnabled,
            mode: mode,
            pattern: pattern,
            pulsesPerSecond: pulsesPerSecond,
            spacing: spacing,
            playsWhileHovering: playsWhileHovering,
            squeezeToggles: squeezeToggles
        )
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                settings
                    .frame(width: 360)
                Divider()
                canvas
            }
            .navigationTitle("Pencil Haptics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear", systemImage: "trash") {
                        clearRequest += 1
                    }
                }
            }
        }
    }

    private var settings: some View {
        Form {
            Section {
                Toggle(isOn: $isEnabled.animation()) {
                    Label(
                        isEnabled ? "Haptics On" : "Haptics Off",
                        systemImage: isEnabled ? "waveform" : "waveform.slash"
                    )
                    .font(.headline)
                }
            } footer: {
                if squeezeToggles {
                    Text("Squeeze your Apple Pencil Pro over the canvas to turn haptics on or off.")
                }
            }

            Section("Mode") {
                Picker("Mode", selection: $mode) {
                    ForEach(HapticMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                switch mode {
                case .constant:
                    VStack(alignment: .leading) {
                        LabeledContent("Pulse rate", value: "\(Int(pulsesPerSecond)) per second")
                        Slider(value: $pulsesPerSecond, in: 2...40, step: 1)
                    }
                case .whileMoving:
                    VStack(alignment: .leading) {
                        LabeledContent("Pulse every", value: "\(Int(spacing)) pt")
                        Slider(value: $spacing, in: 4...80, step: 1)
                    }
                }
            }
            .disabled(!isEnabled)

            Section("Feel") {
                Picker("Pattern", selection: $pattern) {
                    ForEach(HapticPattern.allCases) { pattern in
                        Text(pattern.title).tag(pattern)
                    }
                }
                .pickerStyle(.segmented)
            }
            .disabled(!isEnabled)

            Section("Options") {
                Toggle("Play while hovering", isOn: $playsWhileHovering)
                Toggle("Squeeze to toggle", isOn: $squeezeToggles)
            }

            Section("Good to know") {
                Text("Haptics play while your Apple Pencil Pro is on or over the canvas in this app. iPadOS doesn't let apps control pencil haptics in other apps.")
                Text("If you feel nothing, make sure Settings › Apple Pencil › Haptic Feedback is turned on.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private var canvas: some View {
        HapticCanvas(
            configuration: configuration,
            clearRequest: clearRequest,
            onSqueeze: {
                withAnimation { isEnabled.toggle() }
            },
            onPencilStateChange: { state in
                pencilState = state
            }
        )
        .ignoresSafeArea(edges: .bottom)
        .overlay(alignment: .topLeading) {
            statusBadge
                .padding()
        }
        .overlay {
            if pencilState == .away {
                Text("Hover or draw here with Apple Pencil Pro")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
                    .allowsHitTesting(false)
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 12) {
            Label(pencilState.title, systemImage: pencilState.systemImage)
            Divider().frame(height: 16)
            Label(
                isEnabled ? "Haptics on" : "Haptics off",
                systemImage: isEnabled ? "waveform" : "waveform.slash"
            )
            .foregroundStyle(isEnabled ? Color.accentColor : .secondary)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .allowsHitTesting(false)
    }
}

#Preview {
    ContentView()
}
