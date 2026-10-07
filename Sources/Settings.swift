import Foundation
import CoreGraphics

final class Settings {
    static let intervals: [TimeInterval] = [30, 45, 60, 90, 120]
    static let idleThresholds: [TimeInterval] = [0, 60, 120, 240, 300]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["jiggler.interval": 60.0, "jiggler.idleThreshold": 240.0,
                                     "jiggler.enabled": false])
    }
    var enabled: Bool {
        get { defaults.bool(forKey: "jiggler.enabled") }
        set { defaults.set(newValue, forKey: "jiggler.enabled") }
    }
    var interval: TimeInterval {
        get {
            let value = defaults.double(forKey: "jiggler.interval")
            return Self.intervals.contains(value) ? value : 60
        }
        set { defaults.set(newValue, forKey: "jiggler.interval") }
    }
    var idleThreshold: TimeInterval {
        get {
            let value = defaults.double(forKey: "jiggler.idleThreshold")
            return Self.idleThresholds.contains(value) ? value : 240
        }
        set { defaults.set(newValue, forKey: "jiggler.idleThreshold") }
    }
}

enum URLCommand: String {
    case toggle, on, off
    init?(url: URL) {
        guard url.scheme?.lowercased() == "mxjiggler", url.user == nil,
              url.password == nil, url.port == nil, url.query == nil, url.fragment == nil,
              url.path.isEmpty || url.path == "/",
              let host = url.host?.lowercased(), let command = Self(rawValue: host) else { return nil }
        self = command
    }
}

enum JigglePolicy {
    static func isDue(idle: TimeInterval, threshold: TimeInterval,
                      elapsed: TimeInterval, interval: TimeInterval) -> Bool {
        idle.isFinite && idle >= threshold && elapsed >= interval
    }
    // Use Quartz coordinates throughout; never convert through NSScreen.
    static func destination(from point: CGPoint, in bounds: CGRect) -> CGPoint? {
        guard bounds.contains(point) else { return nil }
        for offset in [CGPoint(x: 2, y: 0), CGPoint(x: -2, y: 0),
                       CGPoint(x: 0, y: 2), CGPoint(x: 0, y: -2)] {
            let candidate = CGPoint(x: point.x + offset.x, y: point.y + offset.y)
            if bounds.contains(candidate) { return candidate }
        }
        return nil
    }
}
