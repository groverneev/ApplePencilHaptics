import SwiftUI
import UIKit

/// SwiftUI wrapper around `HapticCanvasView`.
struct HapticCanvas: UIViewRepresentable {
    var configuration: HapticConfiguration
    /// Increment to erase the drawing.
    var clearRequest: Int
    var onSqueeze: () -> Void
    var onPencilStateChange: (PencilState) -> Void

    final class Coordinator {
        var lastClearRequest = 0
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> HapticCanvasView {
        context.coordinator.lastClearRequest = clearRequest
        return HapticCanvasView()
    }

    func updateUIView(_ canvas: HapticCanvasView, context: Context) {
        canvas.onSqueeze = onSqueeze
        canvas.onPencilStateChange = onPencilStateChange
        canvas.configuration = configuration

        if context.coordinator.lastClearRequest != clearRequest {
            context.coordinator.lastClearRequest = clearRequest
            canvas.clear()
        }
    }
}

/// A simple drawing surface that plays Apple Pencil Pro haptics while the
/// pencil is touching or hovering over it.
///
/// iPadOS only plays app-triggered pencil haptics through
/// `UICanvasFeedbackGenerator`, and only for the view the pencil is
/// interacting with, so the haptics live inside this canvas.
final class HapticCanvasView: UIView, UIPencilInteractionDelegate {
    var configuration = HapticConfiguration() {
        didSet {
            guard configuration != oldValue else { return }
            updatePulseTimer()
        }
    }
    var onSqueeze: (() -> Void)?
    var onPencilStateChange: ((PencilState) -> Void)?

    private lazy var feedbackGenerator = UICanvasFeedbackGenerator(view: self)
    private var pulseTimer: Timer?

    private var pencilState: PencilState = .away {
        didSet {
            guard pencilState != oldValue else { return }
            onPencilStateChange?(pencilState)
            updatePulseTimer()
        }
    }
    private var lastPencilLocation: CGPoint = .zero
    private var distanceSinceLastPulse: CGFloat = 0

    private var strokes: [UIBezierPath] = []
    private var currentStroke: UIBezierPath?
    private var activeTouch: UITouch?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        contentMode = .redraw
        isMultipleTouchEnabled = true

        let hover = UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:)))
        addGestureRecognizer(hover)

        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = self
        addInteraction(pencilInteraction)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func clear() {
        strokes.removeAll()
        currentStroke = nil
        setNeedsDisplay()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updatePulseTimer()
    }

    override func draw(_ rect: CGRect) {
        UIColor.label.setStroke()
        for stroke in strokes {
            stroke.stroke()
        }
        currentStroke?.stroke()
    }

    // MARK: - Haptics

    private var isPencilActive: Bool {
        switch pencilState {
        case .touching: return true
        case .hovering: return configuration.playsWhileHovering
        case .away: return false
        }
    }

    private func updatePulseTimer() {
        let shouldRun = window != nil
            && configuration.isEnabled
            && configuration.mode == .constant
            && isPencilActive

        guard shouldRun else {
            pulseTimer?.invalidate()
            pulseTimer = nil
            return
        }

        let interval = 1 / max(configuration.pulsesPerSecond, 1)
        if let pulseTimer, abs(pulseTimer.timeInterval - interval) < 0.0001 {
            return
        }

        pulseTimer?.invalidate()
        feedbackGenerator.prepare()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.playFeedback(at: self.lastPencilLocation)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pulseTimer = timer
    }

    private func playFeedback(at location: CGPoint) {
        switch configuration.pattern {
        case .tick: feedbackGenerator.alignmentOccurred(at: location)
        case .tap: feedbackGenerator.pathCompleted(at: location)
        }
        feedbackGenerator.prepare()
    }

    /// Records pencil movement and, in "While Moving" mode, plays a pulse
    /// every `spacing` points of travel.
    private func trackMovement(to location: CGPoint, playsHaptics: Bool) {
        distanceSinceLastPulse += hypot(location.x - lastPencilLocation.x, location.y - lastPencilLocation.y)
        lastPencilLocation = location

        guard playsHaptics, configuration.isEnabled, configuration.mode == .whileMoving else { return }
        let spacing = CGFloat(max(configuration.spacing, 1))
        if distanceSinceLastPulse >= spacing {
            distanceSinceLastPulse = distanceSinceLastPulse.truncatingRemainder(dividingBy: spacing)
            playFeedback(at: location)
        }
    }

    // MARK: - Hover

    @objc private func handleHover(_ recognizer: UIHoverGestureRecognizer) {
        // Touch handling owns the state while the pencil is on the glass.
        guard pencilState != .touching else { return }
        let location = recognizer.location(in: self)

        switch recognizer.state {
        case .began:
            lastPencilLocation = location
            distanceSinceLastPulse = 0
            pencilState = .hovering
        case .changed:
            if pencilState == .away {
                lastPencilLocation = location
                distanceSinceLastPulse = 0
                pencilState = .hovering
            }
            trackMovement(to: location, playsHaptics: configuration.playsWhileHovering)
        case .ended, .cancelled, .failed:
            pencilState = .away
        default:
            break
        }
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first(where: { $0.type == .pencil }) else { return }
        activeTouch = touch

        let location = touch.location(in: self)
        let stroke = UIBezierPath()
        stroke.lineWidth = 3
        stroke.lineCapStyle = .round
        stroke.lineJoinStyle = .round
        stroke.move(to: location)
        stroke.addLine(to: location)
        currentStroke = stroke

        lastPencilLocation = location
        distanceSinceLastPulse = 0
        pencilState = .touching

        if configuration.isEnabled {
            playFeedback(at: location)
        }
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let samples = event?.coalescedTouches(for: touch) ?? [touch]
        for sample in samples {
            let location = sample.location(in: self)
            currentStroke?.addLine(to: location)
            trackMovement(to: location, playsHaptics: true)
        }
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endStroke(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endStroke(touches)
    }

    private func endStroke(_ touches: Set<UITouch>) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        if let currentStroke {
            strokes.append(currentStroke)
        }
        currentStroke = nil
        activeTouch = nil
        // Hover recognition resumes on its own once the pencil lifts.
        pencilState = .away
        setNeedsDisplay()
    }

    // MARK: - Squeeze (Apple Pencil Pro)

    func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveSqueeze squeeze: UIPencilInteraction.Squeeze) {
        guard configuration.squeezeToggles, squeeze.phase == .ended else { return }
        let isTurningOn = !configuration.isEnabled
        onSqueeze?()

        // Confirm "on" with a pulse so you can feel the toggle.
        if isTurningOn, let location = squeeze.hoverPose?.location {
            playFeedback(at: location)
        }
    }
}
