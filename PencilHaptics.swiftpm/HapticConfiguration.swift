import Foundation

/// How the app decides when to play haptic pulses on the pencil.
enum HapticMode: String, CaseIterable, Identifiable {
    /// Pulse at a fixed rate for as long as the pencil is on (or over) the canvas.
    case constant
    /// Pulse each time the pencil travels a set distance, like a texture.
    case whileMoving

    var id: String { rawValue }

    var title: String {
        switch self {
        case .constant: return "Constant"
        case .whileMoving: return "While Moving"
        }
    }
}

/// The two feedback styles Apple Pencil Pro supports through `UICanvasFeedbackGenerator`.
enum HapticPattern: String, CaseIterable, Identifiable {
    case tick
    case tap

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tick: return "Light Tick"
        case .tap: return "Firm Tap"
        }
    }
}

/// Where the pencil currently is relative to the canvas.
enum PencilState: Equatable {
    case away
    case hovering
    case touching

    var title: String {
        switch self {
        case .away: return "Pencil away"
        case .hovering: return "Hovering"
        case .touching: return "Touching"
        }
    }

    var systemImage: String {
        switch self {
        case .away: return "pencil.slash"
        case .hovering: return "hand.point.up.left"
        case .touching: return "pencil.tip"
        }
    }
}

struct HapticConfiguration: Equatable {
    var isEnabled = true
    var mode: HapticMode = .constant
    var pattern: HapticPattern = .tick
    /// Pulses per second in `.constant` mode.
    var pulsesPerSecond: Double = 15
    /// Points of pencil travel between pulses in `.whileMoving` mode.
    var spacing: Double = 20
    var playsWhileHovering = true
    var squeezeToggles = true
}
