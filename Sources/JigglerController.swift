import AppKit
import ApplicationServices

final class JigglerController {
    private let settings: Settings
    private var timer: Timer?
    private var lastJiggle = ProcessInfo.processInfo.systemUptime
    private var pendingReturn: DispatchWorkItem?
    private var returnPosition: CGPoint?
    private var displacedPosition: CGPoint?
    var onPermissionLost: (() -> Void)?

    init(settings: Settings) { self.settings = settings }
    static var hardwareIdle: TimeInterval {
        CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .init(rawValue: ~UInt32(0))!)
    }
    func start() {
        stop()
        lastJiggle = ProcessInfo.processInfo.systemUptime
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        timer.tolerance = 0.2
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    func stop() {
        timer?.invalidate()
        timer = nil
        pendingReturn?.cancel()
        pendingReturn = nil
        restoreCursorIfUntouched()
    }
    private func tick() {
        guard AXIsProcessTrusted() else {
            stop()
            onPermissionLost?()
            return
        }
        let now = ProcessInfo.processInfo.systemUptime
        guard JigglePolicy.isDue(idle: Self.hardwareIdle, threshold: settings.idleThreshold,
                                 elapsed: now - lastJiggle, interval: settings.interval),
              !mouseButtonIsDown, let original = CGEvent(source: nil)?.location,
              let destination = destination(from: original) else { return }
        lastJiggle = now
        returnPosition = original
        displacedPosition = destination
        postMovement(to: destination)
        let work = DispatchWorkItem { [weak self] in self?.restoreCursorIfUntouched() }
        pendingReturn = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }
    private var mouseButtonIsDown: Bool {
        (0..<32).contains { CGEventSource.buttonState(.combinedSessionState, button: CGMouseButton(rawValue: UInt32($0))!) }
    }
    private func destination(from point: CGPoint) -> CGPoint? {
        var displays = [CGDirectDisplayID](repeating: 0, count: 32)
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(UInt32(displays.count), &displays, &count) == .success else { return nil }
        for display in displays.prefix(Int(count)) {
            if let destination = JigglePolicy.destination(from: point, in: CGDisplayBounds(display)) {
                return destination
            }
        }
        return nil
    }
    private func postMovement(to point: CGPoint) {
        // Session-tap events with a private source keep hardware idle tracking separate.
        guard let source = CGEventSource(stateID: .privateState),
              let event = CGEvent(mouseEventSource: source, mouseType: .mouseMoved,
                                  mouseCursorPosition: point, mouseButton: .left) else { return }
        source.localEventsSuppressionInterval = 0
        event.post(tap: .cgSessionEventTap)
    }
    private func restoreCursorIfUntouched() {
        defer {
            returnPosition = nil
            displacedPosition = nil
            pendingReturn = nil
        }
        guard let original = returnPosition, let displaced = displacedPosition,
              AXIsProcessTrusted(), !mouseButtonIsDown, Self.hardwareIdle >= 0.15,
              let current = CGEvent(source: nil)?.location,
              abs(current.x - displaced.x) < 0.5, abs(current.y - displaced.y) < 0.5 else { return }
        postMovement(to: original)
    }
}
